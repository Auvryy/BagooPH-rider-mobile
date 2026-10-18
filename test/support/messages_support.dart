import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/messages/data/message_models.dart';
import 'package:bagoo_rider_mobile/features/messages/data/messages_repository.dart';
import 'package:bagoo_rider_mobile/features/messages/presentation/messages_controller.dart';

import '../operations_contract_test.dart' as ops;

const pickupThread = 'pickup-31-41-3';
const deliveryThread = 'final_mile-32-42-4';
Map<String, dynamic> parcelMessageJson({
  String id = '51',
  bool fromRider = false,
  bool read = false,
  String text = 'The parcel is ready.',
  String? sender,
}) => {
  'id': id,
  'sender_id': sender ?? (fromRider ? '5' : '3'),
  'text': text,
  'from_rider': fromRider,
  'is_read': read,
  'recorded_at': '2026-10-18T03:00:00.000Z',
};
Map<String, dynamic> parcelConversationJson({
  String id = pickupThread,
  bool canSend = true,
  int unread = 1,
  Map<String, dynamic>? last,
}) {
  final parts = id.split('-');
  return {
    'id': id,
    'delivery_id': parts[1],
    'assignment_reference': 'CHK-${parts[2]}',
    'phase': parts[0],
    'tracking_number': 'BGO-TEST${parts[1]}',
    'participant': {
      'id': parts[3],
      'name': parts[0] == 'pickup' ? 'Example seller' : 'Example buyer',
      'role': parts[0] == 'pickup' ? 'seller' : 'buyer',
      'avatar_url': null,
    },
    'can_send': canSend,
    'send_denial': canSend ? null : 'PHASE_NOT_ACTIVE',
    'unread_count': unread,
    'last_message': last,
  };
}

Map<String, dynamic> conversationEnvelope(
  List<Map<String, dynamic>> rows, {
  int page = 1,
  int? total,
  int? lastPage,
}) => {
  'data': {
    'items': rows,
    'pagination': {
      'page': page,
      'per_page': 20,
      'total': total ?? rows.length,
      'last_page':
          lastPage ?? (((total ?? rows.length) + 19) ~/ 20).clamp(1, 10000),
    },
  },
};
Map<String, dynamic> historyEnvelope(
  Map<String, dynamic> thread,
  List<Map<String, dynamic>> rows, {
  int page = 1,
  int? total,
}) => {
  'data': {
    'thread': thread,
    'items': rows,
    'pagination': {
      'page': page,
      'per_page': 20,
      'total': total ?? rows.length,
      'last_page': ((total ?? rows.length) + 19) ~/ 20 == 0
          ? 1
          : ((total ?? rows.length) + 19) ~/ 20,
    },
  },
};
Map<String, dynamic> messageCommandEnvelope(
  CommandIntent intent, {
  Map<String, dynamic>? result,
  bool expired = false,
}) => {
  'data': {
    'idempotency_key': intent.key,
    'action': intent.action,
    'resource': intent.resource,
    'state': 'committed',
    'result':
        result ??
        (intent.action == 'message.send'
            ? parcelMessageJson(
                id: '61',
                fromRider: true,
                text: intent.body['text'] as String,
              )
            : {'through_message_id': intent.body['through_message_id']}),
    'recorded_at': '2026-10-18T03:00:00.000Z',
    'expires_at': '2026-10-25T03:00:00.000Z',
    'retry_expired': expired,
    'replayed': false,
  },
};

class MessagesHarness {
  MessagesHarness({this.enabled = true, ops.Session? session})
    : api = session ?? ops.Session() {
    api.respond = respond;
    operations = OperationsRepository(
      api,
      accountId: '5',
      journal: ops.Journal(),
      writesVerified: false,
      isCurrent: () => current,
    );
    repository = OperationsMessagesRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: enabled,
      isCurrent: () => current,
      readHome: operations.home,
      avatarOrigin: Uri.parse('https://example.test/api/v1'),
      now: () => now,
    );
    controller = MessagesController(
      repository,
      onSessionEnd: (message) async {
        ended.add(message);
      },
    );
  }
  final bool enabled;
  final ops.Session api;
  final journal = ops.Journal();
  bool current = true, available = true, canSend = true;
  DateTime now = DateTime.utc(2026, 10, 18, 3);
  final ended = <String>[];
  late final OperationsRepository operations;
  late final OperationsMessagesRepository repository;
  late final MessagesController controller;
  final surface = Object();
  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (path == 'rider/home') {
      final home = ops.fixture('home');
      home['data']['account_id'] = '5';
      home['data']['capabilities']['messages'] = available;
      return home;
    }
    if (path.startsWith('rider/conversations?')) {
      return conversationEnvelope([
        parcelConversationJson(canSend: canSend, last: parcelMessageJson()),
        parcelConversationJson(
          id: deliveryThread,
          last: parcelMessageJson(id: '52', sender: '4'),
        ),
      ]);
    }
    if (path.contains('/messages?')) {
      final id = path.split('/')[2];
      return historyEnvelope(parcelConversationJson(id: id, canSend: canSend), [
        parcelMessageJson(sender: id == pickupThread ? '3' : '4'),
      ]);
    }
    if (method == 'POST' || path.startsWith('rider/commands/')) {
      return messageCommandEnvelope(journal.value!);
    }
    throw StateError('Unexpected test request $path');
  }

  Future<void> boot({bool select = true}) async {
    controller.setSurfaceActive(surface, true);
    await Future<void>.delayed(Duration.zero);
    if (select) await controller.selectConversation(pickupThread);
  }

  ParcelConversation get thread =>
      ParcelConversation.fromJson(parcelConversationJson());
  Future<MessageCommandResult> send([String text = 'I am at the shop.']) =>
      repository.send(thread, text, mayDispatch: () => true);
  void dispose() => controller.dispose();
}
