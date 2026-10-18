import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/protected_proof_store.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  ProtectedParcelProofStore store({
    String account = '5',
    String host = 'https://example.test/api/v1',
  }) => ProtectedParcelProofStore(
    origin: Uri.parse(host),
    accountId: account,
    directory: () async => directory,
  );
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('rider-proof-test-');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('original proof remains encrypted, hash-bound and recoverable after reconstruction', () async {
    final bytes = parcelTestPng();
    final proof = ParcelProof(bytes, 'png');
    bytes[0] = 0;
    expect(proof.bytes.first, 137);
    final key = commandUuid();
    final ref = await store().save(key, proof);
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
    expect(files, hasLength(1));
    expect(await files.single.readAsBytes(), isNot(proof.bytes));
    expect(files.single.path, isNot(contains('example.test')));
    final original = await store().read(
      ParcelProofReference.fromJson(ref.toJson()),
    );
    expect(original.bytes, proof.bytes);
    expect(original.digest, proof.digest);
    final savedAgain = await store().save(key, proof);
    expect(savedAgain.digest, ref.digest);
    await store().delete(ref);
    expect(directory.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test(
    'another account/API cannot read or remove the retained original',
    () async {
      final ref = await store().save(
        commandUuid(),
        ParcelProof(parcelTestPng(), 'png'),
      );
      await expectLater(
        store(account: '6').read(ref),
        throwsA(isA<AccountFailure>()),
      );
      await expectLater(
        store(host: 'https://other.test/api/v1').read(ref),
        throwsA(isA<AccountFailure>()),
      );
      await store(account: '6').delete(ref);
      expect((await store().read(ref)).digest, ref.digest);
    },
  );

  test(
    'modified ciphertext or a substituted hash cannot become upload evidence',
    () async {
      final ref = await store().save(
        commandUuid(),
        ParcelProof(parcelTestPng(), 'png'),
      );
      await expectLater(
        store().read(
          ParcelProofReference(
            key: ref.key,
            digest: '0' * 64,
            extension: 'png',
          ),
        ),
        throwsA(isA<AccountFailure>()),
      );
      final file = directory.listSync(recursive: true).whereType<File>().single;
      final encrypted = await file.readAsBytes();
      encrypted[encrypted.length - 1] ^= 1;
      await file.writeAsBytes(encrypted);
      await expectLater(store().read(ref), throwsA(isA<AccountFailure>()));
      expect(await file.exists(), isTrue);
    },
  );

  test('unsupported type, empty, changed signature and oversize proof reject locally', () {
    expect(
      () => ParcelProof(parcelTestPng(), 'pdf'),
      throwsA(isA<AccountFailure>()),
    );
    final invalid = parcelTestPng()..[0] = 0;
    expect(() => ParcelProof(invalid, 'png'), throwsA(isA<AccountFailure>()));
    final large = Uint8List(parcelProofLimit + 1)
      ..setRange(0, parcelTestPng().length, parcelTestPng());
    expect(() => ParcelProof(large, 'png'), throwsA(isA<AccountFailure>()));
  });
}
