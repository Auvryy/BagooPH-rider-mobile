import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/command_journal.dart';
import '../../home/data/operations_models.dart';
import '../../home/data/operations_repository.dart';
import '../data/workspace_models.dart';
import '../data/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) {
    final account = ref.watch(
      authControllerProvider.select(
        (s) => (
          id: s.user?.id,
          approved: s.user?.approved,
          version: s.user?.operationsApiVersion,
        ),
      ),
    );
    final repository = ref.watch(authRepositoryProvider);
    final config = ref.watch(appConfigProvider);
    if (account.id == null ||
        account.approved != true ||
        account.version != 1 ||
        repository is! RiderSessionApi) {
      return const UnavailableWorkspaceRepository();
    }
    var alive = true;
    ref.onDispose(() => alive = false);
    return OperationsRepository(
      repository as RiderSessionApi,
      accountId: account.id!,
      journal: SecureCommandJournal(
        origin: config.origin,
        accountId: account.id!,
      ),
      writesVerified: config.operationsWritesVerified,
      isCurrent: () =>
          alive &&
          ref.read(authControllerProvider).user?.id == account.id &&
          ref.read(authControllerProvider).user?.approved == true,
    );
  },
  dependencies: [
    authControllerProvider,
    authRepositoryProvider,
    appConfigProvider,
  ],
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
        onSessionEnd: identity.preview
            ? null
            : (notice) => ref
                  .read(authControllerProvider.notifier)
                  .discardSession(notice),
      );
      ref.onDispose(controller.dispose);
      return controller;
    }, dependencies: [workspaceRepositoryProvider, authControllerProvider]);

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this.repository, {this.onSessionEnd}) {
    unawaited(operations == null ? refreshAll() : Future.microtask(refreshAll));
  }
  final WorkspaceRepository repository;
  final Future<void> Function(String notice)? onSessionEnd;
  OperationsRepository? get operations => repository is OperationsRepository
      ? repository as OperationsRepository
      : null;
  FeatureData<OperationsHome> homeData = const FeatureData.loading();
  CommandIntent? pendingIntent;
  AccountFailure? workFailure;
  String? workNotice;
  bool working = false, loadingMore = false;
  OperationTask? selectedTask;
  bool selectingTask = false;
  int _detailGeneration = 0;
  TaskPage? taskPage;
  Timer? _poll;
  bool _foreground = true, _refreshingAll = false;
  DateTime? _cooldownUntil;
  bool get coolingDown => _cooldownUntil?.isAfter(DateTime.now()) ?? false;
  bool get canWrite =>
      operations?.writesVerified == true &&
      !working &&
      !coolingDown &&
      pendingIntent == null &&
      homeData.status == FeatureStatus.ready;

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _poll?.cancel();
    if (value) unawaited(refreshAll());
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!_foreground ||
        _disposed ||
        operations == null ||
        homeData.data == null) {
      return;
    }
    final seconds = (homeData.data!.limits['poll_interval_seconds'] ?? 30)
        .clamp(30, 3600);
    _poll = Timer(Duration(seconds: seconds), () async {
      await refreshAll();
      _schedulePoll();
    });
  }

  Future<void> _workError(Object error) async {
    final failure = error is AccountFailure
        ? error
        : const AccountFailure(
            'Could not verify work data. Refresh and try again.',
          );
    workFailure = failure;
    if (failure.retryAfterSeconds != null) {
      _cooldownUntil = DateTime.now().add(
        Duration(seconds: failure.retryAfterSeconds!),
      );
    }
    if (failure.invalidSession) {
      homeData = FeatureData.unavailable(failure.message);
      taskData = FeatureData.unavailable(failure.message);
      selectedTask = null;
      _detailGeneration++;
      _taskGeneration++;
      _poll?.cancel();
      if (!_disposed) await onSessionEnd?.call(failure.message);
    }
  }

  Future<void> refreshHome() async {
    final ops = operations;
    if (ops == null) {
      homeData = const FeatureData.unavailable(
        'Work availability not connected',
      );
      return;
    }
    final previous = homeData.data;
    homeData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final result = await ops.home();
      if (_disposed) return;
      if (result.capabilities['home'] != true) {
        homeData = const FeatureData.unavailable(
          'Home work data is unavailable.',
        );
        taskData = const FeatureData.unavailable(
          'Home work data is unavailable.',
        );
        selectedTask = null;
        return;
      }
      homeData = FeatureData.ready(result);
      pendingIntent = await ops.pending();
      if (pendingIntent != null && !working) {
        await ops.reconcile();
        if (!_disposed) pendingIntent = await ops.pending();
      }
    } catch (error) {
      if (_disposed) return;
      await _workError(error);
      if (!_disposed && homeData.status != FeatureStatus.unavailable) {
        homeData = FeatureData.failed(workFailure!.message, previous);
      }
    }
    _changed();
  }

  Future<void> openTask(RiderTask task) async {
    final generation = ++_detailGeneration;
    selectedTask = null;
    selectingTask = true;
    _changed();
    try {
      final result = task.operation?.preview == true
          ? task.operation
          : await operations?.detail(task.id);
      if (!_disposed && generation == _detailGeneration) selectedTask = result;
    } catch (error) {
      if (!_disposed && generation == _detailGeneration) {
        await _workError(error);
      }
    }
    if (!_disposed && generation == _detailGeneration) {
      selectingTask = false;
      _changed();
    }
  }

  void closeTask() {
    _detailGeneration++;
    selectedTask = null;
    selectingTask = false;
    _changed();
  }

  Future<void> setDuty(bool desired) =>
      _command(() => operations!.duty(desired));
  Future<void> claimTask(OperationTask task) =>
      _command(() => operations!.claim(task));
  Future<void> checkPending({bool retryUnknown = false}) => _command(
    () => operations!.reconcile(retryUnknown: retryUnknown),
    recovery: true,
  );
  Future<void> _command(
    Future<Map<String, dynamic>?> Function() request, {
    bool recovery = false,
  }) async {
    if (_disposed ||
        operations == null ||
        working ||
        coolingDown ||
        (!recovery && !canWrite)) {
      return;
    }
    working = true;
    workFailure = null;
    workNotice = null;
    _changed();
    try {
      final result = await request();
      if (_disposed) return;
      if (result == null) {
        workNotice =
            'No committed result is visible yet. The original request is kept.';
      } else {
        workNotice = 'Work request confirmed.';
        if (result['task_id'] is String) {
          final owned = await operations!.detail(result['task_id']);
          if (!_disposed) {
            _detailGeneration++;
            selectedTask = owned;
            queue = TaskQueue.pickups;
          }
        }
      }
    } catch (error) {
      if (!_disposed) await _workError(error);
    } finally {
      if (!_disposed) {
        try {
          pendingIntent = await operations!.pending();
        } catch (error) {
          await _workError(error);
        }
        working = false;
        if (!_disposed && !coolingDown && !workFailureIsDenied) {
          await refreshAll();
        }
        _changed();
      }
    }
  }

  bool get workFailureIsDenied => workFailure?.invalidSession == true;

  Future<void> loadMoreTasks() async {
    if (_disposed ||
        loadingMore ||
        operations == null ||
        taskPage?.hasNext != true ||
        coolingDown ||
        taskData.status != FeatureStatus.ready) {
      return;
    }
    final generation = _taskGeneration;
    loadingMore = true;
    _changed();
    try {
      final result = await operations!.taskPage(
        queue,
        page: taskPage!.page + 1,
      );
      if (!_disposed && generation == _taskGeneration) {
        final merged = {for (final t in taskData.data!) t.id: t};
        for (final t in result.items) {
          merged[t.id] = OperationsRepository.asRiderTask(t);
        }
        taskData = FeatureData.ready(merged.values.toList());
        taskPage = result;
      }
    } catch (error) {
      if (!_disposed && generation == _taskGeneration) await _workError(error);
    }
    if (!_disposed) {
      loadingMore = false;
      _changed();
    }
  }

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

  Future<void> refreshAll() async {
    if (_disposed || _refreshingAll || working || coolingDown) return;
    _refreshingAll = true;
    try {
      if (operations == null) {
        homeData = const FeatureData.unavailable(
          'Work availability not connected',
        );
        await Future.wait([
          refreshTasks(),
          refreshTrips(),
          refreshConversations(),
        ]);
        return;
      }
      await refreshHome();
      if (_disposed) return;
      if (operations == null || homeData.status == FeatureStatus.ready) {
        await refreshTasks();
      }
      await Future.wait([refreshTrips(), refreshConversations()]);
    } finally {
      _refreshingAll = false;
      _schedulePoll();
    }
  }

  Future<void> refreshTasks() async {
    if (_disposed ||
        coolingDown ||
        (operations != null && homeData.status != FeatureStatus.ready)) {
      return;
    }
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
        taskPage = operations?.lastPage;
        if (selectedTask != null &&
            !(result.data?.any((t) => t.id == selectedTask!.id) ?? false)) {
          closeTask();
        }
        _changed();
      }
    } catch (error) {
      if (!_disposed && generation == _taskGeneration) {
        if (operations != null) await _workError(error);
        if (_disposed || workFailureIsDenied) return;
        taskData = FeatureData.failed(
          workFailure?.message ?? 'Could not load tasks. Try again.',
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
    closeTask();
    taskPage = null;
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
    _poll?.cancel();
    _detailGeneration++;
    homeData = const FeatureData.loading();
    pendingIntent = null;
    selectedTask = null;
    _drafts.clear();
    taskData = const FeatureData.loading();
    tripData = const FeatureData.loading();
    conversationData = const FeatureData.loading();
    super.dispose();
  }
}
