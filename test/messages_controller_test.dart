import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';

import 'operations_contract_test.dart' as ops;

import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/messages_support.dart';

class ReadSession extends ops.Session implements RiderReadSessionApi {
  final cancellations = <RiderReadCancellation>[];
  @override
  Future<Map<String, dynamic>> authenticatedRead(
    String path, {
    required RiderReadCancellation cancellation,
  }) {
    cancellations.add(cancellation);
    return authenticatedRequest(path);
  }
}

void main() {
  test('listing never acknowledges unopened threads and inactive surfaces make no requests', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.controller.refresh();
    expect(h.api.calls, isEmpty);
    await h.boot(select: false);
    expect(h.controller.inbox.data, hasLength(2));
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    h.controller.setSurfaceActive(h.surface, false);
    final count = h.api.calls.length;
    await h.controller.refresh();
    expect(h.api.calls, hasLength(count));
  });
  test('drafts survive ordinary failure and remain tied to their exact original recipient', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    c.updateDraft('Private seller draft.');
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/conversations?')) {
        throw const AccountFailure('Unavailable', status: 503);
      }
      return h.respond(path, method, body, headers);
    };
    await c.refresh();
    expect(c.draft, 'Private seller draft.');
    expect(c.inbox.status, FeatureStatus.failed);
    expect(await c.sendDraft(), isFalse);
    h.api.respond = h.respond;
    await c.selectConversation(deliveryThread);
    expect(c.draft, isEmpty);
    c.updateDraft('Private buyer draft.');
    await c.selectConversation(pickupThread);
    expect(c.draft, 'Private seller draft.');
    h.canSend = false;
    await c.refresh();
    expect(c.draft, isEmpty);
    expect(c.canSend, isFalse);
  });
  test('duplicate sends lock and an unconfirmed original cannot follow a new selection', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    final response = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async => method == 'POST'
        ? response.future
        : h.respond(path, method, body, headers);
    c.updateDraft('Seller parcel update.');
    final first = c.sendDraft();
    expect(await c.sendDraft(), isFalse);
    await Future<void>.delayed(Duration.zero);
    final original = h.journal.value!;
    await c.selectConversation(deliveryThread);
    response.completeError(
      const AccountFailure('Response lost', unconfirmed: true),
    );
    expect(await first, isFalse);
    expect(c.selectedId, deliveryThread);
    expect(c.draft, isEmpty);
    expect(c.pendingIntent!.key, original.key);
    expect(c.canSend, isFalse);
    await c.selectConversation(pickupThread);
    expect(c.draft, 'Seller parcel update.');
    expect(h.api.calls.where((call) => call.method == 'POST'), hasLength(1));
  });
  test('only an incoming loaded boundary with the current render revision can acknowledge', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    final revision = c.historyRevision;
    await c.acknowledgeDisplayed(pickupThread, '999', revision);
    await c.acknowledgeDisplayed(deliveryThread, '51', revision);
    await c.refreshThread();
    await c.acknowledgeDisplayed(pickupThread, '51', revision);
    expect(h.api.calls.where((call) => call.method == 'POST'), isEmpty);
    await c.acknowledgeDisplayed(pickupThread, '51', c.historyRevision);
    expect(h.api.calls.where((call) => call.method == 'POST').single.data, {
      'through_message_id': '51',
    });
    expect(c.messages.single.isRead, isTrue);
  });
  test(
    'new incoming arrival during a read remains outside the original boundary',
    () async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      await h.boot();
      final c = h.controller;
      bool read = false;
      h.api.respond = (path, method, body, headers) async {
        if (path.contains('/messages?')) {
          return historyEnvelope(parcelConversationJson(unread: read ? 1 : 2), [
            parcelMessageJson(id: '52', text: 'A newer unseen arrival.'),
            parcelMessageJson(read: read),
          ]);
        }
        if (method == 'POST') {
          expect(body, {'through_message_id': '51'});
          read = true;
        }
        return h.respond(path, method, body, headers);
      };
      await c.acknowledgeDisplayed(pickupThread, '51', c.historyRevision);
      await c.refreshThread();
      expect(c.messages.first.id, '52');
      expect(c.messages.first.isRead, isFalse);
      expect(c.messages.last.isRead, isTrue);
    },
  );
  test('failed read retains its original request and reconciliation never resends the draft', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    c.updateDraft('A separate unsent draft.');
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Read response lost', unconfirmed: true);
      }
      return h.respond(path, method, body, headers);
    };
    await c.acknowledgeDisplayed(pickupThread, '51', c.historyRevision);
    expect(c.readError, isNotNull);
    expect(c.messages.single.isRead, isFalse);
    expect(c.pendingIntent!.action, 'message.read');
    expect(await c.sendDraft(), isFalse);
    h.api.respond = h.respond;
    await c.reconcile();
    expect(c.pendingIntent, isNull);
    expect(c.messages.single.isRead, isTrue);
    expect(c.draft, 'A separate unsent draft.');
    expect(h.api.calls.where((call) => call.method == 'POST'), hasLength(1));
  });
  test(
    'an older history response cannot restore a different selected thread',
    () async {
      final api = ReadSession();
      final h = MessagesHarness(session: api);
      addTearDown(h.dispose);
      await h.boot();
      final c = h.controller;
      final old = Completer<Map<String, dynamic>>();
      h.api.respond = (path, method, body, headers) async =>
          path.contains('/$pickupThread/messages?')
          ? old.future
          : h.respond(path, method, body, headers);
      final request = c.refreshThread();
      final cancelled = api.cancellations.last;
      await c.selectConversation(deliveryThread);
      expect(cancelled.cancelled, isTrue);
      old.complete(
        historyEnvelope(parcelConversationJson(), [
          parcelMessageJson(text: 'Obsolete seller text.'),
        ]),
      );
      await request;
      expect(c.thread!.id, deliveryThread);
      expect(c.messages.single.senderId, '4');
    },
  );
  test('background clears visible private data and ignores late history until fresh resume authorization', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    c.updateDraft('Original draft.');
    final old = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async =>
        path.contains('/messages?')
        ? old.future
        : h.respond(path, method, body, headers);
    final request = c.refreshThread();
    c.setForeground(false);
    old.complete(
      historyEnvelope(parcelConversationJson(), [parcelMessageJson()]),
    );
    await request;
    expect(c.detail.data, isNull);
    expect(c.inbox.data, isNull);
    expect(c.messages, isEmpty);
    expect(c.canSend, isFalse);
    h.api.respond = h.respond;
    h.canSend = false;
    c.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(c.thread!.canSend, isFalse);
    expect(c.draft, isEmpty);
  });
  test('capability and session loss clear drafts and cannot retain private message state', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    c.updateDraft('Private draft.');
    h.available = false;
    await c.refresh();
    expect(c.draft, isEmpty);
    expect(c.messages, isEmpty);
    expect(c.inbox.status, FeatureStatus.unavailable);
    h.available = true;
    await c.refresh();
    c.updateDraft('Another private draft.');
    h.api.respond = (path, method, body, headers) async {
      throw const AccountFailure('Access removed', status: 403);
    };
    await c.refreshThread();
    expect(c.selectedId, isNull);
    expect(c.draft, isEmpty);
    expect(c.messages, isEmpty);
    expect(h.ended, hasLength(1));
  });
  test('conversation and history pages append by stable ID without duplicate messages', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = h.controller;
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/conversations?')) {
        final page = int.parse(Uri.parse(path).queryParameters['page']!);
        return conversationEnvelope(
          page == 1
              ? [parcelConversationJson()]
              : [
                  parcelConversationJson(),
                  parcelConversationJson(id: deliveryThread),
                ],
          page: page,
          total: 21,
        );
      }
      if (path.contains('/messages?')) {
        final page = int.parse(Uri.parse(path).queryParameters['page']!);
        return historyEnvelope(
          parcelConversationJson(),
          page == 1
              ? [parcelMessageJson(id: '51')]
              : [parcelMessageJson(id: '51'), parcelMessageJson(id: '50')],
          page: page,
          total: 21,
        );
      }
      return h.respond(path, method, body, headers);
    };
    await c.refresh();
    await c.loadMoreConversations();
    expect(c.inbox.data!.map((t) => t.id), [pickupThread, deliveryThread]);
    await c.refreshThread(older: true);
    expect(c.messages.map((m) => m.id), ['51', '50']);
  });
  test(
    'dispose clears private drafts and ignores a late send result',
    () async {
      final h = MessagesHarness();
      await h.boot();
      final c = h.controller;
      c.updateDraft('Private test update.');
      final future = Completer<Map<String, dynamic>>();
      h.api.respond = (path, method, body, headers) async => method == 'POST'
          ? future.future
          : h.respond(path, method, body, headers);
      final request = c.sendDraft();
      await Future<void>.delayed(Duration.zero);
      final original = h.journal.value!;
      c.dispose();
      future.complete(messageCommandEnvelope(original));
      expect(await request, isFalse);
      expect(c.draft, isEmpty);
      expect(c.inbox.data, isNull);
      expect(c.messages, isEmpty);
    },
  );
}
