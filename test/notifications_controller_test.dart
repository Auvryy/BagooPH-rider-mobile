import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/notifications_support.dart';

void main() {
  test('hidden and Home-only surfaces cannot acknowledge anything; server aggregate drives badge', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.controller.refresh();
    expect(h.api.calls, isEmpty);
    await h.boot(inbox: false);
    expect(h.controller.unreadCount, 3);
    expect(h.controller.inbox.data, hasLength(3));
    h.display([noticeId(1)]);
    await h.controller.acknowledgeDisplayed([
      noticeId(1),
    ], h.controller.revision);
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
  });
  test('only the exact rendered snapshot is acknowledged and new arrivals remain unread', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.display([noticeId(3), noticeId(2)]);
    await h.controller.acknowledgeDisplayed([
      noticeId(1),
    ], h.controller.revision);
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    h.rows.insert(0, notificationJson(4));
    await h.controller.acknowledgeDisplayed([
      noticeId(3),
      noticeId(2),
    ], h.controller.revision);
    final posted = h.api.calls.singleWhere((c) => c.method == 'POST');
    expect(posted.data, {
      'displayed_ids': [noticeId(2), noticeId(3)],
    });
    expect(h.controller.unreadCount, 2);
    expect(h.controller.inbox.data!.first.id, noticeId(4));
    expect(h.controller.inbox.data!.first.unread, isTrue);
  });
  test('a refresh invalidates old rendered IDs and a selected single read uses the original notice', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.display([noticeId(3)]);
    final previous = h.controller.revision;
    await h.controller.refresh();
    await h.controller.acknowledgeDisplayed([noticeId(3)], previous);
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    h.controller.select(h.first);
    h.display([h.first.id]);
    await h.controller.acknowledgeDisplayed([
      h.first.id,
    ], h.controller.revision);
    expect(h.controller.selected!.unread, isFalse);
    expect(h.controller.unreadCount, 2);
  });
  test('offset-page overlaps deduplicate, sort newest-first and later-page errors retain loaded data', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    h.rows = List.generate(21, (i) => notificationJson(21 - i));
    await h.boot();
    h.api.respond = (path, method, body, headers) async {
      if (path.contains('page=2&')) {
        return notificationEnvelope(
          [notificationJson(2), notificationJson(1)],
          page: 2,
          total: 21,
          unread: 21,
        );
      }
      return h.respond(path, method, body, headers);
    };
    await h.controller.loadMore();
    expect(h.controller.inbox.data, hasLength(21));
    expect(h.controller.inbox.data!.last.id, noticeId(1));
    await h.controller.refresh();
    h.api.respond = (path, method, body, headers) async {
      if (path.contains('page=2&')) {
        throw const AccountFailure('Network interrupted');
      }
      return h.respond(path, method, body, headers);
    };
    await h.controller.loadMore();
    expect(h.controller.inbox.data, hasLength(20));
    expect(h.controller.moreError, 'Network interrupted');
  });
  test(
    'inbox loading is bounded and refresh starts again at page one',
    () async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.rows = List.generate(205, (i) => notificationJson(205 - i));
      await h.boot();
      for (var i = 0; i < 15; i++) {
        await h.controller.loadMore();
      }
      expect(h.controller.inbox.data, hasLength(200));
      expect(h.controller.hasMore, isFalse);
      expect(h.controller.unreadCount, 205);
      await h.controller.refresh();
      expect(h.controller.inbox.data, hasLength(20));
      expect(h.controller.hasMore, isTrue);
    },
  );
  test('background cancels a real read, clears visible data and ignores the late old response', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.controller.select(h.first);
    final gate = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async =>
        path.startsWith('rider/notifications?')
        ? gate.future
        : h.respond(path, method, body, headers);
    final reading = h.controller.refresh();
    await Future<void>.delayed(Duration.zero);
    final cancel = h.api.cancellations.last;
    h.controller.setForeground(false);
    expect(cancel.cancelled, isTrue);
    expect(h.controller.inbox.data, isNull);
    expect(h.controller.unreadCount, isNull);
    expect(h.controller.selected, isNull);
    gate.complete(notificationEnvelope([notificationJson(99)]));
    await reading;
    expect(h.controller.inbox.data, isNull);
    h.api.respond = h.respond;
    h.controller.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(h.controller.inbox.status, FeatureStatus.ready);
    expect(h.controller.inbox.data!.first.id, noticeId(3));
  });
  test('401 and 403 clear all private state and leave unresolved command storage intact', () async {
    for (final status in [401, 403]) {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      await h.boot();
      h.journal.value = CommandIntent(
        accountId: '5',
        key: commandUuid(),
        action: 'notification.read',
        resource: 'notifications',
        body: {
          'displayed_ids': [noticeId(1)],
        },
        createdAt: h.now,
      );
      h.api.respond = (path, method, body, headers) async {
        throw AccountFailure('Access removed', status: status);
      };
      await h.controller.refresh();
      expect(h.controller.inbox.status, FeatureStatus.unavailable);
      expect(h.controller.inbox.data, isNull);
      expect(h.controller.unreadCount, isNull);
      expect(h.controller.selected, isNull);
      expect(h.ended, ['Access removed']);
      expect(h.journal.value, isNotNull);
    }
  });
  test('uncertain read never flips UI to read and foreground refresh recovers only the saved result', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.display([noticeId(3)]);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Response uncertain', unconfirmed: true);
      }
      return h.respond(path, method, body, headers);
    };
    await h.controller.acknowledgeDisplayed([
      noticeId(3),
    ], h.controller.revision);
    final key = h.journal.value!.key;
    expect(h.first.unread, isTrue);
    expect(h.controller.pendingIntent!.key, key);
    expect(h.controller.readError, 'Response uncertain');
    h.unknown = true;
    await h.controller.refresh();
    expect(h.controller.canRetryOriginal, isTrue);
    h.rows.first['read_at'] = '2026-10-19T03:05:00.000Z';
    h.unknown = false;
    await h.controller.refresh();
    expect(h.first.unread, isFalse);
    expect(h.journal.value, isNull);
    expect(h.controller.pendingIntent, isNull);
    expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
  });
  test('a saved read can be explicitly retried after its original displayed IDs leave page one', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.display([noticeId(3)]);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Lost', unconfirmed: true);
      }
      return h.respond(path, method, body, headers);
    };
    await h.controller.acknowledgeDisplayed([
      noticeId(3),
    ], h.controller.revision);
    final key = h.journal.value!.key;
    h.rows = List.generate(25, (i) => notificationJson(25 - i));
    h.unknown = true;
    h.api.respond = h.respond;
    await h.controller.refresh();
    expect(h.controller.inbox.data!.any((n) => n.id == noticeId(3)), isFalse);
    await h.controller.reconcile(retryUnknown: true);
    final posts = h.api.calls.where((c) => c.method == 'POST').toList();
    expect(posts, hasLength(2));
    expect(posts.last.headers['Idempotency-Key'], key);
    expect(posts.last.path, 'rider/notifications/${noticeId(3)}/read');
    expect(h.controller.unreadCount, 24);
  });
  test('target access is fetched on open, 404 keeps notice readable and selection cancels late targets', () async {
    final h = NotificationsHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.controller.select(h.first);
    expect(
      await h.controller.resolveSelected(),
      isA<NotificationTaskDestination>(),
    );
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/tasks/')) {
        throw const AccountFailure('Gone', status: 404);
      }
      return h.respond(path, method, body, headers);
    };
    expect(await h.controller.resolveSelected(), isNull);
    expect(h.controller.selected!.heading, isNotEmpty);
    expect(h.controller.targetError, contains('no longer available'));
    final gate = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async => gate.future;
    final opening = h.controller.resolveSelected();
    await Future<void>.delayed(Duration.zero);
    final cancel = h.api.cancellations.last;
    h.controller.select(null);
    expect(cancel.cancelled, isTrue);
    gate.complete({'data': {}});
    expect(await opening, isNull);
    expect(h.controller.selected, isNull);
  });
  testWidgets(
    'quota cooldown blocks repeated calls until the server delay expires',
    (tester) async {
      final h = NotificationsHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async {
        throw const AccountFailure('Wait', status: 429, retryAfterSeconds: 5);
      };
      h.controller.setSurfaceActive(h.surface, true, inbox: true);
      await tester.pump();
      expect(h.controller.coolingDown, isTrue);
      final count = h.api.calls.length;
      await h.controller.refresh();
      await h.controller.reconcile();
      expect(h.api.calls, hasLength(count));
      h.api.respond = h.respond;
      await tester.pump(const Duration(seconds: 6));
      expect(h.controller.coolingDown, isFalse);
      await h.controller.refresh();
      expect(h.controller.inbox.status, FeatureStatus.ready);
    },
  );
}
