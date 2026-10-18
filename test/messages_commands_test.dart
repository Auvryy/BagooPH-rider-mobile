import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/messages/data/messages_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/messages_support.dart';

void main() {
  test(
    'chat activation is independent and disabled writes make no request',
    () async {
      const config = AppConfig(
        'https://example.test/api/v1',
        operationsWritesVerified: true,
        parcelWritesVerified: true,
      );
      expect(config.messagesWritesVerified, isFalse);
      final h = MessagesHarness(enabled: false);
      addTearDown(h.dispose);
      await expectLater(h.send(), throwsA(isA<AccountFailure>()));
      expect(h.api.calls, isEmpty);
      expect(h.journal.value, isNull);
    },
  );
  test('send persists normalized original body before first dispatch and checks actor identity', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        expect(h.journal.value, isNotNull);
        expect(body, {'text': 'Hello seller 123'});
        expect(headers['Idempotency-Key'], h.journal.value!.key);
        expect(headers['X-Request-ID'], isNot(h.journal.value!.key));
        expect(path, 'rider/conversations/$pickupThread/messages');
      }
      return h.respond(path, method, body, headers);
    };
    final result = await h.send('  Ｈｅｌｌｏ seller １２３  ');
    expect(result.message!.text, 'Hello seller 123');
    expect(h.journal.value, isNull);
    expect(h.api.calls.map((c) => c.method), ['GET', 'GET', 'POST']);
  });
  test('secure storage failure prevents a message write', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    h.journal.fail = true;
    await expectLater(h.send(), throwsA(isA<StateError>()));
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
  });
  test(
    'fresh capability and phase denial do not persist a replacement message',
    () async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      h.available = false;
      await expectLater(h.send(), throwsA(isA<AccountFailure>()));
      expect(h.journal.value, isNull);
      h.available = true;
      h.canSend = false;
      await expectLater(h.send(), throwsA(isA<AccountFailure>()));
      expect(h.journal.value, isNull);
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      final read = await h.repository.acknowledge(
        h.thread,
        '51',
        mayDispatch: () => true,
      );
      expect(read.throughMessageId, '51');
    },
  );
  test('lost response survives restart and unknown retry keeps the original UUID and payload', () async {
    final h = MessagesHarness();
    addTearDown(h.dispose);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Response lost', unconfirmed: true);
      }
      return h.respond(path, method, body, headers);
    };
    await expectLater(h.send(), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    h.journal.value = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    final restart = OperationsMessagesRepository(
      h.api,
      accountId: '5',
      journal: h.journal,
      writesVerified: true,
      isCurrent: () => true,
      readHome: h.operations.home,
      avatarOrigin: null,
      now: () => h.now,
    );
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/commands/')) {
        throw const AccountFailure(
          'Unknown',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      if (method == 'POST') {
        expect(headers['Idempotency-Key'], original.key);
        expect(body, original.body);
      }
      return h.respond(path, method, body, headers);
    };
    expect(await restart.reconcile(mayDispatch: () => true), isNull);
    await expectLater(
      h.send('A different message.'),
      throwsA(isA<AccountFailure>()),
    );
    final replay = await restart.reconcile(
      retryUnknown: true,
      mayDispatch: () => true,
    );
    expect(replay!.intent.key, original.key);
    expect(h.journal.value, isNull);
  });
  for (final changed in [
    'idempotency_key',
    'resource',
    'action',
    'text',
    'sender',
    'boundary',
  ]) {
    test(
      'a mismatched committed $changed remains uncertain and retains the original intent',
      () async {
        final h = MessagesHarness();
        addTearDown(h.dispose);
        h.api.respond = (path, method, body, headers) async {
          if (method != 'POST') return h.respond(path, method, body, headers);
          final result = messageCommandEnvelope(h.journal.value!);
          switch (changed) {
            case 'idempotency_key':
              result['data']['idempotency_key'] = commandUuid();
            case 'resource':
              result['data']['resource'] = deliveryThread;
            case 'action':
              result['data']['action'] = 'message.read';
            case 'text':
              result['data']['result']['text'] = 'A different message.';
            case 'sender':
              result['data']['result']['sender_id'] = '6';
            case 'boundary':
              result['data']['result']['through_message_id'] = '52';
          }
          return result;
        };
        final action = changed == 'boundary'
            ? h.repository.acknowledge(h.thread, '51', mayDispatch: () => true)
            : h.send();
        await expectLater(
          action,
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
  test('retained committed results reconcile after expiry even when new writes are disabled', () async {
    final h = MessagesHarness(enabled: false);
    addTearDown(h.dispose);
    h.journal.value = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'message.send',
      resource: pickupThread,
      body: {'text': 'Original parcel update.'},
      createdAt: DateTime.utc(2026, 10, 1),
    );
    h.api.respond = (path, method, body, headers) async =>
        messageCommandEnvelope(h.journal.value!, expired: true);
    final result = await h.repository.reconcile(mayDispatch: () => false);
    expect(result!.retryExpired, isTrue);
    expect(h.api.calls.single.method, 'GET');
    expect(h.journal.value, isNull);
  });
  test(
    'unknown expired or re-assigned original never receives a new send UUID',
    () async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      final original = CommandIntent(
        accountId: '5',
        key: commandUuid(),
        action: 'message.send',
        resource: pickupThread,
        body: {'text': 'Original parcel update.'},
        createdAt: DateTime.utc(2026, 10, 1),
      );
      h.journal.value = original;
      h.api.respond = (path, method, body, headers) async {
        if (path.startsWith('rider/commands/')) {
          throw const AccountFailure(
            'Unknown',
            status: 404,
            code: 'COMMAND_UNKNOWN',
          );
        }
        return h.respond(path, method, body, headers);
      };
      await expectLater(
        h.repository.reconcile(retryUnknown: true, mayDispatch: () => true),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value!.key, original.key);
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );
  test(
    'backgrounding during preflight and duplicate taps cannot dispatch',
    () async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      final barrier = Completer<Map<String, dynamic>>();
      bool visible = true;
      h.api.respond = (path, method, body, headers) async =>
          path.contains('/messages?')
          ? barrier.future
          : h.respond(path, method, body, headers);
      final sending = h.repository.send(
        h.thread,
        'A parcel update.',
        mayDispatch: () => visible,
      );
      await Future<void>.delayed(Duration.zero);
      await expectLater(h.send(), throwsA(isA<AccountFailure>()));
      visible = false;
      barrier.complete(
        historyEnvelope(parcelConversationJson(), [parcelMessageJson()]),
      );
      await expectLater(sending, throwsA(isA<AccountFailure>()));
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(h.journal.value, isNull);
    },
  );
  test(
    'history rejects foreign sender data and wrong response identity',
    () async {
      final h = MessagesHarness();
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async => historyEnvelope(
        parcelConversationJson(),
        [parcelMessageJson(sender: '99')],
      );
      await expectLater(
        h.repository.history(pickupThread),
        throwsFormatException,
      );
      h.api.respond = (path, method, body, headers) async => historyEnvelope(
        parcelConversationJson(id: deliveryThread),
        [parcelMessageJson(sender: '4')],
      );
      await expectLater(
        h.repository.history(pickupThread),
        throwsFormatException,
      );
    },
  );
}
