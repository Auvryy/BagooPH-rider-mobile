import 'dart:async';

import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'support/parcel_support.dart';
import 'support/photo_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final version = 'a' * 64;
  late ParcelTestProofStore proofs;
  late TestParcelPhotoPicker picker;
  var current = true;
  ParcelPhotoService service({
    String account = '5',
    String origin = 'https://example.test/api/v1',
    DateTime Function()? now,
  }) => ParcelPhotoService(
    origin: Uri.parse(origin),
    accountId: account,
    proofs: proofs,
    picker: picker,
    isCurrent: () => current,
    now: now ?? () => DateTime.utc(2026, 10, 18, 2),
  );
  Future<ParcelProof?> choose(ParcelPhotoService photos) => photos.choose(
    taskId: 'final_mile-1',
    version: version,
    action: ParcelAction.deliver,
    camera: false,
  );
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    proofs = ParcelTestProofStore();
    picker = TestParcelPhotoPicker();
    current = true;
  });

  test('original photo draft survives restart only for the exact account API task version and action', () async {
    final first = service();
    final original = await choose(first);
    expect(original!.bytes, parcelTestPng());
    first.dispose();
    final restored = service();
    await restored.restore();
    expect(
      restored.forTask('final_mile-1', version, ParcelAction.deliver)!.digest,
      original.digest,
    );
    expect(
      restored.forTask('final_mile-2', version, ParcelAction.deliver),
      isNull,
    );
    expect(
      restored.forTask('final_mile-1', 'b' * 64, ParcelAction.deliver),
      isNull,
    );
    expect(
      restored.forTask('final_mile-1', version, ParcelAction.fail),
      isNull,
    );
    final other = service(account: '6'),
        otherApi = service(origin: 'https://other.test/api/v1');
    await other.restore();
    await otherApi.restore();
    expect(other.recovered, isNull);
    expect(otherApi.recovered, isNull);
    expect(proofs.files, hasLength(1));
    restored.dispose();
    other.dispose();
    otherApi.dispose();
  });

  test('Android lost-file recovery uses the pending capture context and does not submit anything', () async {
    picker = TestParcelPhotoPicker(
      supportsCamera: true,
      recoversLostData: true,
    );
    final started = Completer<void>(), returned = Completer<XFile?>();
    picker.select = () {
      started.complete();
      return returned.future;
    };
    final first = service();
    final pending = choose(first);
    await started.future;
    first.dispose();
    picker.lost = [XFile.fromData(parcelTestPng(), path: 'original.png')];
    final restarted = service();
    await restarted.restore();
    expect(
      restarted.forTask('final_mile-1', version, ParcelAction.deliver)!.bytes,
      parcelTestPng(),
    );
    expect(restarted.recovered!.context.taskId, 'final_mile-1');
    expect(picker.recoverCalls, 1);
    await restarted.restore();
    expect(picker.recoverCalls, 1);
    returned.complete(null);
    await expectLater(pending, throwsA(isA<AccountFailure>()));
    expect(proofs.files, hasLength(1));
    restarted.dispose();
  });

  test(
    'another account cannot attach a lost Android file to its own parcel',
    () async {
      picker = TestParcelPhotoPicker(
        supportsCamera: true,
        recoversLostData: true,
      );
      final started = Completer<void>(), returned = Completer<XFile?>();
      picker.select = () {
        started.complete();
        return returned.future;
      };
      final first = service();
      final pending = choose(first);
      await started.future;
      first.dispose();
      picker.lost = [
        XFile.fromData(parcelTestPng(), path: 'previous-account.png'),
      ];
      final other = service(account: '6');
      await other.restore();
      expect(other.recovered, isNull);
      expect(proofs.files, isEmpty);
      returned.complete(null);
      await expectLater(pending, throwsA(isA<AccountFailure>()));
      other.dispose();
    },
  );

  test(
    'startup checks Android lost data even when there is no draft marker',
    () async {
      picker = TestParcelPhotoPicker(
        supportsCamera: true,
        recoversLostData: true,
      );
      picker.lost = [XFile.fromData(parcelTestPng(), path: 'unowned.png')];
      final photos = service();
      await photos.restore();
      expect(picker.recoverCalls, 1);
      expect(photos.recovered, isNull);
      expect(proofs.files, isEmpty);
      photos.dispose();
    },
  );

  test(
    'expired draft cleanup never removes an unresolved command original',
    () async {
      final unrelated = await proofs.save(
        commandUuid(),
        ParcelProof(parcelTestPng(), 'png'),
      );
      final first = service();
      await choose(first);
      first.dispose();
      expect(proofs.files, hasLength(2));
      final restored = service(now: () => DateTime.utc(2026, 10, 19, 2, 1));
      await restored.restore();
      expect(restored.recovered, isNull);
      expect(proofs.files.keys, [unrelated.key]);
      restored.dispose();
    },
  );

  test(
    'cancel and invalid replacement retain the previous safe original',
    () async {
      final photos = service();
      final original = await choose(photos);
      picker.select = () async => null;
      expect(await choose(photos), isNull);
      expect(photos.recovered!.proof.digest, original!.digest);
      picker.select = () async =>
          XFile.fromData(parcelTestPng(), path: 'wrong.pdf');
      await expectLater(choose(photos), throwsA(isA<AccountFailure>()));
      expect(photos.recovered!.proof.digest, original.digest);
      expect(photos.busy, isFalse);
      expect(proofs.files, hasLength(1));
      photos.dispose();
    },
  );

  test(
    'session change during photo selection cannot expose the returned bytes',
    () async {
      final started = Completer<void>(), returned = Completer<XFile?>();
      picker.select = () {
        started.complete();
        return returned.future;
      };
      final photos = service();
      final pending = choose(photos);
      await started.future;
      current = false;
      returned.complete(XFile.fromData(parcelTestPng(), path: 'proof.png'));
      await expectLater(pending, throwsA(isA<AccountFailure>()));
      expect(photos.recovered, isNull);
      expect(proofs.files, isEmpty);
      photos.dispose();
    },
  );
}
