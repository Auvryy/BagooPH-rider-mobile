import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as ops;
import 'support/notifications_support.dart';

void main() {
  test('notice write activation is independent and disabled writes do not make a request', () async {
    const config = AppConfig(
      'https://example.test/api/v1',
      operationsWritesVerified: true,
      messagesWritesVerified: true,
      parcelWritesVerified: true,
    );
    expect(config.notificationsWritesVerified, isFalse);
    final h = NotificationsHarness(enabled: false);
    addTearDown(h.dispose);
    await expectLater(
      h.repository.acknowledge([noticeId(1)], mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.calls, isEmpty);
    expect(h.journal.value, isNull);
  });
  test(
    'one read persists before POST and uses an empty object with a stable UUID',
    () async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          expect(h.journal.value, isNotNull);
          expect(path, 'rider/notifications/${noticeId(1)}/read');
          expect(body, <String, dynamic>{});
          expect(headers['Idempotency-Key'], h.journal.value!.key);
          expect(headers['X-Request-ID'], isNot(h.journal.value!.key));
        }
        return h.respond(path, method, body, headers);
      };
      final result = await h.repository.acknowledge([
        noticeId(1),
      ], mayDispatch: () => true);
      expect(result.ids, [noticeId(1)]);
      expect(h.journal.value, isNull);
      expect(h.api.calls.map((c) => c.method), ['GET', 'POST']);
    },
  );
  test('bulk read keeps the exact sorted IDs and leaves a same-tick unseen arrival unread', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    final original = h.respond;
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        h.rows.insert(0, notificationJson(4));
        expect(path, 'rider/notifications/read-through');
        expect(body, {
          'displayed_ids': [noticeId(1), noticeId(2)],
        });
      }
      return original(path, method, body, headers);
    };
    await h.repository.acknowledge([
      noticeId(2),
      noticeId(1),
    ], mayDispatch: () => true);
    final page = await h.repository.page();
    expect(page.unreadCount, 2);
    expect(page.items.first.unread, isTrue);
    expect(
      page.items
          .where((n) => [noticeId(1), noticeId(2)].contains(n.id))
          .every((n) => !n.unread),
      isTrue,
    );
  });
  test(
    'storage failure and fresh capability loss both prevent dispatch',
    () async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.journal.fail = true;
      await expectLater(
        h.repository.acknowledge([noticeId(1)], mayDispatch: () => true),
        throwsA(isA<StateError>()),
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      h.journal.fail = false;
      h.available = false;
      await expectLater(
        h.repository.acknowledge([noticeId(1)], mayDispatch: () => true),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value, isNull);
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  test('uncertain response survives restart and retry keeps original UUID and body', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Response lost', unconfirmed: true);
      }
      return h.respond(path, method, body, headers);
    };
    await expectLater(
      h.repository.acknowledge([
        noticeId(2),
        noticeId(1),
      ], mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    final original = h.journal.value!;
    h.journal.value = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    final restart = OperationsNotificationsRepository(
      h.api,
      accountId: '5',
      journal: h.journal,
      isCurrent: () => h.current,
      readHome: h.operations.home,
      writesVerified: true,
      now: () => h.now,
    );
    h.unknown = true;
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        expect(body, original.body);
        expect(headers['Idempotency-Key'], original.key);
      }
      return h.respond(path, method, body, headers);
    };
    expect(await restart.reconcile(mayDispatch: () => true), isNull);
    await expectLater(
      restart.acknowledge([noticeId(3)], mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    final result = await restart.reconcile(
      retryUnknown: true,
      mayDispatch: () => true,
    );
    expect(result!.intent.key, original.key);
    expect(h.journal.value, isNull);
  });
  for (final field in [
    'idempotency_key',
    'action',
    'resource',
    'read_ids',
    'state',
  ]) {
    test(
      'mismatched committed $field stays uncertain and retains the original intent',
      () async {
        final h = NotificationsHarness();
        addTearDown(h.dispose);
        h.api.respond = (path, method, body, headers) async {
          if (method != 'POST') return h.respond(path, method, body, headers);
          final response = notificationCommand(h.journal.value!);
          if (field == 'read_ids') {
            response['data']['result']['read_ids'] = [noticeId(99)];
          } else {
            response['data'][field] = field == 'idempotency_key'
                ? commandUuid()
                : 'different';
          }
          return response;
        };
        await expectLater(
          h.repository.acknowledge([noticeId(1)], mayDispatch: () => true),
          throwsA(
            isA<AccountFailure>().having(
              (e) => e.unconfirmed,
              'uncertain',
              true,
            ),
          ),
        );
        expect(h.journal.value, isNotNull);
      },
    );
  }
  test('unknown expired requests cannot POST while retained committed results still reconcile', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    h.journal.value = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'notification.read',
      resource: 'notifications',
      body: {
        'displayed_ids': [noticeId(1)],
      },
      createdAt: h.now.subtract(const Duration(days: 7)),
    );
    h.unknown = true;
    await expectLater(
      h.repository.reconcile(retryUnknown: true, mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    expect(h.journal.value, isNotNull);
    h.api.respond = (path, method, body, headers) async =>
        notificationCommand(h.journal.value!, expired: true);
    final result = await h.repository.reconcile(mayDispatch: () => false);
    expect(result!.retryExpired, isTrue);
    expect(h.journal.value, isNull);
  });
  test('foreign-ID rejection is definitive but quota and conflict retain the original command', () async {
    for (final (status, code, retain) in [
      (404, 'NOT_FOUND', false),
      (429, 'THROTTLED', true),
      (409, 'IDEMPOTENCY_CONFLICT', true),
    ]) {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          throw AccountFailure(
            'Rejected',
            status: status,
            code: code,
            retryAfterSeconds: status == 429 ? 30 : null,
          );
        }
        return h.respond(path, method, body, headers);
      };
      await expectLater(
        h.repository.acknowledge([noticeId(9)], mayDispatch: () => true),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value != null, retain);
    }
  });
  test('duplicate taps cannot create competing intents and coverage loss prevents late dispatch', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    final gate = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async => path == 'rider/home'
        ? gate.future
        : h.respond(path, method, body, headers);
    var visible = true;
    final first = h.repository.acknowledge([
      noticeId(1),
    ], mayDispatch: () => visible);
    final firstAssertion = expectLater(first, throwsA(isA<AccountFailure>()));
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      h.repository.acknowledge([noticeId(2)], mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    visible = false;
    gate.complete(ops.fixture('home'));
    await firstAssertion;
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    expect(h.journal.value, isNull);
  });
  test('account replacement rejects late pages and cancelled reads without returning private data', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    final gate = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async => gate.future;
    final read = h.repository.page();
    final assertion = expectLater(read, throwsA(isA<AccountFailure>()));
    h.current = false;
    gate.complete(notificationEnvelope([notificationJson(1)]));
    await assertion;
    h.current = true;
    final cancel = RiderReadCancellation()..cancel();
    await expectLater(
      h.repository.page(cancellation: cancel),
      throwsA(isA<AccountFailure>()),
    );
  });
  test('task, cash and account destinations fetch fresh allowed paths and reject response substitutions', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    final target = NotificationTarget.parse({
      'kind': 'task',
      'id': 'final_mile-1',
      'href': '/api/v1/rider/tasks/final_mile-1',
    })!;
    expect(
      await h.repository.resolve(target, cancellation: RiderReadCancellation()),
      isA<NotificationTaskDestination>(),
    );
    h.api.respond = (path, method, body, headers) async =>
        ops.fixture('pickup-task');
    await expectLater(
      h.repository.resolve(target, cancellation: RiderReadCancellation()),
      throwsFormatException,
    );
    final account = NotificationTarget.parse({
      'kind': 'account',
      'id': '6',
      'href': '/api/v1/rider/me',
    })!;
    h.api.respond = (path, method, body, headers) async => {
      'data': {
        'id': '5',
        'name': 'Example Rider',
        'email': 'rider@example.test',
        'role': 'courier',
        'status': 'active',
        'kyc_status': 'approved',
        'access_state': 'approved',
        'can_access_portal': true,
        'email_verified': true,
        'operations_api_version': 1,
      },
    };
    await expectLater(
      h.repository.resolve(account, cancellation: RiderReadCancellation()),
      throwsFormatException,
    );
    final own = NotificationTarget.parse({
      'kind': 'account',
      'id': '5',
      'href': '/api/v1/rider/me',
    })!;
    expect(
      await h.repository.resolve(own, cancellation: RiderReadCancellation()),
      isA<NotificationAccountDestination>(),
    );
    final cash = NotificationTarget.parse({
      'kind': 'cash',
      'id': '9007199254740993',
      'href': '/api/v1/rider/cash/9007199254740993',
    })!;
    h.api.respond = (path, method, body, headers) async => {
      'data': {
        'id': '9007199254740993',
        'tracking_number': 'BGO-TEST-CASH',
        'status': 'cash_held',
        'version': '1',
        'own_held_cents': '900719925474099312345',
        'own_remitted_cents': '0',
        'reconciled_cents': '0',
        'recorded_at': '2026-10-19T03:00:00.000Z',
      },
    };
    final cashResult = await h.repository.resolve(
      cash,
      cancellation: RiderReadCancellation(),
    );
    expect(
      (cashResult as NotificationCashDestination).cash.heldCents,
      '900719925474099312345',
    );
    expect(h.api.calls.last.path, 'rider/cash/9007199254740993');
  });
}
