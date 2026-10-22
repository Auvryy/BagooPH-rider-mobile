// Isolated native verification with a real paid source; never targets Azure.
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
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_PREPAID_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_PREPAID_FIXTURE_TOKEN');
  testWidgets(
    'native prepaid handoff/replay uses original proof and records the retained-proof backend gap',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated prepaid runner.');
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
          expect(response.statusCode, 200);
          return jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      final prepared = await control('prepare_prepaid'),
          parcel = prepared['parcel'] as Map;
      final taskId = 'final_mile-${parcel['id']}';
      final dio = Dio();
      var next = DateTime.now();
      var loseDelivery = true;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final wait = next.difference(DateTime.now());
            if (wait > Duration.zero) await Future<void>.delayed(wait);
            next = DateTime.now().add(const Duration(milliseconds: 2300));
            handler.next(request);
          },
          onResponse: (response, handler) {
            if (loseDelivery &&
                response.requestOptions.method == 'POST' &&
                response.requestOptions.path.endsWith('/deliver')) {
              loseDelivery = false;
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
      const storage = FlutterSecureStorage();
      final root = await Directory.systemTemp.createTemp('rider-prepaid-');
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
          prepaidDeliveryWritesVerified: true,
          isCurrent: () => true,
        );
        var repo = repository();
        await repo.parcel(
          ParcelAction.depart,
          await repo.detail(taskId),
          barcode: parcel['barcode'] as String,
        );
        final task = await repo.detail(taskId);
        expect(task.deliveryPaymentKind, DeliveryPaymentKind.paidWallet);
        expect(task.codDueCents, isNull);
        final proof = ParcelProof(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
          ),
          'png',
        );
        await expectLater(
          repo.parcel(
            ParcelAction.deliver,
            task,
            barcode: parcel['barcode'] as String,
            fields: const {
              'recipient_name': 'Software Test Prepaid Recipient',
              'recipient_relationship': 'buyer',
            },
            proof: proof,
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final original = (await journal.read())!;
        expect(original.deliveryPaymentMethod, 'wallet');
        expect(
          original.body.keys.any(
            (k) => k.startsWith('cash') || k == 'change_given',
          ),
          isFalse,
        );
        expect((await proofStore().read(original.proof!)).digest, proof.digest);
        repo = repository();
        expect((await repo.reconcile())!['operational_stage'], 'delivered');
        expect(await journal.read(), isNull);
        final replay = await auth.authenticatedRequest(
          original.path,
          method: 'POST',
          headers: {'Idempotency-Key': original.key},
          data: FormData.fromMap({
            ...original.body,
            'proof_image_file': MultipartFile.fromBytes(
              proof.bytes,
              filename: proof.filename,
              contentType: DioMediaType.parse(proof.mime),
            ),
          }),
        );
        expect(replay['data']['replayed'], isTrue);
        final saved = await control('prepaid_snapshot');
        expect(saved['wallet_receipts'], 1);
        expect(saved['cod_accounts'], 0);
        expect(saved['delivered'], 1);
        expect(saved['commands'], 1);
        expect(saved['recipient'], 'Software Test Prepaid Recipient');
        expect(saved['proof_hash'], proof.digest);
        expect(saved['order_status'], 'delivered');
        expect(saved['payment_status'], 'paid');
        final trip = (await repo.tripPage(
          filters: TripFilters(payment: 'prepaid'),
        )).items.singleWhere((t) => t.taskId == taskId);
        expect(trip.paymentMethod, 'wallet');
        expect(trip.collectedCents, isNull);
        final history = await repo.tripDetail(trip.id);
        final checkpoint = history.checkpoints.singleWhere(
          (c) => c.kind == 'delivered',
        );
        expect(checkpoint.proofPath, isNotNull);
        // This is an observed external gate, not accepted proof functionality.
        // Require the owner to fix this before prepaid live activation; do not
        // fabricate a cash account or borrow another assignment's proof.
        await expectLater(
          repo.tripProof(history.id, checkpoint.proofPath!),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.status,
              'current backend retained wallet proof gap',
              404,
            ),
          ),
        );
        expect(history.recipient, isNull);
        final out = File('build/prepaid-verification/native-result.json');
        await out.parent.create(recursive: true);
        await out.writeAsString(
          jsonEncode({
            'native_paid_handoff': true,
            'original_replay': true,
            'wallet_receipts': 1,
            'cod_accounts': 0,
            'buyer_completed': false,
            'retained_proof_status': 404,
            'retained_recipient_returned': false,
            'prepaid_live_accepted': false,
          }),
        );
        debugPrint(
          'Native paid-wallet handoff and original replay passed; retained wallet proof returned 404 and original recipient was absent. Live activation remains unavailable.',
        );
      } finally {
        if (journal != null) {
          await journal.clear();
        }
        if (scope != null) {
          await storage.delete(key: 'bagoo_rider_parcel_proof_key_$scope');
        }
        dio.close(force: true);
        await root.delete(recursive: true);
      }
    },
    skip: base.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
