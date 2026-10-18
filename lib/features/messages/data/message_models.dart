import '../../../core/commands/command_intent.dart';
import '../../../core/commands/message_validation.dart';
import '../../../core/network/wire.dart';

class ParcelMessage {
  ParcelMessage.fromJson(Map<String, dynamic> json)
    : id = Wire.id(json['id']),
      senderId = Wire.id(json['sender_id']),
      text = Wire.string(json['text']),
      fromRider = Wire.boolean(json['from_rider']),
      isRead = Wire.boolean(json['is_read']),
      recordedAt = Wire.time(json['recorded_at']);

  final String id, senderId, text;
  final bool fromRider, isRead;
  final DateTime recordedAt;

  ParcelMessage read() => ParcelMessage.fromJson({
    'id': id,
    'sender_id': senderId,
    'text': text,
    'from_rider': fromRider,
    'is_read': true,
    'recorded_at': recordedAt.toIso8601String(),
  });
}

class ParcelConversation {
  ParcelConversation.fromJson(Map<String, dynamic> json)
    : id = Wire.string(json['id']),
      deliveryId = Wire.id(json['delivery_id']),
      assignmentReference = Wire.nullableString(json['assignment_reference']),
      phase = Wire.string(json['phase']),
      tracking = Wire.string(json['tracking_number']),
      canSend = Wire.boolean(json['can_send']),
      sendDenial = Wire.nullableString(json['send_denial']),
      unreadCount = Wire.count(json['unread_count']),
      lastMessage = json['last_message'] == null
          ? null
          : ParcelMessage.fromJson(Wire.object(json['last_message'])) {
    final parts = messageThreadParts(id);
    final participant = Wire.object(json['participant']);
    participantId = Wire.id(participant['id']);
    participantName = Wire.string(participant['name']);
    participantRole = Wire.string(participant['role']);
    avatarPath = _avatarPath(participant['avatar_url']);
    assignmentId = parts.assignmentId;
    if (parts.deliveryId != deliveryId ||
        parts.phase != phase ||
        parts.participantId != participantId ||
        participantRole != (phase == 'pickup' ? 'seller' : 'buyer') ||
        (canSend && sendDenial != null)) {
      Wire.invalid();
    }
  }

  final String id, deliveryId, tracking, phase;
  final String? assignmentReference, sendDenial;
  final bool canSend;
  final int unreadCount;
  final ParcelMessage? lastMessage;
  late final String assignmentId,
      participantId,
      participantName,
      participantRole;
  late final String? avatarPath;
  String get phaseLabel =>
      phase == 'pickup' ? 'Seller · Pickup' : 'Buyer · Delivery';
  String get taskId => '$phase-$deliveryId';

  static String? _avatarPath(Object? value) {
    if (value == null) return null;
    final path = Wire.string(value);
    return RegExp(r'^/storage/avatars/[A-Za-z0-9._/-]+$')
                    .firstMatch(path)
                    ?.end ==
                path.length &&
            !path.contains('..') &&
            !path.endsWith('/')
        ? path
        : null;
  }
}

class MessagePagination {
  MessagePagination.fromJson(Map<String, dynamic> json)
    : page = Wire.count(json['page']),
      perPage = Wire.count(json['per_page']),
      total = Wire.count(json['total']),
      lastPage = Wire.count(json['last_page']) {
    if (page < 1 ||
        page > 10000 ||
        perPage < 1 ||
        perPage > 50 ||
        lastPage < 1 ||
        lastPage != (total == 0 ? 1 : (total + perPage - 1) ~/ perPage)) {
      Wire.invalid();
    }
  }
  final int page, perPage, total, lastPage;
  bool get hasMore => page < lastPage && page < 10000;
}

class ConversationPage {
  ConversationPage.fromJson(Map<String, dynamic> json)
    : items = List.unmodifiable(
        _items(json['items']).map(ParcelConversation.fromJson),
      ),
      pagination = MessagePagination.fromJson(Wire.object(json['pagination'])) {
    if (items.length > pagination.perPage ||
        items.map((item) => item.id).toSet().length != items.length) {
      Wire.invalid();
    }
  }
  final List<ParcelConversation> items;
  final MessagePagination pagination;
}

class MessageHistoryPage {
  MessageHistoryPage.fromJson(Map<String, dynamic> json)
    : thread = ParcelConversation.fromJson(Wire.object(json['thread'])),
      items = List.unmodifiable(
        _items(json['items']).map(ParcelMessage.fromJson),
      ),
      pagination = MessagePagination.fromJson(Wire.object(json['pagination'])) {
    if (items.length > pagination.perPage ||
        items.map((item) => item.id).toSet().length != items.length) {
      Wire.invalid();
    }
    for (var i = 1; i < items.length; i++) {
      if (BigInt.parse(items[i - 1].id) <= BigInt.parse(items[i].id)) {
        Wire.invalid();
      }
    }
  }
  final ParcelConversation thread;
  final List<ParcelMessage> items;
  final MessagePagination pagination;
}

Iterable<Map<String, dynamic>> _items(Object? value) =>
    value is List ? value.map(Wire.object) : Wire.invalid();

class MessageCommandResult {
  MessageCommandResult.fromJson(Map<String, dynamic> json, this.intent) {
    if (Wire.uuid(json['idempotency_key']) != intent.key ||
        json['action'] != intent.action ||
        json['resource'] != intent.resource ||
        json['state'] != 'committed') {
      Wire.invalid();
    }
    final recorded = Wire.time(json['recorded_at']);
    final expires = Wire.time(json['expires_at']);
    if (!expires.isAfter(recorded)) Wire.invalid();
    retryExpired = Wire.boolean(json['retry_expired']);
    replayed = Wire.boolean(json['replayed']);
    final result = Wire.object(json['result']);
    if (intent.action == 'message.send') {
      message = ParcelMessage.fromJson(result);
      if (message!.senderId != intent.accountId ||
          !message!.fromRider ||
          message!.text != intent.body['text']) {
        Wire.invalid();
      }
    } else if (intent.action == 'message.read') {
      throughMessageId = Wire.id(result['through_message_id']);
      if (throughMessageId != intent.body['through_message_id']) Wire.invalid();
    } else {
      Wire.invalid();
    }
  }
  final CommandIntent intent;
  late final bool retryExpired, replayed;
  ParcelMessage? message;
  String? throughMessageId;
}
