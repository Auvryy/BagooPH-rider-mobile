import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workspace_models.dart';
import '../data/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => const UnavailableWorkspaceRepository(),
  dependencies: const [],
);

class WorkspaceIdentity {
  const WorkspaceIdentity(this.accountId, {this.preview = false});
  final String accountId;
  final bool preview;
  @override
  bool operator ==(Object other) =>
      other is WorkspaceIdentity &&
      other.accountId == accountId &&
      other.preview == preview;
  @override
  int get hashCode => Object.hash(accountId, preview);
}

final workspaceControllerProvider = Provider.autoDispose
    .family<WorkspaceController, WorkspaceIdentity>((ref, identity) {
      final controller = WorkspaceController(
        ref.watch(workspaceRepositoryProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    }, dependencies: [workspaceRepositoryProvider]);

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this.repository) {
    unawaited(refreshAll());
  }
  final WorkspaceRepository repository;
  FeatureData<List<RiderTask>> taskData = const FeatureData.loading();
  FeatureData<List<RiderTrip>> tripData = const FeatureData.loading();
  FeatureData<List<RiderConversation>> conversationData =
      const FeatureData.loading();
  TaskQueue queue = TaskQueue.available;
  String taskSearch = '', tripSearch = '', conversationSearch = '';
  PaymentFilter payment = PaymentFilter.all;
  DateTime? fromDate, toDate;
  int tripPage = 0;
  static const pageSize = 10;
  String? selectedConversationId;
  final Map<String, String> _drafts = {};
  bool sending = false, acknowledging = false;
  String? sendError, readError;
  bool _disposed = false;
  int _taskGeneration = 0, _tripGeneration = 0, _conversationGeneration = 0;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshAll() async =>
      Future.wait([refreshTasks(), refreshTrips(), refreshConversations()]);
  Future<void> refreshTasks() async {
    final generation = ++_taskGeneration;
    final previous = taskData.data;
    taskData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final result = await repository.tasks(queue);
      if (!_disposed && generation == _taskGeneration) {
        taskData = result;
        _changed();
      }
    } catch (_) {
      if (!_disposed && generation == _taskGeneration) {
        taskData = FeatureData.failed(
          'Could not load tasks. Try again.',
          previous,
        );
        _changed();
      }
    }
  }

  Future<void> refreshTrips() async {
    final generation = ++_tripGeneration;
    final previous = tripData.data;
    tripData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final result = await repository.trips();
      if (!_disposed && generation == _tripGeneration) {
        tripData = result;
        if (tripPage * pageSize >= filteredTrips.length) tripPage = 0;
        _changed();
      }
    } catch (_) {
      if (!_disposed && generation == _tripGeneration) {
        tripData = FeatureData.failed(
          'Could not load trips. Try again.',
          previous,
        );
        _changed();
      }
    }
  }

  Future<void> refreshConversations() async {
    final generation = ++_conversationGeneration;
    final previous = conversationData.data;
    conversationData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final result = await repository.conversations();
      if (!_disposed && generation == _conversationGeneration) {
        conversationData = result;
        final ids = result.data?.map((c) => c.id).toSet() ?? <String>{};
        final draftScopes =
            result.data?.where((c) => c.canSend).map(_scope).toSet() ??
            <String>{};
        _drafts.removeWhere((scope, _) => !draftScopes.contains(scope));
        if (!ids.contains(selectedConversationId)) {
          selectedConversationId = null;
        }
        _changed();
      }
    } catch (_) {
      if (!_disposed && generation == _conversationGeneration) {
        conversationData = FeatureData.failed(
          'Could not load conversations. Your draft is kept for retry.',
          previous,
        );
        _changed();
      }
    }
  }

  void selectQueue(TaskQueue value) {
    if (queue == value) return;
    queue = value;
    taskSearch = '';
    taskData = const FeatureData.loading();
    unawaited(refreshTasks());
  }

  void searchTasks(String value) {
    taskSearch = value;
    _changed();
  }

  void searchTrips(String value) {
    tripSearch = value;
    tripPage = 0;
    _changed();
  }

  void filterPayment(PaymentFilter value) {
    payment = value;
    tripPage = 0;
    _changed();
  }

  void filterDates(DateTime? from, DateTime? to) {
    fromDate = from;
    toDate = to;
    tripPage = 0;
    _changed();
  }

  void searchConversations(String value) {
    conversationSearch = value;
    _changed();
  }

  List<RiderTask> get visibleTasks => (taskData.data ?? [])
      .where(
        (t) => '${t.tracking} ${t.stop} ${t.address}'.toLowerCase().contains(
          taskSearch.trim().toLowerCase(),
        ),
      )
      .toList();
  List<RiderTrip> get filteredTrips => (tripData.data ?? []).where((t) {
    final day = manilaTime(t.recordedAt);
    final date = DateTime(day.year, day.month, day.day);
    return '${t.tracking} ${t.recipient} ${t.address}'.toLowerCase().contains(
          tripSearch.trim().toLowerCase(),
        ) &&
        (payment == PaymentFilter.all || t.payment == payment) &&
        (fromDate == null || !date.isBefore(fromDate!)) &&
        (toDate == null || !date.isAfter(toDate!));
  }).toList();
  List<RiderTrip> get visibleTrips =>
      filteredTrips.skip(tripPage * pageSize).take(pageSize).toList();
  bool get hasNextTripPage => (tripPage + 1) * pageSize < filteredTrips.length;
  void nextTripPage() {
    if (hasNextTripPage) {
      tripPage++;
      _changed();
    }
  }

  void previousTripPage() {
    if (tripPage > 0) {
      tripPage--;
      _changed();
    }
  }

  List<RiderConversation> get visibleConversations =>
      (conversationData.data ?? [])
          .where(
            (c) => '${c.participant} ${c.tracking}'.toLowerCase().contains(
              conversationSearch.trim().toLowerCase(),
            ),
          )
          .toList();
  RiderConversation? get selectedConversation {
    for (final c in conversationData.data ?? <RiderConversation>[]) {
      if (c.id == selectedConversationId) return c;
    }
    return null;
  }

  String _scope(RiderConversation c) => '${c.id}:${c.phase}';
  String get draft => selectedConversation == null
      ? ''
      : _drafts[_scope(selectedConversation!)] ?? '';
  void updateDraft(String value) {
    final thread = selectedConversation;
    if (thread != null && thread.canSend) _drafts[_scope(thread)] = value;
    _changed();
  }

  void selectConversation(String? id) {
    if (sending) return;
    selectedConversationId = id;
    sendError = null;
    readError = null;
    _changed();
  }

  Future<void> acknowledgeVisibleConversation(
    String id, {
    required String phase,
    required String throughMessageId,
  }) async {
    final thread = selectedConversation;
    if (acknowledging ||
        thread?.id != id ||
        thread!.unreadCount == 0 ||
        thread.messages.isEmpty ||
        thread.phase != phase ||
        thread.messages.last.id != throughMessageId ||
        conversationData.status != FeatureStatus.ready) {
      return;
    }
    final generation = _conversationGeneration;
    final scope = _scope(thread);
    final latest = throughMessageId;
    acknowledging = true;
    readError = null;
    _changed();
    try {
      await repository.acknowledge(id, thread.phase, latest);
      if (!_disposed &&
          generation == _conversationGeneration &&
          selectedConversation != null &&
          selectedConversation!.messages.isNotEmpty &&
          selectedConversation!.messages.last.id == latest &&
          _scope(selectedConversation!) == scope) {
        conversationData = FeatureData.ready(
          List.unmodifiable(
            conversationData.data!.map(
              (c) => _scope(c) == scope ? c.read() : c,
            ),
          ),
        );
      }
    } catch (_) {
      if (!_disposed && selectedConversationId == id) {
        readError = 'Read status was not confirmed. Retry without resending.';
      }
    }
    if (!_disposed) {
      acknowledging = false;
      _changed();
    }
  }

  Future<bool> sendDraft() async {
    final thread = selectedConversation;
    final text = draft.trim();
    if (sending ||
        thread == null ||
        !thread.canSend ||
        conversationData.status != FeatureStatus.ready ||
        text.isEmpty ||
        text.length > 1000) {
      return false;
    }
    final scope = _scope(thread);
    sending = true;
    sendError = null;
    _changed();
    try {
      final message = await repository.send(thread.id, thread.phase, text);
      if (_disposed ||
          selectedConversation == null ||
          _scope(selectedConversation!) != scope ||
          !selectedConversation!.canSend) {
        return false;
      }
      conversationData = FeatureData.ready(
        List.unmodifiable(
          conversationData.data!.map(
            (c) => _scope(c) == scope ? c.withMessage(message) : c,
          ),
        ),
      );
      _drafts.remove(scope);
      return true;
    } catch (_) {
      if (!_disposed) sendError = 'Sending was not confirmed. Your draft is kept; check the conversation before retrying.';
      return false;
    } finally {
      if (!_disposed) {
        sending = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _drafts.clear();
    taskData = const FeatureData.loading();
    tripData = const FeatureData.loading();
    conversationData = const FeatureData.loading();
    super.dispose();
  }
}
