// Isolated native cash verification. All accounts and money are synthetic.
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_CASH_API_BASE');
  const fixtureToken = String.fromEnvironment('LOCAL_CASH_FIXTURE_TOKEN');
  testWidgets(
    'native cash offers recover once and balances change only on owning hub receipts',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          fixtureToken.isEmpty) {
        throw StateError('Use the isolated cash runner.');
      }
      Future<Map<String, dynamic>> control(
        String operation, [
        Map<String, Object> fields = const {},
      ]) async {
        final client = HttpClient();
        try {
          final request = await client.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', fixtureToken);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({'operation': operation, ...fields}));
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
      final prepared = await control('cash_prepare');
      final rows = prepared['accounts'] as List;
      final first = rows[0] as Map, second = rows[1] as Map;
      final firstId = first['id'] as String, secondId = second['id'] as String;
      final firstDue = BigInt.parse(first['due_cents'] as String);
      final secondDue = BigInt.parse(second['due_cents'] as String);
      final dio = Dio();
      var next = DateTime.now(), loseBefore = true, loseAfter = false;
      final attempts = <Map<String, Object?>>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = next.difference(DateTime.now());
            if (delay > Duration.zero) {
              await Future<void>.delayed(delay);
            }
            next = DateTime.now().add(const Duration(milliseconds: 2300));
            if (request.path.endsWith('/offer')) {
              attempts.add({
                'key': request.headers['Idempotency-Key'],
                'body': jsonEncode(request.data),
              });
              if (loseBefore) {
                loseBefore = false;
                handler.reject(
                  DioException(
                    requestOptions: request,
                    type: DioExceptionType.connectionError,
                    error: 'Software test interruption before dispatch.',
                  ),
                );
                return;
              }
            }
            handler.next(request);
          },
          onResponse: (response, handler) {
            if (loseAfter &&
                response.requestOptions.path.endsWith('/offer') &&
                response.statusCode == 200) {
              loseAfter = false;
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  type: DioExceptionType.receiveTimeout,
                  error: 'Software test interruption after commit.',
                ),
              );
              return;
            }
            handler.next(response);
          },
        ),
      );
      final config = AppConfig('$base/api/v1', localAuth: true);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      SecureCommandJournal? journal;
      try {
        final account = await auth.login(
          info['email'] as String,
          info['password'] as String,
        );
        expect(account.operationsApiVersion, 1);
        journal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
          storage: const FlutterSecureStorage(),
        );
        OperationsRepository repository({bool writes = true}) =>
            OperationsRepository(
              auth,
              accountId: account.id,
              journal: journal!,
              writesVerified: false,
              cashWritesVerified: writes,
              isCurrent: () => true,
            );
        var repo = repository();
        expect(await repo.cashAvailable(), isTrue);
        final filtered = await repo.cashPage(
          query: first['tracking'] as String,
        );
        expect(filtered.items.single.id, firstId);
        expect(filtered.held, firstDue + secondDue);
        expect(filtered.total, 1);
        final reviewedFirst = await repo.cashDetail(firstId);
        expect(reviewedFirst.held, firstDue);
        expect(reviewedFirst.remitted, BigInt.zero);
        expect(
          reviewedFirst.recipients.any((r) => r.id == first['handler_id']),
          isTrue,
        );
        await expectLater(
          repo.offerCash(
            reviewedFirst,
            recipientId: first['handler_id'] as String,
            amount: first['amount'] as String,
            evidenceReference: 'SOFTWARE-TEST-CASH-ONE',
            mayDispatch: () => true,
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final originalFirst = (await journal.read())!;
        expect(originalFirst.action, 'cash.offer');
        expect(originalFirst.resource, 'cash-$firstId');
        expect(originalFirst.body['expected_version'], reviewedFirst.version);
        expect((await repo.cashDetail(firstId)).pending, isNull);
        repo = repository();
        expect(await repo.reconcile(), isNull);
        await expectLater(
          repository(writes: false)
              .reconcile(retryUnknown: true, mayDispatch: () => true),
          throwsA(isA<AccountFailure>()),
        );
        expect((await journal.read())!.key, originalFirst.key);
        final recordedFirst = (await repo.reconcile(
          retryUnknown: true,
          mayDispatch: () => true,
        ))!;
        expect(recordedFirst['handover_state'], 'awaiting_recipient_receipt');
        expect(await journal.read(), isNull);
        expect(attempts.take(2).map((a) => a['key']), [
          originalFirst.key,
          originalFirst.key,
        ]);
        expect(attempts[0]['body'], attempts[1]['body']);
        final offeredFirst = await repo.cashDetail(firstId);
        expect(offeredFirst.held, firstDue);
        expect(offeredFirst.remitted, BigInt.zero);
        expect(
          offeredFirst.pending!.reference,
          recordedFirst['event_reference'],
        );

        final reviewedSecond = await repo.cashDetail(secondId);
        loseAfter = true;
        await expectLater(
          repo.offerCash(
            reviewedSecond,
            recipientId: second['handler_id'] as String,
            amount: second['amount'] as String,
            evidenceReference: 'SOFTWARE-TEST-CASH-TWO',
            mayDispatch: () => true,
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final originalSecond = (await journal.read())!;
        final recordedSecond = (await repository(writes: false).reconcile())!;
        expect(await journal.read(), isNull);
        expect((await repo.cashDetail(secondId)).held, secondDue);
        final beforeReceipts = await control('cash_snapshot');
        expect(beforeReceipts['commands'], 2);
        for (final row in beforeReceipts['accounts'] as List) {
          expect(row['offers'], 1);
          expect(row['receipts'], 0);
          expect(row['remitted_cents'], '0');
          expect(row['web_parity'], isTrue);
        }
        await control('cash_receive', {'which': 'cash_one'});
        await control('cash_receive', {'which': 'cash_two', 'shortage': true});
        final receivedFirst = await repo.cashDetail(firstId);
        expect(receivedFirst.held, BigInt.zero);
        expect(receivedFirst.remitted, firstDue);
        expect(receivedFirst.reconciled, BigInt.zero);
        expect(receivedFirst.pending, isNull);
        final receivedSecond = await repo.cashDetail(secondId);
        expect(receivedSecond.held, BigInt.from(100));
        expect(receivedSecond.remitted, secondDue - BigInt.from(100));
        expect(receivedSecond.status, 'difference');
        expect(receivedSecond.discrepancies.single.cents, BigInt.from(-100));
        expect(receivedSecond.history.last.discrepancy, BigInt.from(-100));
        final summary = await repo.cashPage(query: first['tracking'] as String);
        expect(summary.items.single.id, firstId);
        expect(summary.held, BigInt.from(100));
        expect(summary.unresolved, 1);

        for (final original in [originalFirst, originalSecond]) {
          final replay = await auth.authenticatedRequest(
            original.path,
            method: 'POST',
            headers: {'Idempotency-Key': original.key},
            data: original.body,
          );
          expect(replay['data']['replayed'], isTrue);
          expect(
            replay['data']['result']['event_reference'],
            original == originalFirst
                ? recordedFirst['event_reference']
                : recordedSecond['event_reference'],
          );
        }
        await expectLater(
          auth.authenticatedRequest(
            originalFirst.path,
            method: 'POST',
            headers: {'Idempotency-Key': commandUuid()},
            data: originalFirst.body,
          ),
          throwsA(
            isA<AccountFailure>().having((e) => e.status, 'stale version', 409),
          ),
        );
        await expectLater(
          auth.authenticatedRequest(
            originalSecond.path,
            method: 'POST',
            headers: {'Idempotency-Key': commandUuid()},
            data: {
              'expected_version': receivedSecond.version,
              'recipient_id': prepared['other_id'],
              'amount': '1.00',
              'evidence_reference': 'SOFTWARE-TEST-WRONG-RECIPIENT',
            },
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.status,
              'wrong recipient',
              409,
            ),
          ),
        );
        await expectLater(
          auth.authenticatedRequest(
            'rider/cash/$firstId/receive',
            method: 'POST',
            data: {},
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.status,
              'no rider receipt',
              404,
            ),
          ),
        );
        final saved = await control('cash_snapshot');
        expect(saved['commands'], 2);
        for (final row in saved['accounts'] as List) {
          expect(row['offers'], 1);
          expect(row['receipts'], 1);
          expect(row['reconciled_cents'], '0');
          expect(row['order_status'], 'delivered');
          expect(row['payment_status'], 'pending');
          expect(row['delivered'], 1);
          expect(row['web_parity'], isTrue);
        }
        await auth.login(
          info['other_email'] as String,
          info['other_password'] as String,
        );
        await expectLater(
          auth.authenticatedRequest('rider/cash/$firstId'),
          throwsA(
            isA<AccountFailure>().having((e) => e.status, 'foreign cash', 404),
          ),
        );
        await expectLater(
          auth.authenticatedRequest(
            originalFirst.path,
            method: 'POST',
            headers: {'Idempotency-Key': commandUuid()},
            data: originalFirst.body,
          ),
          throwsA(
            isA<AccountFailure>().having((e) => e.status, 'foreign offer', 404),
          ),
        );
        final other = await auth.authenticatedRequest('rider/cash');
        expect(other['data']['items'], isEmpty);
        expect(other['data']['summary']['own_held_cents'], '0');
        expect(other['data']['earnings'], {
          'available': false,
          'confirmed_cents': null,
        });
        expect((await control('cash_snapshot'))['commands'], 2);
        final out = File('build/cash-verification/native-result.json');
        await out.parent.create(recursive: true);
        await out.writeAsString(
          jsonEncode({
            'native_cash_compatibility': true,
            'cash_offer_commands': 2,
            'original_unknown_retry': true,
            'original_committed_recovery': true,
            'original_replay_after_receipt': true,
            'offers_moved_cash': false,
            'hub_receipts': 2,
            'signed_shortage_cents': '-100',
            'filtered_all_owned_summary': true,
            'foreign_denied': true,
            'web_parity': true,
            'buyer_completed': false,
            'cash_reconciled': false,
            'azure_accepted': false,
            'physical_android_accepted': false,
          }),
        );
        debugPrint(
          'Native cash recovery, original replay, independent hub receipts, signed shortage and web journal parity passed. No live activation.',
        );
      } finally {
        if (journal != null) {
          await journal.clear();
        }
        dio.close(force: true);
      }
    },
    skip: base.isEmpty,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
