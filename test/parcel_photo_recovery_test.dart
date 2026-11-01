import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'support/parcel_support.dart';
import 'support/photo_support.dart';

class _DelayedParcelPhotoReadStore extends ParcelTestProofStore {
  final readStarted = Completer<void>();
  final finishRead = Completer<void>();

  @override
  Future<ParcelProof> read(ParcelProofReference reference) async {
    if (!readStarted.isCompleted) readStarted.complete();
    await finishRead.future;
    return super.read(reference);
  }
}

class _DelayedParcelPhotoSaveStore extends ParcelTestProofStore {
  final saveStarted = Completer<void>();
  final finishSave = Completer<void>();

  @override
  Future<ParcelProofReference> save(String key, ParcelProof proof) async {
    if (!saveStarted.isCompleted) saveStarted.complete();
    await finishSave.future;
    return super.save(key, proof);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final version = 'a' * 64;
  late ParcelTestProofStore proofs;
  late TestParcelPhotoPicker picker;
  var current = true;
  var photoNow = DateTime.utc(2026, 10, 18, 2);
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
    now: now ?? () => photoNow,
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
    photoNow = DateTime.utc(2026, 10, 18, 2);
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

  test('background clears photo bytes from memory and resume restores the encrypted draft', () async {
    final photos = service();
    final original = await choose(photos);
    expect(
      photos.forTask('final_mile-1', version, ParcelAction.deliver),
      isNotNull,
    );

    photos.setForeground(false);
    expect(photos.recovered, isNull);
    expect(
      photos.forTask('final_mile-1', version, ParcelAction.deliver),
      isNull,
    );
    expect(proofs.files, hasLength(1));

    final restored = Completer<void>();
    photos.addListener(() {
      if (!photos.busy && photos.recovered != null && !restored.isCompleted) {
        restored.complete();
      }
    });
    photos.setForeground(true);
    await restored.future.timeout(const Duration(seconds: 2));
    expect(
      photos.forTask('final_mile-1', version, ParcelAction.deliver)!.digest,
      original!.digest,
    );
    photos.dispose();
  });

  test(
    'WorkspaceController forwards foreground changes to parcel photo recovery',
    () async {
      final domain = ParcelHarness();
      final photos = service();
      final original = await choose(photos);
      domain.repository = domain.restart(photos: photos);
      final work = WorkspaceController(domain.repository);
      addTearDown(work.dispose);
      addTearDown(photos.dispose);

      work.setForeground(false);
      expect(photos.recovered, isNull);
      final restored = Completer<void>();
      photos.addListener(() {
        if (!photos.busy && photos.recovered != null && !restored.isCompleted) {
          restored.complete();
        }
      });
      work.setForeground(true);
      await restored.future.timeout(const Duration(seconds: 2));
      expect(
        photos.forTask('final_mile-1', version, ParcelAction.deliver)!.digest,
        original!.digest,
      );
      await work.clearUnsubmittedPhotoDraftForSignOut();
      expect(photos.recovered, isNull);
      expect(proofs.files, isEmpty);
    },
  );

  test('a delayed restore cannot put photo bytes back after a background transition', () async {
    final delayedProofs = _DelayedParcelPhotoReadStore();
    proofs = delayedProofs;
    final first = service();
    final original = await choose(first);
    first.dispose();

    final resumed = service();
    final restored = Completer<void>();
    resumed.addListener(() {
      if (!resumed.busy && resumed.recovered != null && !restored.isCompleted) {
        restored.complete();
      }
    });
    final firstRestore = resumed.restore();
    await delayedProofs.readStarted.future;
    resumed.setForeground(false);
    resumed.setForeground(true);
    delayedProofs.finishRead.complete();
    await firstRestore;
    await restored.future.timeout(const Duration(seconds: 2));

    expect(resumed.recovered!.proof.digest, original!.digest);
    resumed.dispose();
  });

  test(
    'a draft expired in background is removed when the workspace resumes',
    () async {
      final photos = service();
      await choose(photos);
      photos.setForeground(false);
      photoNow = photoNow.add(const Duration(hours: 24));
      expect(photos.recovered, isNull);
      expect(proofs.files, hasLength(1));

      final restored = Completer<void>();
      photos.addListener(() {
        if (!photos.busy && !restored.isCompleted) restored.complete();
      });
      photos.setForeground(true);
      await restored.future.timeout(const Duration(seconds: 2));
      expect(photos.recovered, isNull);
      expect(proofs.files, isEmpty);
      photos.dispose();
    },
  );

  test(
    'sign-out cleanup removes only the unsubmitted draft and picker marker',
    () async {
      final photos = service();
      final original = await choose(photos);
      final commandCopy = await proofs.save(commandUuid(), original!);
      final storage = const FlutterSecureStorage();
      await storage.write(
        key: 'bagoo_rider_parcel_active_photo',
        value: jsonEncode(photos.recovered!.context.toJson()),
      );

      await photos.clearForSignOut();
      expect(photos.recovered, isNull);
      expect(
        await storage.read(key: 'bagoo_rider_parcel_active_photo'),
        isNull,
      );
      expect(proofs.files.keys, [commandCopy.key]);

      final nextSession = service();
      await nextSession.restore();
      expect(nextSession.recovered, isNull);
      expect(proofs.files.keys, [commandCopy.key]);
      photos.dispose();
      nextSession.dispose();
    },
  );

  test(
    'sign-out blocks a picker result that returns after draft cleanup',
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
      final photos = service();
      final pending = choose(photos);
      await started.future;

      await photos.clearForSignOut();
      returned.complete(
        XFile.fromData(parcelTestPng(), path: 'late-proof.png'),
      );
      await expectLater(pending, throwsA(isA<AccountFailure>()));
      expect(photos.recovered, isNull);
      expect(proofs.files, isEmpty);
      expect(
        await const FlutterSecureStorage().read(
          key: 'bagoo_rider_parcel_active_photo',
        ),
        isNull,
      );
      photos.dispose();
    },
  );

  test(
    'sign-out removes a proof file saved by an in-flight photo selection',
    () async {
      final delayedProofs = _DelayedParcelPhotoSaveStore();
      proofs = delayedProofs;
      final photos = service();
      final pending = choose(photos);
      await delayedProofs.saveStarted.future;

      await photos.clearForSignOut();
      delayedProofs.finishSave.complete();
      await expectLater(pending, throwsA(isA<AccountFailure>()));
      expect(photos.recovered, isNull);
      expect(delayedProofs.files, isEmpty);
      photos.dispose();
    },
  );

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

  test('active expiry clears the temporary draft but preserves the command proof copy', () async {
    final photos = service();
    final original = await choose(photos);
    final commandCopy = await proofs.save(commandUuid(), original!);
    expect(proofs.files, hasLength(2));

    final cleaned = Completer<void>();
    photos.addListener(() {
      if (!photos.busy && photos.recovered == null && !cleaned.isCompleted) {
        cleaned.complete();
      }
    });
    photoNow = photoNow.add(const Duration(hours: 24));

    expect(
      photos.forTask('final_mile-1', version, ParcelAction.deliver),
      isNull,
    );
    expect(
      photos.isUsableDraft(
        original,
        taskId: 'final_mile-1',
        version: version,
        action: ParcelAction.deliver,
      ),
      isFalse,
    );
    await cleaned.future.timeout(const Duration(seconds: 2));

    expect(photos.recovered, isNull);
    expect(proofs.files.keys, [commandCopy.key]);
    photos.dispose();
  });

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
