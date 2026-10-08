import 'dart:async';

import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

RiderConversation thread({String phase = 'pickup', bool canSend = true}) =>
    RiderConversation(
      id: 'parcel-1',
      tracking: 'TEST-1',
      participant: 'Example participant',
      phase: phase,
      canSend: canSend,
      unreadCount: 2,
      messages: [
        RiderMessage(
          id: 'message-1',
          text: 'Test message',
          fromRider: false,
          recordedAt: DateTime.utc(2026, 10, 7),
        ),
      ],
    );

class ControlledRepository implements WorkspaceRepository {
  final List<Completer<FeatureData<List<RiderTask>>>> requests = [];
  List<RiderConversation> threads = [thread()];
  bool failConversations = false, failRead = false;
  Completer<RiderMessage>? pendingSend;
  final sends = <(String, String, String)>[];
  final reads = <(String, String, String)>[];
  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) {
    final pending = Completer<FeatureData<List<RiderTask>>>();
    requests.add(pending);
    return pending.future;
  }

  @override
  Future<FeatureData<List<RiderTrip>>> trips() async =>
      const FeatureData.ready([]);
  @override
  Future<FeatureData<List<RiderConversation>>> conversations() async {
    if (failConversations) throw StateError('Test outage');
    return FeatureData.ready(threads);
  }

  @override
  Future<RiderMessage> send(String id, String phase, String text) {
    sends.add((id, phase, text));
    pendingSend = Completer<RiderMessage>();
    return pendingSend!.future;
  }

  @override
  Future<void> acknowledge(
    String id,
    String phase,
    String latestMessageId,
  ) async {
    reads.add((id, phase, latestMessageId));
    if (failRead) throw StateError('Test read failure');
  }
}

Future<void> settleController() => Future<void>.delayed(Duration.zero);
void main() {
  test('missing operational contracts remain unavailable rather than empty success', () async {
    final controller = WorkspaceController(
      const UnavailableWorkspaceRepository(),
    );
    addTearDown(controller.dispose);
    await settleController();
    expect(controller.taskData.status, FeatureStatus.unavailable);
    expect(controller.tripData.status, FeatureStatus.unavailable);
    expect(controller.conversationData.status, FeatureStatus.unavailable);
    expect(await controller.sendDraft(), isFalse);
  });
  test('a late old queue response cannot overwrite a newly selected queue or disposed scope', () async {
    final repository = ControlledRepository();
    final controller = WorkspaceController(repository);
    controller.selectQueue(TaskQueue.delivery);
    const current = RiderTask(
      id: 'delivery',
      tracking: 'TEST-D',
      stage: 'Assigned',
      stop: 'Hub',
      address: 'Test street',
      nextStep: 'View assignment',
    );
    repository.requests[1].complete(const FeatureData.ready([current]));
    await settleController();
    repository.requests[0].complete(const FeatureData.ready([]));
    await settleController();
    expect(controller.visibleTasks.single.id, 'delivery');
    final reload = controller.refreshTasks();
    controller.dispose();
    repository.requests[2].complete(const FeatureData.ready([current]));
    await reload;
    expect(controller.taskData.data, isNull);
  });
  test('drafts survive a failed refresh but never cross a changed phase or read-only assignment', () async {
    final repository = ControlledRepository();
    final controller = WorkspaceController(repository);
    addTearDown(controller.dispose);
    await settleController();
    controller.selectConversation('parcel-1');
    controller.updateDraft('Private test draft');
    repository.failConversations = true;
    await controller.refreshConversations();
    expect(controller.draft, 'Private test draft');
    expect(controller.conversationData.status, FeatureStatus.failed);
    expect(await controller.sendDraft(), isFalse);
    expect(repository.sends, isEmpty);
    repository.failConversations = false;
    repository.threads = [thread(phase: 'final_mile')];
    await controller.refreshConversations();
    expect(controller.draft, isEmpty);
    controller.updateDraft('Delivery draft');
    repository.threads = [thread(phase: 'final_mile', canSend: false)];
    await controller.refreshConversations();
    expect(controller.draft, isEmpty);
    expect(await controller.sendDraft(), isFalse);
  });
  test('send is phase-bound, excludes duplicate taps and preserves unconfirmed drafts', () async {
    final repository = ControlledRepository();
    final controller = WorkspaceController(repository);
    addTearDown(controller.dispose);
    await settleController();
    controller.selectConversation('parcel-1');
    controller.updateDraft('A private test draft');
    final first = controller.sendDraft();
    expect(await controller.sendDraft(), isFalse);
    controller.selectConversation(null);
    expect(controller.selectedConversationId, 'parcel-1');
    expect(repository.sends, [('parcel-1', 'pickup', 'A private test draft')]);
    repository.pendingSend!.completeError(StateError('Test response lost'));
    expect(await first, isFalse);
    expect(controller.draft, 'A private test draft');
    expect(controller.sendError, isNotNull);
  });
  test(
    'read failures do not clear unread counts or alter another phase',
    () async {
      final repository = ControlledRepository()..failRead = true;
      final controller = WorkspaceController(repository);
      addTearDown(controller.dispose);
      await settleController();
      controller.selectConversation('parcel-1');
      await controller.acknowledgeVisibleConversation(
        'parcel-1',
        phase: 'pickup',
        throughMessageId: 'message-1',
      );
      expect(repository.reads.single, ('parcel-1', 'pickup', 'message-1'));
      expect(controller.selectedConversation!.unreadCount, 2);
      expect(controller.readError, isNotNull);
      repository.failRead = false;
      await controller.acknowledgeVisibleConversation(
        'parcel-1',
        phase: 'pickup',
        throughMessageId: 'message-1',
      );
      expect(controller.selectedConversation!.unreadCount, 0);
    },
  );
  test('an obsolete rendered message boundary cannot acknowledge newer data or another phase', () async {
    final repository = ControlledRepository();
    final controller = WorkspaceController(repository);
    addTearDown(controller.dispose);
    await settleController();
    controller.selectConversation('parcel-1');
    await controller.acknowledgeVisibleConversation(
      'parcel-1',
      phase: 'pickup',
      throughMessageId: 'message-old',
    );
    await controller.acknowledgeVisibleConversation(
      'parcel-1',
      phase: 'final_mile',
      throughMessageId: 'message-1',
    );
    expect(repository.reads, isEmpty);
    expect(controller.selectedConversation!.unreadCount, 2);
  });
  test(
    'disposing a session clears its draft and ignores a later send result',
    () async {
      final repository = ControlledRepository();
      final controller = WorkspaceController(repository);
      await settleController();
      controller.selectConversation('parcel-1');
      controller.updateDraft('Private draft');
      final operation = controller.sendDraft();
      controller.dispose();
      repository.pendingSend!.complete(
        RiderMessage(
          id: 'late',
          text: 'Private draft',
          fromRider: true,
          recordedAt: DateTime.utc(2026),
        ),
      );
      expect(await operation, isFalse);
      expect(controller.draft, isEmpty);
      expect(controller.conversationData.data, isNull);
    },
  );
  test(
    'money and Philippine calendar dates preserve exact displayed meaning',
    () {
      expect(pesos(100001), '₱1,000.01');
      expect(pesos(-1), '-₱0.01');
      expect(dayLabel(DateTime.utc(2026, 10, 7, 20)), 'Oct 8, 2026');
      expect(calendarDateLabel(DateTime(2026, 10, 7)), 'Oct 7, 2026');
    },
  );
}
