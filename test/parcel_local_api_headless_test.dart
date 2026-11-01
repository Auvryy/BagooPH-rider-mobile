// Windowless client-to-kernel check for failed final-mile delivery and return.
// Run through tool/parcel_local_api/run.mjs; all accounts and proof are synthetic.
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/commands/protected_proof_store.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_PARCEL_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_PARCEL_FIXTURE_TOKEN');

  test(
    'failed final-mile attempt returns to destination hub and retains private Trips proof',
    () async {
      final originalOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = originalOverrides);
      FlutterSecureStorage.setMockInitialValues({});

      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated parcel-headless runner.');
      }

      Future<Map<String, dynamic>> control(String operation) async {
        final client = HttpClient();
        try {
          final request = await client.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', fixtureToken);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({'operation': operation}));
          final response = await request.close().timeout(
            const Duration(seconds: 50),
          );
          if (response.statusCode != 200) {
            throw StateError('Local parcel fixture operation failed.');
          }
          return jsonDecode(
            await response
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 50)),
          ) as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      var nextRequest = DateTime.now();
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = nextRequest.difference(DateTime.now());
            if (delay > Duration.zero) await Future<void>.delayed(delay);
            nextRequest = DateTime.now().add(
              const Duration(milliseconds: 2300),
            );
            handler.next(request);
          },
        ),
      );

      final config = AppConfig('$base/api/v1', localAuth: true);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      const storage = FlutterSecureStorage();
      final root = await Directory.systemTemp.createTemp(
        'bagoo-headless-parcel-',
      );
      SecureCommandJournal? journal;
      String? scope;
      try {
        final account = await auth.login(
          info['email'] as String,
          info['password'] as String,
        );
        expect(account.operationsApiVersion, 1);
        journal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
          storage: storage,
        );
        scope = sha256
            .convert(utf8.encode('${config.origin}/${account.id}'))
            .toString();
        final proofStore = ProtectedParcelProofStore(
          origin: config.origin,
          accountId: account.id,
          storage: storage,
          directory: () async => root,
        );
        OperationsRepository repository() => OperationsRepository(
          auth,
          accountId: account.id,
          journal: journal!,
          proofStore: proofStore,
          writesVerified: true,
          parcelWritesVerified: true,
          isCurrent: () => true,
        );

        var repo = repository();
        final home = await repo.home();
        expect(home.capabilities['parcel_actions'], isTrue);
        expect(home.capabilities['trips'], isTrue);
        await repo.duty(true);

        final prepared = await control('prepare_failure');
        final parcel = prepared['parcel'] as Map<String, dynamic>;
        final deliveryId = parcel['id'] as String;
        var task = await repo.detail('final_mile-$deliveryId');
        expect(task.stop.kind, 'destination_hub');
        await repo.parcel(ParcelAction.depart, task, barcode: task.tracking);
        task = await repo.detail(task.id);
        expect(task.stop.kind, 'buyer');

        final original = ParcelProof(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
          ),
          'png',
        );
        await repo.parcel(
          ParcelAction.fail,
          task,
          barcode: task.tracking,
          proof: original,
          fields: {
            'reason': task.failurePolicy!.reasons.keys.first,
            'notes': 'Isolated software test recipient unavailable at the saved stop.',
            'location_name': 'Isolated software test buyer stop',
          },
        );

        final returnTask = await repo.detail(task.id);
        expect(returnTask.stop.kind, 'destination_hub');
        expect(returnTask.failurePolicy!.recordedAttempts, 1);
        final beforeReceipt = await control('counts');
        expect(beforeReceipt['parcels']['failure']['attempts'], 1);
        expect(
          beforeReceipt['parcels']['failure']['custody']['kind'],
          'courier',
        );

        await control('receive_failure');
        final afterReceipt = await control('counts');
        expect(afterReceipt['parcels']['failure']['custody']['kind'], 'hub');
        expect((await repo.taskPage(TaskQueue.delivery)).items, isEmpty);

        final trips = await repo.tripPage();
        final failedTrip = trips.items.singleWhere(
          (trip) => trip.deliveryId == deliveryId && trip.phase == 'final_mile',
        );
        expect(failedTrip.outcome, 'delivery_failed');
        final retainedAttempt = failedTrip.attempts.single;
        expect(retainedAttempt.proofPath, isNotNull);
        expect(
          (await repo.tripProof(
            failedTrip.id,
            retainedAttempt.proofPath!,
          )).bytes,
          original.bytes,
        );

        expect(afterReceipt['parcels']['failure']['stage'], 'delivery_failed');
        expect(afterReceipt['cash'], isEmpty);
        expect(afterReceipt['public_proofs'], isEmpty);

        await control('reassign_retry');
        final retained = await repo.tripDetail(failedTrip.id);
        expect(retained.outcome, 'delivery_failed');
        expect(retained.currentStage, 'assigned_to_rider');
        expect(retained.attempts.single.id, retainedAttempt.id);
        expect(
          (await repo.tripProof(
            failedTrip.id,
            retainedAttempt.proofPath!,
          )).bytes,
          original.bytes,
        );

        final other = ApiAuthRepository(config, MemoryTokenStore());
        try {
          await other.login(
            info['other_email'] as String,
            info['other_password'] as String,
          );
          await expectLater(
            other.authenticatedRequest('rider/trips/${failedTrip.id}'),
            throwsA(
              isA<AccountFailure>().having(
                (failure) => failure.status,
                'denied original assignment',
                404,
              ),
            ),
          );
          await expectLater(
            other.authenticatedEvidence(retainedAttempt.proofPath!),
            throwsA(
              isA<AccountFailure>().having(
                (failure) => failure.status,
                'denied original attempt proof',
                404,
              ),
            ),
          );
        } finally {
          await other.discardSession();
        }
      } finally {
        await journal?.clear();
        if (scope != null) {
          await storage.delete(key: 'bagoo_rider_parcel_proof_key_$scope');
        }
        await auth.discardSession();
        dio.close(force: true);
        await root.delete(recursive: true);
      }
    },
    skip: base.isEmpty || fixtureToken.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
