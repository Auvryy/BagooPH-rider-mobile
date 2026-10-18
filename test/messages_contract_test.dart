import 'package:bagoo_rider_mobile/core/commands/message_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/messages/data/message_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/messages_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('thread references preserve full exact assignment and recipient identifiers', () {
    const id =
        'final_mile-9223372036854775807-9007199254740993-9223372036854775806';
    final thread = ParcelConversation.fromJson(parcelConversationJson(id: id));
    expect(thread.deliveryId, '9223372036854775807');
    expect(thread.assignmentId, '9007199254740993');
    expect(thread.participantId, '9223372036854775806');
    for (final invalid in [
      'pickup-1-2-03',
      'pickup-1-9223372036854775808-3',
      'pickup-1-2-3\n',
      'pickup-1-2-3/messages',
      'buyer-1-2-3',
    ]) {
      expect(() => messageThreadParts(invalid), throwsFormatException);
    }
    final json = parcelConversationJson();
    json['participant']['id'] = '4';
    expect(() => ParcelConversation.fromJson(json), throwsFormatException);
  });
  test('nullable avatar/preview stay nullable and foreign traversal avatars use initials', () {
    final json = parcelConversationJson();
    expect(ParcelConversation.fromJson(json).lastMessage, isNull);
    for (final path in [
      'https://foreign.test/avatar.png',
      '/storage/avatars/../proof.png',
      '/storage/avatars/a.png?token=1',
      '/storage/avatars/a.png\n',
    ]) {
      json['participant']['avatar_url'] = path;
      expect(ParcelConversation.fromJson(json).avatarPath, isNull);
    }
    json['participant']['avatar_url'] = '/storage/avatars/5/profile.png';
    expect(
      ParcelConversation.fromJson(json).avatarPath,
      '/storage/avatars/5/profile.png',
    );
  });
  test('history is newest first and malformed pagination is never an empty success', () {
    final envelope = historyEnvelope(parcelConversationJson(), [
      parcelMessageJson(id: '9007199254740993'),
      parcelMessageJson(id: '51'),
    ]);
    final page = MessageHistoryPage.fromJson(envelope['data']);
    expect(page.items.first.id, '9007199254740993');
    envelope['data']['items'] = [
      parcelMessageJson(id: '51'),
      parcelMessageJson(id: '52'),
    ];
    expect(
      () => MessageHistoryPage.fromJson(envelope['data']),
      throwsFormatException,
    );
    final empty = conversationEnvelope([]);
    expect(
      ConversationPage.fromJson(empty['data']).pagination.hasMore,
      isFalse,
    );
    for (final pair in [
      ('page', 0),
      ('page', 10001),
      ('per_page', 51),
      ('last_page', 0),
    ]) {
      final json = conversationEnvelope([]);
      json['data']['pagination'][pair.$1] = pair.$2;
      expect(
        () => ConversationPage.fromJson(json['data']),
        throwsFormatException,
      );
    }
  });
  test('plain-text NFKC normalization matches the accepted send policy', () {
    expect(messageText('  Ｈｅｌｌｏ １２３  '), 'Hello 123');
    expect(
      messageText('Cafe\u0301\nPlease use the entrance.'),
      'Café\nPlease use the entrance.',
    );
    expect(messageText('\n A parcel update.\r\n'), 'A parcel update.');
    expect(messageText('a' * 1000), 'a' * 1000);
    for (final bad in [
      '',
      '   ',
      '!!!',
      'a' * 1001,
      '<script>Hi</script>',
      '＜b＞Hi＜/b＞',
      'Hi\u200b',
      'Hi\u034f',
      'Hi\ufe0f',
      'Hi\tthere',
      'Hi\rthere',
      'data: hidden',
      'onclick = hello',
    ]) {
      expect(
        () => messageText(bad),
        throwsA(isA<AccountFailure>()),
        reason: bad,
      );
    }
  });
  test('message intent roundtrip keeps only exact endpoint body and rejects changed normalization', () {
    final intent = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'message.send',
      resource: pickupThread,
      body: {'text': 'A parcel update.'},
      createdAt: DateTime.utc(2026, 10, 18),
    );
    final restored = CommandIntent.fromJson(intent.toJson());
    expect(restored.body, {'text': 'A parcel update.'});
    expect(restored.path, 'rider/conversations/$pickupThread/messages');
    expect(
      () => CommandIntent(
        accountId: '5',
        key: commandUuid(),
        action: 'message.send',
        resource: pickupThread,
        body: {'text': 'Ａ parcel update.'},
        createdAt: DateTime.utc(2026),
      ),
      throwsFormatException,
    );
  });
  test('protected messages journal isolates accounts APIs and the existing parcel journal', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SecureCommandJournal store({
      String account = '5',
      String host = 'https://example.test/api/v1',
      String scope = 'messages',
    }) => SecureCommandJournal(
      origin: Uri.parse(host),
      accountId: account,
      scope: scope,
    );
    final original = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'message.read',
      resource: pickupThread,
      body: {'through_message_id': '51'},
      createdAt: DateTime.utc(2026, 10, 18),
    );
    await store().write(original);
    expect((await store().read())!.key, original.key);
    expect(await store(account: '6').read(), isNull);
    expect(await store(host: 'https://other.test/api/v1').read(), isNull);
    expect(await store(scope: 'work').read(), isNull);
    await store(scope: 'work').clear();
    expect((await store().read())!.key, original.key);
  });
}
