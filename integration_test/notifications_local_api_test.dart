// Uses only the disposable loopback kernel. No production account or event.
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notifications_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('LOCAL_NOTIFICATIONS_API_BASE');
  const token = String.fromEnvironment('LOCAL_NOTIFICATIONS_FIXTURE_TOKEN');
  testWidgets(
    'native exact notice reads match durable saved rows and retained commands',
    (tester) async {
      final origin = Uri.parse(base);
      if (origin.scheme != 'http' ||
          origin.host != '127.0.0.1' ||
          origin.path.isNotEmpty ||
          token.isEmpty) {
        throw StateError('Use the isolated notification runner.');
      }
      Future<Map<String, dynamic>> control(
        String operation, [
        Map<String, dynamic> arguments = const {},
      ]) async {
        final http = HttpClient();
        try {
          final request = await http.postUrl(origin.resolve('/fixture'));
          request.headers.set('X-Local-Fixture', token);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({'operation': operation, ...arguments}));
          final response = await request.close().timeout(
            const Duration(seconds: 50),
          );
          if (response.statusCode != 200) {
            throw StateError('Local notification fixture failed.');
          }
          return jsonDecode(
            await response
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 50)),
          ) as Map<String, dynamic>;
        } finally {
          http.close(force: true);
        }
      }

      final info = await control('info');
      expect(info['database'], ':memory:');
      final dio = Dio();
      var next = DateTime.now();
      bool loseAfter = false, loseBefore = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final delay = next.difference(DateTime.now());
            if (!delay.isNegative) await Future<void>.delayed(delay);
            next = DateTime.now().add(const Duration(milliseconds: 2300));
            if (loseBefore &&
                request.method == 'POST' &&
                request.uri.path.contains('/notifications/')) {
              loseBefore = false;
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
            if (loseAfter &&
                response.requestOptions.method == 'POST' &&
                response.requestOptions.uri.path.contains('/notifications/')) {
              loseAfter = false;
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
      final other = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      SecureCommandJournal? workJournal, noticeJournal;
      try {
        final account = await auth.login(
          info['email'] as String,
          info['password'] as String,
        );
        expect(account.operationsApiVersion, 1);
        workJournal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
        );
        noticeJournal = SecureCommandJournal(
          origin: config.origin,
          accountId: account.id,
          scope: 'notifications',
        );
        await workJournal.clear();
        await noticeJournal.clear();
        final work = OperationsRepository(
          auth,
          accountId: account.id,
          journal: workJournal,
          writesVerified: true,
          isCurrent: () => true,
        );
        OperationsNotificationsRepository notifications() =>
            OperationsNotificationsRepository(
              auth,
              accountId: account.id,
              journal: noticeJournal!,
              isCurrent: () => true,
              readHome: work.home,
              writesVerified: true,
            );
        var repo = notifications();
        expect(await repo.available(), isTrue);
        await work.duty(true);
        final pickup = info['parcels']['pickup']['id'] as String;
        final jobs = await work.taskPage(TaskQueue.available);
        await work.claim(jobs.items.singleWhere((t) => t.deliveryId == pickup));
        final custodyBefore = await control('counts');
        final first = await control('notification_seed', {
          'name': 'notice-test-1',
        });
        final duplicate = await control('notification_seed', {
          'name': 'notice-test-1',
        });
        expect(duplicate['id'], first['id']);
        var page = await repo.page();
        expect(page.items.any((n) => n.id == first['id']), isTrue);
        final one = await repo.acknowledge([
          first['id'] as String,
        ], mayDispatch: () => true);
        expect(one.ids, [first['id']]);
        final second = await control('notification_seed', {
          'name': 'notice-test-2',
        });
        await control('notification_seed', {'name': 'notice-test-4'});
        page = await repo.page();
        final displayed = page.items
            .where((n) => n.unread)
            .map((n) => n.id)
            .toList();
        expect(displayed, contains(second['id']));
        final late = await control('notification_seed', {
          'name': 'notice-test-3',
        });
        expect(late['recorded_at'], second['recorded_at']);
        loseAfter = true;
        await expectLater(
          repo.acknowledge(displayed, mayDispatch: () => true),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        final original = (await repo.pending())!;
        repo = notifications();
        final recovered = await repo.reconcile(mayDispatch: () => true);
        expect(recovered!.intent.key, original.key);
        final replay = await auth.authenticatedRequest(
          original.path,
          method: 'POST',
          data: original.body,
          headers: {'Idempotency-Key': original.key},
        );
        expect(replay['data']['replayed'], isTrue);
        await expectLater(
          auth.authenticatedRequest(
            original.path,
            method: 'POST',
            data: {
              'displayed_ids': [late['id']],
            },
            headers: {'Idempotency-Key': original.key},
          ),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.code,
              'conflict',
              'IDEMPOTENCY_CONFLICT',
            ),
          ),
        );
        await control('notification_expire', {'key': original.key});
        final retained = await auth.authenticatedRequest(
          'rider/commands/${original.key}',
        );
        final expired = NotificationReadResult.fromJson(
          retained['data'],
          original,
        );
        expect(expired.retryExpired, isTrue);
        await control('notifications_resume_clock');
        var snapshot = await control('notifications_snapshot');
        expect(snapshot['unread'], 1);
        final otherCount = snapshot['other_count'];
        expect(
          (snapshot['items'] as List).singleWhere(
            (n) => n['id'] == late['id'],
          )['read'],
          isFalse,
        );
        final current = await repo.page();
        final link = current.items
            .firstWhere((n) => n.target?.kind == 'task')
            .target!;
        expect(
          await repo.resolve(link, cancellation: RiderReadCancellation()),
          isA<NotificationTaskDestination>(),
        );
        loseBefore = true;
        await expectLater(
          repo.acknowledge([late['id'] as String], mayDispatch: () => true),
          throwsA(isA<AccountFailure>()),
        );
        final unknown = (await repo.pending())!;
        expect(await repo.reconcile(mayDispatch: () => true), isNull);
        final retried = await repo.reconcile(
          retryUnknown: true,
          mayDispatch: () => true,
        );
        expect(retried!.intent.key, unknown.key);
        final foreign = await other.login(
          info['other_email'] as String,
          info['other_password'] as String,
        );
        final otherWork = OperationsRepository(
          other,
          accountId: foreign.id,
          journal: SecureCommandJournal(
            origin: config.origin,
            accountId: foreign.id,
          ),
          writesVerified: false,
          isCurrent: () => true,
        );
        final foreignJournal = SecureCommandJournal(
          origin: config.origin,
          accountId: foreign.id,
          scope: 'notifications',
        );
        await foreignJournal.clear();
        try {
          final foreignRepo = OperationsNotificationsRepository(
            other,
            accountId: foreign.id,
            journal: foreignJournal,
            isCurrent: () => true,
            readHome: otherWork.home,
            writesVerified: true,
          );
          await expectLater(
            foreignRepo.acknowledge([
              first['id'] as String,
            ], mayDispatch: () => true),
            throwsA(
              isA<AccountFailure>().having(
                (e) => e.status,
                'foreign read',
                404,
              ),
            ),
          );
        } finally {
          await foreignJournal.clear();
        }
        snapshot = await control('notifications_snapshot');
        expect(snapshot['unread'], 0);
        expect(snapshot['commands'], 3);
        expect(snapshot['other_count'], otherCount);
        final custodyAfter = await control('counts');
        expect(custodyAfter['parcels'], custodyBefore['parcels']);
        expect(custodyAfter['cash'], custodyBefore['cash']);
      } finally {
        await noticeJournal?.clear();
        await workJournal?.clear();
        await auth.logout();
        await other.logout();
        dio.close(force: true);
      }
    },
    skip: base.isEmpty || token.isEmpty,
  );
}
