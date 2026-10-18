import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/account.dart';
import '../../../core/commands/command_intent.dart';
import '../../../core/network/rider_api_client.dart';
import '../../messages/data/message_models.dart';
import '../../messages/data/messages_repository.dart';
import '../../home/development/home_preview_data.dart';
import '../../settings/development/settings_preview_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/workspace_models.dart';
import '../data/workspace_repository.dart';
import '../presentation/workspace_controller.dart';
import '../presentation/workspace_shell.dart';

/// Test-only layout fixture; never routed by the main app.
class WorkspacePreviewPage extends StatelessWidget {
  const WorkspacePreviewPage({super.key});
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWith(
        (ref, identity) => identity.preview
            ? PreviewSettingsRepository(identity.accountId)
            : const UnavailableSettingsRepository(),
      ),
      workspaceRepositoryProvider.overrideWith(
        (ref) => PreviewWorkspaceRepository(),
      ),
    ],
    child: const RiderWorkspaceShell(
      account: RiderAccount(
        id: 'preview-rider',
        name: 'Demo Rider',
        email: 'rider@example.test',
        status: 'active',
        kycStatus: 'approved',
        approved: true,
        emailVerified: true,
      ),
      preview: true,
    ),
  );
}

class PreviewWorkspaceRepository
    implements WorkspaceRepository, MessagesRepository {
  int _messageNumber = 900;
  final Map<String, List<Map<String, dynamic>>> _messages = {
    'pickup-1-101-3': [
      {
        'id': '1',
        'sender_id': '3',
        'text': 'The parcel is ready at the shop counter.',
        'from_rider': false,
        'is_read': false,
        'recorded_at': '2026-10-07T02:12:00.000Z',
      },
      {
        'id': '2',
        'sender_id': '7',
        'text': 'Thank you. I will check the parcel when I arrive.',
        'from_rider': true,
        'is_read': true,
        'recorded_at': '2026-10-07T02:14:00.000Z',
      },
    ],
    'final_mile-2-102-4': [
      {
        'id': '3',
        'sender_id': '4',
        'text': 'Please use the entrance beside the garden.',
        'from_rider': false,
        'is_read': false,
        'recorded_at': '2026-10-07T03:20:00.000Z',
      },
    ],
    'final_mile-3-103-5': [
      {
        'id': '4',
        'sender_id': '5',
        'text': 'Thank you for the delivery.',
        'from_rider': false,
        'is_read': true,
        'recorded_at': '2026-10-06T04:00:00.000Z',
      },
    ],
  };
  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) async {
    final original = HomePreviewQueue.values[queue.index];
    return FeatureData.ready(
      List.unmodifiable(
        homePreviewTasks[original]!.map(
          (t) => RiderTask(
            id: t.tracking,
            tracking: t.tracking,
            stage: switch (queue) {
              TaskQueue.available => 'unassigned',
              TaskQueue.pickups => 'picked_up',
              TaskQueue.delivery => 'assigned_to_rider',
            },
            stop: t.stop,
            address: t.address,
            nextStep: t.nextStep,
            cashCentavos: queue == TaskQueue.delivery ? 78500 : null,
          ),
        ),
      ),
    );
  }

  @override
  Future<FeatureData<List<RiderTrip>>> trips() async => FeatureData.ready(
    List.unmodifiable(
      List.generate(14, (index) {
        final date = DateTime.utc(
          2026,
          10,
          7,
          7,
          30,
        ).subtract(Duration(days: index ~/ 3, hours: index % 3));
        return RiderTrip(
          id: 'preview-trip-$index',
          tracking: 'DEMO-T${3001 + index}',
          recipient: [
            'Sample recipient',
            'Example customer',
            'Demo buyer',
          ][index % 3],
          address: [
            'Market Street · Sample District',
            'Garden Road · Sample District',
          ][index % 2],
          outcome: index % 5 == 0 ? 'Delivery failed' : 'Delivered',
          recordedAt: date,
          payment: index.isEven ? PaymentFilter.cod : PaymentFilter.prepaid,
          cashCentavos: index.isEven ? 78500 + index * 1500 : null,
          checkpoints: [
            TripCheckpoint(
              'Assigned by destination hub',
              date.subtract(const Duration(hours: 2)),
            ),
            TripCheckpoint(
              'Departed destination hub',
              date.subtract(const Duration(hours: 1)),
            ),
            TripCheckpoint(
              index % 5 == 0 ? 'Delivery failed' : 'Delivered to buyer',
              date,
            ),
          ],
        );
      }),
    ),
  );
  @override
  bool get writesVerified => true;
  @override
  Uri? get avatarOrigin => null;
  @override
  Future<bool> available() async => true;
  Map<String, dynamic> _thread(String id) {
    final parts = id.split('-');
    final items = _messages[id]!;
    return {
      'id': id,
      'delivery_id': parts[1],
      'assignment_reference': 'CHK-PREVIEW-${parts[2]}',
      'phase': parts[0],
      'tracking_number': switch (id) {
        'pickup-1-101-3' => 'DEMO-P1003',
        'final_mile-2-102-4' => 'DEMO-D2001',
        _ => 'DEMO-D1999',
      },
      'participant': {
        'id': parts[3],
        'name': switch (id) {
          'pickup-1-101-3' => 'Example grocery',
          'final_mile-2-102-4' => 'Sample buyer',
          _ => 'Previous sample buyer',
        },
        'role': parts[0] == 'pickup' ? 'seller' : 'buyer',
        'avatar_url': null,
      },
      'can_send': id != 'final_mile-3-103-5',
      'send_denial': id == 'final_mile-3-103-5' ? 'PHASE_NOT_ACTIVE' : null,
      'unread_count': items
          .where((m) => m['from_rider'] == false && m['is_read'] == false)
          .length,
      'last_message': items.isEmpty ? null : items.last,
    };
  }

  @override
  Future<ConversationPage> conversations({
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async => ConversationPage.fromJson({
    'items': _messages.keys.map(_thread).toList(),
    'pagination': {'page': 1, 'per_page': 20, 'total': 3, 'last_page': 1},
  });
  @override
  Future<MessageHistoryPage> history(
    String id, {
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async => MessageHistoryPage.fromJson({
    'thread': _thread(id),
    'items': _messages[id]!.reversed.toList(),
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': _messages[id]!.length,
      'last_page': 1,
    },
  });
  @override
  Future<CommandIntent?> pending() async => null;
  MessageCommandResult _result(
    String action,
    String id,
    Map<String, dynamic> body,
    Map<String, dynamic> result,
  ) {
    final intent = CommandIntent(
      accountId: '7',
      key: commandUuid(),
      action: action,
      resource: id,
      body: body,
      createdAt: DateTime.utc(2026, 10, 18),
    );
    return MessageCommandResult.fromJson({
      'idempotency_key': intent.key,
      'action': action,
      'resource': id,
      'state': 'committed',
      'result': result,
      'recorded_at': '2026-10-18T00:00:00.000Z',
      'expires_at': '2026-10-25T00:00:00.000Z',
      'retry_expired': false,
      'replayed': false,
    }, intent);
  }

  @override
  Future<MessageCommandResult> send(
    ParcelConversation thread,
    String text, {
    required bool Function() mayDispatch,
  }) async {
    final message = <String, dynamic>{
      'id': '${++_messageNumber}',
      'sender_id': '7',
      'text': text,
      'from_rider': true,
      'is_read': false,
      'recorded_at': DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String(),
    };
    _messages[thread.id]!.add(message);
    return _result('message.send', thread.id, {'text': text}, message);
  }

  @override
  Future<MessageCommandResult> acknowledge(
    ParcelConversation thread,
    String throughMessageId, {
    required bool Function() mayDispatch,
  }) async {
    for (final message in _messages[thread.id]!) {
      if (message['from_rider'] == false &&
          BigInt.parse(message['id'] as String) <=
              BigInt.parse(throughMessageId)) {
        message['is_read'] = true;
      }
    }
    return _result(
      'message.read',
      thread.id,
      {'through_message_id': throughMessageId},
      {'through_message_id': throughMessageId},
    );
  }

  @override
  Future<MessageCommandResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async => null;
}
