import 'package:bagoo_rider_mobile/core/commands/notification_validation.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:bagoo_rider_mobile/features/notifications/presentation/notification_format.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/notifications_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'unknown notice types, absent copy and unavailable links remain readable',
    () {
      final json = notificationJson(1)
        ..addAll({
          'type': 'future-event',
          'title': null,
          'body': null,
          'target': {
            'kind': 'future',
            'id': '1',
            'href': 'https://outside.test',
          },
        });
      final value = RiderNotification.fromJson(json);
      expect(value.heading, 'Rider update');
      expect(value.body, isNull);
      expect(value.target, isNull);
      expect(value.unread, isTrue);
      json['id'] = 'NOT-A-UUID';
      expect(() => RiderNotification.fromJson(json), throwsFormatException);
    },
  );
  test('native destinations require exact allowlisted relative routes and exact identifiers', () {
    const id = 'final_mile-9223372036854775807';
    final value = NotificationTarget.parse({
      'kind': 'task',
      'id': id,
      'href': '/api/v1/rider/tasks/$id',
    });
    expect(value!.id, id);
    for (final href in [
      'https://bagoo.test/api/v1/rider/tasks/$id',
      '/api/v1/rider/tasks/$id?token=secret',
      '/api/v1/rider/tasks/$id/../proof',
      '/api/v1/rider/tasks/pickup-1',
      '/api/v1/rider/tasks/$id\n',
    ]) {
      expect(
        NotificationTarget.parse({'kind': 'task', 'id': id, 'href': href}),
        isNull,
      );
    }
    for (final id in ['01', '9223372036854775808', '1/read', '1\n']) {
      expect(
        NotificationTarget.parse({
          'kind': 'cash',
          'id': id,
          'href': '/api/v1/rider/cash/$id',
        }),
        isNull,
      );
    }
    expect(
      NotificationTarget.parse({
        'kind': 'company_request',
        'id': '1',
        'href': '/api/v1/rider/company-requests/1',
      }),
      isNull,
    );
  });
  test('pagination preserves server aggregate rather than the number loaded and rejects malformed pages', () {
    final json =
        notificationEnvelope(
              [notificationJson(1)],
              total: 999,
              unread: 850,
            )['data']
            as Map<String, dynamic>;
    final page = NotificationPage.fromJson(json);
    expect(page.unreadCount, 850);
    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    for (final pair in [('page', 0), ('per_page', 51), ('last_page', 0)]) {
      final invalid = notificationEnvelope([])['data'] as Map<String, dynamic>;
      invalid['pagination'][pair.$1] = pair.$2;
      expect(() => NotificationPage.fromJson(invalid), throwsFormatException);
    }
    json['items'] = [notificationJson(1), notificationJson(1)];
    expect(() => NotificationPage.fromJson(json), throwsFormatException);
  });
  test('displayed IDs are distinct canonical UUIDs and immutable through intent roundtrip', () {
    final body = [noticeId(2), noticeId(1)];
    final intent = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'notification.read',
      resource: 'notifications',
      body: {'displayed_ids': body},
      createdAt: DateTime.utc(2026, 10, 19),
    );
    body.clear();
    expect(intent.body['displayed_ids'], [noticeId(1), noticeId(2)]);
    expect(
      () => (intent.body['displayed_ids'] as List).clear(),
      throwsUnsupportedError,
    );
    final restored = CommandIntent.fromJson(intent.toJson());
    expect(restored.body, intent.body);
    expect(restored.path, 'rider/notifications/read-through');
    for (final invalid in [
      [],
      [noticeId(1), noticeId(1)],
      ['ABCDEF00-0000-4000-8000-000000000001'],
      List.generate(51, noticeId),
    ]) {
      expect(() => notificationIds(invalid), throwsFormatException);
    }
  });
  test('protected notice journal isolates account, API, work and Messages without changing old work keys', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SecureCommandJournal store({
      String account = '5',
      String host = 'https://example.test/api/v1',
      String scope = 'notifications',
    }) => SecureCommandJournal(
      origin: Uri.parse(host),
      accountId: account,
      scope: scope,
    );
    final notice = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'notification.read',
      resource: 'notifications',
      body: {
        'displayed_ids': [noticeId(1)],
      },
      createdAt: DateTime.utc(2026, 10, 19),
    );
    await store().write(notice);
    expect(
      (await store().read())!.path,
      'rider/notifications/${noticeId(1)}/read',
    );
    expect(await store(account: '6').read(), isNull);
    expect(await store(host: 'https://other.test/api/v1').read(), isNull);
    for (final scope in ['work', 'messages']) {
      expect(await store(scope: scope).read(), isNull);
      await expectLater(
        store(scope: scope).write(notice),
        throwsFormatException,
      );
    }
    final duty = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'duty',
      resource: 'rider',
      body: {'on_duty': true},
      createdAt: DateTime.utc(2026, 10, 19),
    );
    await store(scope: 'work').write(duty);
    expect((await store(scope: 'work').read())!.body, {'on_duty': true});
    await expectLater(store().write(duty), throwsFormatException);
  });
  test('linked cash preserves integer-cent precision and PHT dates without inferred earnings', () {
    expect(
      notificationPeso('900719925474099312345'),
      '₱9,007,199,254,740,993,123.45',
    );
    expect(
      notificationTime(DateTime.utc(2026, 10, 19, 18, 5)),
      '20 Oct 2026 · 02:05 PHT',
    );
    final json = {
      'id': '9223372036854775807',
      'tracking_number': 'BGO-TEST',
      'status': 'cash_held',
      'version': '9007199254740993',
      'own_held_cents': '900719925474099312345',
      'own_remitted_cents': '0',
      'reconciled_cents': '0',
      'recorded_at': '2026-10-19T03:00:00.000Z',
    };
    expect(NotificationCash.fromJson(json).heldCents, '900719925474099312345');
    json['own_held_cents'] = '1.23';
    expect(() => NotificationCash.fromJson(json), throwsFormatException);
  });
}
