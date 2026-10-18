// Explicit synthetic native-to-kernel verification. Never targets Azure.
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
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/trips/data/trip_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_PARCEL_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_PARCEL_FIXTURE_TOKEN');
  testWidgets(
    'native parcel commands Trips and private proof match the isolated Laravel kernel and owning roles',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated local parcel runner.');
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
      final parcels = info['parcels'] as Map<String, dynamic>;
      String id(String kind) => parcels[kind]['id'] as String;
      final dio = Dio();
      // Honour the normal native/server budget throughout the integration test.
      // No limiter is disabled and no production clock or data is changed.
      var nextRequest = DateTime.now();
      String? loseBefore, loseAfter;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = nextRequest.difference(DateTime.now());
            if (!delay.isNegative) await Future<void>.delayed(delay);
            nextRequest = DateTime.now().add(
              const Duration(milliseconds: 2300),
            );
            if (loseBefore != null && request.uri.path.endsWith(loseBefore!)) {
              loseBefore = null;
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionTimeout,
                ),
              );
            } else {
              handler.next(request);
            }
          },
          onResponse: (response, handler) {
            if (loseAfter != null &&
                response.requestOptions.uri.path.endsWith(loseAfter!) &&
                response.requestOptions.method == 'POST') {
              loseAfter = null;
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  type: DioExceptionType.receiveTimeout,
                ),
              );
            } else {
              handler.next(response);
            }
          },
        ),
      );
      final config = AppConfig('$base/api/v1', localAuth: true);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      final storage = const FlutterSecureStorage();
      final root = await Directory.systemTemp.createTemp(
        'bagoo-native-parcel-',
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
        ProtectedParcelProofStore proofStore() => ProtectedParcelProofStore(
          origin: config.origin,
          accountId: account.id,
          storage: storage,
          directory: () async => root,
        );
        OperationsRepository repository() => OperationsRepository(
          auth,
          accountId: account.id,
          journal: journal!,
          proofStore: proofStore(),
          writesVerified: true,
          parcelWritesVerified: true,
          isCurrent: () => true,
        );
        var repo = repository();
        final home = await repo.home();
        expect(home.capabilities['parcel_actions'], isTrue);
        expect(home.capabilities['trips'], isTrue);
        debugPrint(
          'Local parcel check: fresh native account and capabilities verified.',
        );
        await repo.duty(false);
        expect((await repo.home()).claimDenial, 'OFF_DUTY');
        await repo.duty(true);
        final preview = (await repo.taskPage(TaskQueue.available)).items
            .singleWhere((p) => p.deliveryId == id('pickup'));
        expect(preview.preview, isTrue);
        expect(preview.stop.latitude, isNull);
        loseAfter = '/claim';
        await expectLater(
          repo.claim(preview),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final claim = (await journal.read())!;
        repo = repository();
        expect((await repo.reconcile())!['task_id'], 'pickup-${id('pickup')}');
        final replayClaim = await auth.authenticatedRequest(
          'rider/pickup-jobs/${id('pickup')}/claim',
          method: 'POST',
          data: claim.body,
          headers: {'Idempotency-Key': claim.key},
        );
        expect(replayClaim['data']['replayed'], isTrue);

        // A failure before dispatch remains unknown and retries the original key.
        final pickup = await repo.detail('pickup-${id('pickup')}');
        await repo.duty(false);
        loseBefore = '/pickup';
        await expectLater(
          repo.parcel(ParcelAction.pickup, pickup, barcode: pickup.tracking),
          throwsA(isA<AccountFailure>()),
        );
        final pickupIntent = (await journal.read())!;
        repo = repository();
        expect(await repo.reconcile(), isNull);
        expect(
          (await repo.reconcile(retryUnknown: true))!['operational_stage'],
          'picked_up',
        );
        expect(pickupIntent.key, isNotEmpty);
        expect(await journal.read(), isNull);
        expect((await repo.detail(pickup.id)).stop.kind, 'origin_hub');
        expect((await control('counts'))['parcels']['pickup']['picked_up'], 1);
        expect(
          (await control('receive_pickup'))['stage'],
          'arrived_at_origin_hub',
        );
        expect((await repo.taskPage(TaskQueue.pickups)).items, isEmpty);
        await repo.duty(true);
        debugPrint(
          'Local parcel check: claim replay, off-duty collection and owning hub receipt verified.',
        );

        Future<OperationTask> depart(String kind) async {
          final assigned = await repo.detail('final_mile-${id(kind)}');
          expect(assigned.stop.kind, 'destination_hub');
          await repo.parcel(
            ParcelAction.depart,
            assigned,
            barcode: assigned.tracking,
          );
          final fresh = await repo.detail(assigned.id);
          expect(fresh.stop.kind, 'buyer');
          return fresh;
        }

        parcels['delivery'] = (await control('prepare_delivery'))['parcel'];
        final delivery = await depart('delivery');
        final original = ParcelProof(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
          ),
          'png',
        );
        final due = delivery.codDueCents!;
        final whole = due ~/ BigInt.from(100),
            fraction = (due % BigInt.from(100)).toString().padLeft(2, '0');
        final fields = <String, dynamic>{
          'recipient_name': 'Isolated Software Test Recipient',
          'recipient_relationship': 'buyer',
          'cash_received': '$whole.$fraction',
          'change_given': '0.00',
          'cash_confirmed': true,
        };
        loseAfter = '/deliver';
        await expectLater(
          repo.parcel(
            ParcelAction.deliver,
            delivery,
            barcode: delivery.tracking,
            fields: fields,
            proof: original,
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final deliveredIntent = (await journal.read())!;
        expect(
          (await proofStore().read(deliveredIntent.proof!)).bytes,
          original.bytes,
        );
        repo = repository();
        expect((await repo.reconcile())!['operational_stage'], 'delivered');
        expect(await journal.read(), isNull);
        final replay = await auth.authenticatedRequest(
          'rider/tasks/${delivery.id}/deliver',
          method: 'POST',
          headers: {'Idempotency-Key': deliveredIntent.key},
          data: FormData.fromMap({
            ...deliveredIntent.body,
            'cash_confirmed': '1',
            'proof_image_file': MultipartFile.fromBytes(
              original.bytes,
              filename: 'proof.png',
              contentType: DioMediaType.parse(original.mime),
            ),
          }),
        );
        expect(replay['data']['replayed'], isTrue);
        final deliveredState = await control('counts');
        expect(deliveredState['parcels']['delivery']['delivered'], 1);
        expect(deliveredState['parcels']['delivery']['order'], 'delivered');
        expect(deliveredState['parcels']['delivery']['payment'], 'pending');
        expect(deliveredState['cash'], hasLength(1));
        expect(deliveredState['cash'][0]['expected_cents'], due.toString());
        expect(deliveredState['cash'][0]['balance_cents'], due.toString());
        expect(deliveredState['cash'][0]['events'], 1);
        expect(deliveredState['cash'][0]['reconciled'], isFalse);
        expect(deliveredState['public_proofs'], isEmpty);
        expect((await control('buyer_receive'))['order'], 'completed');
        debugPrint(
          'Local parcel check: one COD delivery, original proof recovery and separate buyer receipt verified.',
        );

        parcels['failure'] = (await control('prepare_failure'))['parcel'];
        final failure = await depart('failure');
        await repo.parcel(
          ParcelAction.fail,
          failure,
          barcode: failure.tracking,
          proof: original,
          fields: {
            'reason': failure.failurePolicy!.reasons.keys.first,
            'notes': 'Isolated software test recipient unavailable at the saved stop.',
            'location_name': 'Isolated software test buyer stop',
          },
        );
        final returnTask = await repo.detail(failure.id);
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
        debugPrint(
          'Local parcel check: failed attempt and owning destination-hub return verified.',
        );

        final trips = await repo.tripPage();
        expect(trips.items.map((t) => t.phase).toSet(), {
          'pickup',
          'final_mile',
        });
        final deliveredTrip = trips.items.singleWhere(
          (t) => t.deliveryId == id('delivery') && t.phase == 'final_mile',
        );
        final failedTrip = trips.items.singleWhere(
          (t) => t.deliveryId == id('failure') && t.phase == 'final_mile',
        );
        expect(deliveredTrip.recipient, fields['recipient_name']);
        expect(deliveredTrip.collectedCents, due);
        final privatePath = deliveredTrip.proofPaths.single;
        debugPrint('Local parcel check: reading retained assignment images.');
        expect(
          (await repo.tripProof(deliveredTrip.id, privatePath)).bytes,
          original.bytes,
        );
        final retainedAttempt = failedTrip.attempts.single;
        expect(
          (await repo.tripProof(
            failedTrip.id,
            retainedAttempt.proofPath!,
          )).bytes,
          original.bytes,
        );
        final filtered = await repo.tripPage(
          filters: TripFilters(
            search: delivery.tracking,
            phase: 'final_mile',
            payment: 'cod',
          ),
        );
        expect(filtered.items.single.id, deliveredTrip.id);
        final manila = manilaTime(deliveredTrip.assignedAt);
        final day = DateTime(manila.year, manila.month, manila.day);
        final sameDay = await repo.tripPage(
          filters: TripFilters(search: delivery.tracking, from: day, to: day),
        );
        expect(sameDay.items.single.id, deliveredTrip.id);
        final paginated = RetainedTripPage.fromJson(
          Wire.object(
            (await auth.authenticatedRequest(
              'rider/trips?per_page=1&page=2',
            ))['data'],
          ),
        );
        expect(paginated.items.single.id, trips.items[1].id);
        debugPrint(
          'Local parcel check: retained filters, assignment dates and pagination verified.',
        );
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
                (e) => e.status,
                'denied original assignment',
                404,
              ),
            ),
          );
          await expectLater(
            other.authenticatedEvidence(retainedAttempt.proofPath!),
            throwsA(
              isA<AccountFailure>().having(
                (e) => e.status,
                'denied original proof',
                404,
              ),
            ),
          );
        } finally {
          await other.discardSession();
        }
        await control('change_proof');
        await expectLater(
          repo.tripProof(deliveredTrip.id, privatePath),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.code,
              'changed image',
              'EVIDENCE_CHANGED',
            ),
          ),
        );
        expect((await control('counts'))['cash'][0]['reconciled'], isFalse);
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
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
