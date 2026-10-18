import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/commands/protected_proof_store.dart';
import '../../../core/commands/parcel_proof.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/command_journal.dart';
import '../../home/data/operations_models.dart';
import '../../home/data/operations_repository.dart';
import '../../parcels/data/parcel_photo_service.dart';
import '../../messages/data/messages_repository.dart';
import '../../messages/presentation/messages_controller.dart';
import '../../trips/data/trip_models.dart';
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
    bool isCurrent() =>
        alive &&
        ref.read(authControllerProvider).user?.id == account.id &&
        ref.read(authControllerProvider).user?.approved == true;
    final proofs = ProtectedParcelProofStore(
      origin: config.origin,
      accountId: account.id!,
    );
    final photos = ParcelPhotoService(
      origin: config.origin,
      accountId: account.id!,
      proofs: proofs,
      isCurrent: isCurrent,
    );
    ref.onDispose(photos.dispose);
    return OperationsRepository(
      repository as RiderSessionApi,
      accountId: account.id!,
      journal: SecureCommandJournal(
        origin: config.origin,
        accountId: account.id!,
      ),
      writesVerified: config.operationsWritesVerified,
      parcelWritesVerified: config.parcelWritesVerified,
      proofStore: proofs,
      photos: photos,
      isCurrent: isCurrent,
    );
  },
  dependencies: [
    authControllerProvider,
    authRepositoryProvider,
    appConfigProvider,
  ],
);

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final repository = ref.watch(workspaceRepositoryProvider);
  if (repository is MessagesRepository) return repository as MessagesRepository;
  if (repository is! OperationsRepository) {
    return const UnavailableMessagesRepository();
  }
  final config = ref.watch(appConfigProvider);
  return OperationsMessagesRepository(
    repository.api,
    accountId: repository.accountId,
    journal: SecureCommandJournal(
      origin: config.origin,
      accountId: repository.accountId,
      scope: 'messages',
    ),
    writesVerified: config.messagesWritesVerified,
    isCurrent: repository.isCurrent,
    readHome: repository.home,
    avatarOrigin: config.origin,
  );
}, dependencies: [workspaceRepositoryProvider, appConfigProvider]);

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
    .family<WorkspaceController, WorkspaceIdentity>(
      (ref, identity) {
        final controller = WorkspaceController(
          ref.watch(workspaceRepositoryProvider),
          messagesRepository: ref.watch(messagesRepositoryProvider),
          onSessionEnd: identity.preview
              ? null
              : (notice) => ref
                    .read(authControllerProvider.notifier)
                    .discardSession(notice),
        );
        ref.onDispose(controller.dispose);
        return controller;
      },
      dependencies: [
        workspaceRepositoryProvider,
        messagesRepositoryProvider,
        authControllerProvider,
      ],
    );

enum _WorkRead { home, tasks, detail, more, trips }

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(
    this.repository, {
    this.onSessionEnd,
    MessagesRepository? messagesRepository,
  }) {
    messages = MessagesController(
      messagesRepository ??
          (repository is MessagesRepository
              ? repository as MessagesRepository
              : const UnavailableMessagesRepository()),
      onSessionEnd: (notice) async {
        await _workError(AccountFailure(notice, status: 401));
      },
    );
    messages.addListener(_changed);
    if (operations?.photos != null) unawaited(operations!.photos!.restore());
    unawaited(operations == null ? refreshAll() : Future.microtask(refreshAll));
  }
  final WorkspaceRepository repository;
  late final MessagesController messages;
  final Future<void> Function(String notice)? onSessionEnd;
  OperationsRepository? get operations => repository is OperationsRepository
      ? repository as OperationsRepository
      : null;
  FeatureData<OperationsHome> homeData = const FeatureData.loading();
  CommandIntent? pendingIntent;
  String? reconciledWorkKey;
  Map<String, dynamic>? reconciledWorkResult;
  final _readFailures = <_WorkRead, AccountFailure>{};
  AccountFailure? _commandFailure;
  AccountFailure? get workFailure =>
      _commandFailure ?? _readFailures.values.lastOrNull;
  AccountFailure? get loadMoreFailure => _readFailures[_WorkRead.more];
  String? workNotice;
  bool working = false, loadingMore = false;
  OperationTask? selectedTask;
  String? unavailableTaskId;
  final _unavailableTasks = <String>{};
  bool isTaskUnavailable(String id) => _unavailableTasks.contains(id);
  bool workAccessUnavailable = false;
  bool _sessionEnded = false;
  bool selectingTask = false;
  int _detailGeneration = 0, _homeGeneration = 0, _moreGeneration = 0;
  TaskPage? taskPage;
  Timer? _poll, _cooldownTimer;
  bool _foreground = true, _refreshingAll = false;
  DateTime? _cooldownUntil;
  bool get coolingDown => _cooldownUntil?.isAfter(DateTime.now()) ?? false;
  bool get canRefresh =>
      !_disposed &&
      !_sessionEnded &&
      !_refreshingAll &&
      !working &&
      !coolingDown;
  bool get canWrite =>
      !_disposed &&
      !_sessionEnded &&
      operations?.writesVerified == true &&
      !working &&
      !coolingDown &&
      pendingIntent == null &&
      homeData.status == FeatureStatus.ready;

  bool get canWriteParcel =>
      !_disposed &&
      !_sessionEnded &&
      operations?.parcelWritesVerified == true &&
      !working &&
      !coolingDown &&
      pendingIntent == null &&
      homeData.status == FeatureStatus.ready &&
      homeData.data?.capabilities['parcel_actions'] == true;

  bool get hasWorkAccess =>
      !_disposed && !_sessionEnded && !workAccessUnavailable;

  bool get canReadTrips =>
      !_disposed &&
      !_sessionEnded &&
      (operations == null || homeData.data?.capabilities['trips'] == true);

  bool canUseSelectedStop(String id) =>
      hasWorkAccess &&
      _foreground &&
      !selectingTask &&
      !coolingDown &&
      homeData.status == FeatureStatus.ready &&
      selectedTask?.id == id &&
      selectedTask?.preview == false &&
      !isTaskUnavailable(id) &&
      !_readFailures.containsKey(_WorkRead.detail);

  void setForeground(bool value) {
    messages.setForeground(value);
    if (_foreground == value) return;
    _foreground = value;
    _poll?.cancel();
    if (!value) {
      _tripSearchTimer?.cancel();
      _tripGeneration++;
      loadingTrips = false;
      if (tripData.status == FeatureStatus.refreshing) {
        tripData = FeatureData.ready(tripData.data!);
      }
      _changed();
    }
    if (value) unawaited(refreshAll());
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!_foreground ||
        _disposed ||
        _sessionEnded ||
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

  Future<AccountFailure> _workError(Object error, {_WorkRead? read}) async {
    final failure = error is AccountFailure
        ? error
        : const AccountFailure(
            'Could not verify work data. Refresh and try again.',
          );
    if (read == null) {
      _commandFailure = failure;
    } else {
      _readFailures.remove(read);
      _readFailures[read] = failure;
    }
    if (failure.retryAfterSeconds != null) {
      _cooldownTimer?.cancel();
      _cooldownUntil = DateTime.now().add(
        Duration(seconds: failure.retryAfterSeconds!),
      );
      _cooldownTimer = Timer(Duration(seconds: failure.retryAfterSeconds!), () {
        _cooldownUntil = null;
        _changed();
      });
    }
    if (failure.invalidSession) {
      _readFailures.clear();
      _commandFailure = failure;
      _sessionEnded = true;
      workAccessUnavailable = true;
      homeData = FeatureData.unavailable(failure.message);
      taskData = FeatureData.unavailable(failure.message);
      tripData = FeatureData.unavailable(failure.message);
      retainedTrips = null;
      loadingTrips = false;
      _tripSearchTimer?.cancel();
      messages.revoke(failure.message);
      selectedTask = null;
      pendingIntent = null;
      reconciledWorkKey = null;
      reconciledWorkResult = null;
      taskPage = null;
      selectingTask = loadingMore = false;
      _homeGeneration++;
      _detailGeneration++;
      _taskGeneration++;
      _tripGeneration++;
      _moreGeneration++;
      _poll?.cancel();
      _cooldownTimer?.cancel();
      // Deliver access loss before awaiting session cleanup or a widget rebuild.
      _changed();
      if (!_disposed) await onSessionEnd?.call(failure.message);
    }
    return failure;
  }

  Future<void> refreshHome() async {
    if (_disposed || _sessionEnded || coolingDown) return;
    final ops = operations;
    if (ops == null) {
      homeData = const FeatureData.unavailable(
        'Work availability not connected',
      );
      return;
    }
    final generation = ++_homeGeneration;
    final previous = homeData.data;
    homeData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final result = await ops.home();
      if (_disposed || generation != _homeGeneration) return;
      if (result.capabilities['messages'] != true) {
        messages.capabilityUnavailable();
      }
      _readFailures.remove(_WorkRead.home);
      if (result.capabilities['home'] != true) {
        workAccessUnavailable = true;
        homeData = const FeatureData.unavailable(
          'Home work data is unavailable.',
        );
        taskData = const FeatureData.unavailable(
          'Home work data is unavailable.',
        );
        selectedTask = null;
        selectingTask = loadingMore = false;
        taskPage = null;
        _detailGeneration++;
        _taskGeneration++;
        _moreGeneration++;
        _changed();
        return;
      }
      workAccessUnavailable = false;
      homeData = FeatureData.ready(result);
      if (!_queueChosenByRider && !_initialQueueChosen) {
        _initialQueueChosen = true;
        queue = (result.counts['final_mile'] ?? 0) > 0
            ? TaskQueue.delivery
            : (result.counts['pickup'] ?? 0) > 0
            ? TaskQueue.pickups
            : TaskQueue.available;
      }
      // A successful read is independent of an uncertain saved command.
      try {
        final pending = await ops.pending();
        if (_disposed || generation != _homeGeneration) return;
        pendingIntent = pending;
        if (pending != null && !working) {
          final committed = await ops.reconcile();
          if (_disposed || generation != _homeGeneration) return;
          pendingIntent = await ops.pending();
          if (_disposed || generation != _homeGeneration) return;
          if (committed != null) {
            reconciledWorkKey = pending.key;
            reconciledWorkResult = committed;
            _commandFailure = null;
            workNotice = 'Work request confirmed.';
          }
        }
      } catch (error) {
        if (!_disposed && generation == _homeGeneration) {
          await _workError(error);
        }
      }
    } catch (error) {
      if (_disposed || generation != _homeGeneration) return;
      final failure = await _workError(error, read: _WorkRead.home);
      if (!_disposed && !_sessionEnded && generation == _homeGeneration) {
        homeData = FeatureData.failed(failure.message, previous);
      }
    }
    _changed();
  }

  Future<void> openTask(RiderTask task) async {
    if (_disposed || _sessionEnded) return;
    final generation = ++_detailGeneration;
    selectedTask = null;
    selectingTask = true;
    _changed();
    try {
      final result = task.operation?.preview == true
          ? task.operation
          : await operations?.detail(task.id);
      if (!_disposed && generation == _detailGeneration) {
        selectedTask = result;
        _readFailures.remove(_WorkRead.detail);
        _unavailableTasks.remove(task.id);
        if (unavailableTaskId == task.id) unavailableTaskId = null;
      }
    } catch (error) {
      if (!_disposed && generation == _detailGeneration) {
        if (error is AccountFailure && error.status == 404) {
          _invalidateTask(task.id);
        }
        await _workError(error, read: _WorkRead.detail);
        _changed();
      }
    }
    if (!_disposed && generation == _detailGeneration) {
      selectingTask = false;
      _changed();
    }
  }

  /// Keeps the displayed stop while checking it, but blocks its actions until
  /// this read succeeds. A newer selection or session loss cancels the result.
  Future<OperationTask?> revalidateSelectedStop(String id) async {
    if (_disposed ||
        _sessionEnded ||
        !_foreground ||
        coolingDown ||
        selectingTask ||
        selectedTask?.id != id ||
        selectedTask?.preview != false ||
        operations == null) {
      return null;
    }
    final generation = ++_detailGeneration;
    selectingTask = true;
    _changed();
    try {
      final task = await operations!.detail(id);
      if (_disposed || generation != _detailGeneration) return null;
      selectedTask = task;
      _readFailures.remove(_WorkRead.detail);
      _unavailableTasks.remove(id);
      if (unavailableTaskId == id) unavailableTaskId = null;
    } catch (error) {
      if (!_disposed && generation == _detailGeneration) {
        if (error is AccountFailure && error.status == 404) {
          _invalidateTask(id);
        }
        await _workError(error, read: _WorkRead.detail);
      }
    } finally {
      if (!_disposed && generation == _detailGeneration) {
        selectingTask = false;
        _changed();
      }
    }
    return canUseSelectedStop(id) ? selectedTask : null;
  }

  void _invalidateTask(String id) {
    unavailableTaskId = id;
    _unavailableTasks.add(id);
    selectedTask = null;
    selectingTask = loadingMore = false;
    _detailGeneration++;
    _taskGeneration++;
    _homeGeneration++;
    _moreGeneration++;
    taskData = FeatureData.failed(
      'This task is no longer available. Refresh the queue.',
      taskData.data?.where((t) => t.id != id).toList(),
    );
    if (homeData.data != null) {
      homeData = FeatureData.failed(
        'Refresh work availability.',
        homeData.data,
      );
    }
    _changed();
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
  Future<Map<String, dynamic>?> performParcel(
    ParcelAction action,
    OperationTask reviewed, {
    required String barcode,
    Map<String, dynamic> fields = const {},
    ParcelProof? proof,
  }) async {
    Map<String, dynamic>? committed;
    await _command(() async {
      committed = await operations!.parcel(
        action,
        reviewed,
        barcode: barcode,
        fields: fields,
        proof: proof,
      );
      return committed;
    }, parcel: true);
    return committed;
  }

  Future<void> checkPending({bool retryUnknown = false}) => _command(
    () => operations!.reconcile(retryUnknown: retryUnknown),
    recovery: true,
  );
  Future<void> _command(
    Future<Map<String, dynamic>?> Function() request, {
    bool recovery = false,
    bool parcel = false,
  }) async {
    if (_disposed ||
        _sessionEnded ||
        operations == null ||
        working ||
        coolingDown ||
        (!recovery && !(parcel ? canWriteParcel : canWrite))) {
      return;
    }
    working = true;
    _commandFailure = null;
    workNotice = null;
    final reviewedSelection = _detailGeneration;
    final originalRecovery = recovery ? pendingIntent : null;
    _changed();
    try {
      final result = await request();
      if (_disposed) return;
      if (result == null) {
        workNotice =
            'No committed result is visible yet. The original request is kept.';
      } else {
        if (originalRecovery != null) {
          reconciledWorkKey = originalRecovery.key;
          reconciledWorkResult = result;
        }
        workNotice = switch (result['operational_stage']) {
          'picked_up' =>
            'Collection recorded. Bring the parcel to its origin hub.',
          'out_for_delivery' =>
            'Departure recorded. Follow the current buyer stop.',
          'delivered' =>
            'Delivery recorded. The buyer confirms receipt separately.',
          'delivery_failed' =>
            'Attempt recorded. Return the parcel to its destination hub.',
          _ => 'Work request confirmed.',
        };
        if (result['task_id'] is String) {
          if (result['operational_stage'] == 'delivered') {
            final id = result['task_id'] as String;
            _unavailableTasks.add(id);
            taskData = FeatureData.ready(
              taskData.data?.where((task) => task.id != id).toList() ?? [],
            );
            _taskGeneration++;
            if (selectedTask?.id == id) closeTask();
            queue = TaskQueue.delivery;
          } else if (_detailGeneration == reviewedSelection) {
            final generation = ++_detailGeneration;
            try {
              final owned = await operations!.detail(result['task_id']);
              if (!_disposed && generation == _detailGeneration) {
                selectedTask = owned;
                selectingTask = false;
                _readFailures.remove(_WorkRead.detail);
                _unavailableTasks.remove(owned.id);
                if (unavailableTaskId == owned.id) unavailableTaskId = null;
                queue = owned.phase == 'pickup'
                    ? TaskQueue.pickups
                    : TaskQueue.delivery;
              }
            } catch (error) {
              if (!_disposed && generation == _detailGeneration) {
                if (error is AccountFailure && error.status == 404) {
                  _invalidateTask(result['task_id']);
                }
                await _workError(error, read: _WorkRead.detail);
              }
            }
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

  bool get workFailureIsDenied => _sessionEnded;

  Future<void> loadMoreTasks() async {
    if (_disposed ||
        _sessionEnded ||
        loadingMore ||
        operations == null ||
        taskPage?.hasNext != true ||
        coolingDown ||
        taskData.status != FeatureStatus.ready) {
      return;
    }
    final generation = _taskGeneration;
    final moreGeneration = ++_moreGeneration;
    final requestedQueue = queue;
    loadingMore = true;
    _changed();
    try {
      final result = await operations!.taskPage(
        requestedQueue,
        page: taskPage!.page + 1,
      );
      if (!_disposed && generation == _taskGeneration) {
        final merged = {for (final t in taskData.data!) t.id: t};
        for (final t in result.items) {
          merged[t.id] = OperationsRepository.asRiderTask(t);
        }
        taskData = FeatureData.ready(merged.values.toList());
        taskPage = result;
        _readFailures.remove(_WorkRead.more);
      }
    } catch (error) {
      if (!_disposed && generation == _taskGeneration) {
        await _workError(error, read: _WorkRead.more);
      }
    }
    if (!_disposed && moreGeneration == _moreGeneration) {
      loadingMore = false;
      _changed();
    }
  }

  FeatureData<List<RiderTask>> taskData = const FeatureData.loading();
  FeatureData<List<RiderTrip>> tripData = const FeatureData.loading();
  TaskQueue queue = TaskQueue.available;
  bool _queueChosenByRider = false, _initialQueueChosen = false;
  String taskSearch = '', tripSearch = '';
  PaymentFilter payment = PaymentFilter.all;
  DateTime? fromDate, toDate;
  int tripPage = 0;
  RetainedTripPage? retainedTrips;
  String? tripPhase;
  bool loadingTrips = false;
  Timer? _tripSearchTimer;
  static const pageSize = 10;
  bool _disposed = false;
  int _taskGeneration = 0, _tripGeneration = 0;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_disposed ||
        _sessionEnded ||
        _refreshingAll ||
        working ||
        coolingDown) {
      return;
    }
    _refreshingAll = true;
    try {
      if (operations == null) {
        homeData = const FeatureData.unavailable(
          'Work availability not connected',
        );
        await Future.wait([refreshTasks(), refreshTrips(), messages.refresh()]);
        return;
      }
      await refreshHome();
      if (_disposed || _sessionEnded) return;
      if (operations == null || homeData.status == FeatureStatus.ready) {
        await refreshTasks();
      }
      await Future.wait([
        refreshTrips(),
        if (homeData.status == FeatureStatus.ready)
          messages.refresh(
            available: homeData.data!.capabilities['messages'] == true,
          ),
      ]);
    } finally {
      _refreshingAll = false;
      _schedulePoll();
      _changed();
    }
  }

  Future<void> refreshTasks() async {
    if (_disposed ||
        _sessionEnded ||
        coolingDown ||
        (operations != null && homeData.status != FeatureStatus.ready)) {
      return;
    }
    final generation = ++_taskGeneration;
    _moreGeneration++;
    loadingMore = false;
    final requestedQueue = queue;
    final previous = taskData.data;
    taskData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final ops = operations;
      TaskPage? page;
      final FeatureData<List<RiderTask>> result;
      if (ops != null) {
        page = await ops.taskPage(requestedQueue);
        result = FeatureData.ready(
          page.items.map(OperationsRepository.asRiderTask).toList(),
        );
      } else {
        result = await repository.tasks(requestedQueue);
      }
      if (!_disposed && generation == _taskGeneration) {
        taskData = result;
        taskPage = page;
        if (result.status == FeatureStatus.ready) {
          _readFailures.remove(_WorkRead.tasks);
          _readFailures.remove(_WorkRead.more);
          if (selectedTask == null) _readFailures.remove(_WorkRead.detail);
          for (final task in result.data!) {
            _unavailableTasks.remove(task.id);
            if (unavailableTaskId == task.id) unavailableTaskId = null;
          }
        }
        final selected = selectedTask;
        if (selected != null && selected.preview) {
          final matches =
              result.data?.where((t) => t.id == selected.id).toList() ?? [];
          if (matches.isEmpty) {
            closeTask();
          } else {
            selectedTask = matches.first.operation;
          }
        } else if (selected != null && operations != null && !selectingTask) {
          final detailGeneration = _detailGeneration;
          try {
            final detail = await operations!.detail(selected.id);
            if (!_disposed &&
                generation == _taskGeneration &&
                detailGeneration == _detailGeneration) {
              selectedTask = detail;
              _readFailures.remove(_WorkRead.detail);
            }
          } catch (error) {
            if (!_disposed &&
                generation == _taskGeneration &&
                detailGeneration == _detailGeneration) {
              if (error is AccountFailure && error.status == 404) {
                _invalidateTask(selected.id);
              }
              final failure = await _workError(error, read: _WorkRead.detail);
              final hidden = error is AccountFailure && error.status == 404;
              if (!_disposed &&
                  !_sessionEnded &&
                  generation == _taskGeneration &&
                  detailGeneration == _detailGeneration &&
                  !hidden) {
                taskData = FeatureData.failed(failure.message, taskData.data);
              }
            }
          }
        }
        _changed();
      }
    } catch (error) {
      if (!_disposed && generation == _taskGeneration) {
        final failure = operations == null
            ? null
            : await _workError(error, read: _WorkRead.tasks);
        if (_disposed || workFailureIsDenied || generation != _taskGeneration) {
          return;
        }
        taskData = FeatureData.failed(
          failure?.message ?? 'Could not load tasks. Try again.',
          previous,
        );
        _changed();
      }
    }
  }

  Future<void> refreshTrips({int page = 1, bool append = false}) async {
    if (_disposed || _sessionEnded || coolingDown || !_foreground) return;
    _tripSearchTimer?.cancel();
    final ops = operations;
    if (ops != null && homeData.data?.capabilities['trips'] != true) {
      _tripGeneration++;
      tripData = const FeatureData.unavailable(
        'Recorded Trips are unavailable for this account.',
      );
      retainedTrips = null;
      loadingTrips = false;
      _changed();
      return;
    }
    final generation = ++_tripGeneration;
    final previous = tripData.data;
    loadingTrips = true;
    tripData = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      RetainedTripPage? response;
      FeatureData<List<RiderTrip>> result;
      if (ops != null) {
        response = await ops.tripPage(
          page: page,
          filters: TripFilters(
            search: tripSearch,
            phase: tripPhase,
            payment: payment.name,
            from: fromDate,
            to: toDate,
          ),
        );
        final unique = <String, RiderTrip>{
          if (append && previous != null)
            for (final trip in previous) trip.id: trip,
          for (final trip in response.items)
            trip.id: OperationsRepository.asRiderTrip(trip),
        };
        result = FeatureData.ready(List.unmodifiable(unique.values));
      } else {
        result = await repository.trips();
      }
      if (!_disposed && generation == _tripGeneration) {
        tripData = result;
        if (response != null) {
          retainedTrips = response;
          tripPage = response.page - 1;
          _readFailures.remove(_WorkRead.trips);
        } else if (tripPage * pageSize >= filteredTrips.length) {
          tripPage = 0;
        }
        _changed();
      }
    } catch (error) {
      if (!_disposed && generation == _tripGeneration) {
        final failure = ops == null
            ? null
            : await _workError(error, read: _WorkRead.trips);
        if (_disposed || _sessionEnded || generation != _tripGeneration) return;
        tripData = FeatureData.failed(
          failure?.message ?? 'Could not load trips. Try again.',
          previous,
        );
        _changed();
      }
    } finally {
      if (!_disposed && generation == _tripGeneration) {
        loadingTrips = false;
        _changed();
      }
    }
  }

  Future<void> reportTripFailure(AccountFailure failure) async {
    await _workError(failure, read: _WorkRead.trips);
    _changed();
  }

  void _tripQueryChanged({bool debounce = false}) {
    if (_disposed || _sessionEnded) return;
    if (operations == null) {
      _changed();
      return;
    }
    _tripSearchTimer?.cancel();
    _tripGeneration++;
    tripPage = 0;
    retainedTrips = null;
    loadingTrips = false;
    tripData = coolingDown
        ? const FeatureData.failed(
            'Wait for the request cooldown, then refresh Trips.',
          )
        : const FeatureData.loading();
    _changed();
    if (coolingDown) return;
    if (debounce) {
      _tripSearchTimer = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(refreshTrips()),
      );
    } else {
      unawaited(refreshTrips());
    }
  }

  void selectQueue(TaskQueue value) {
    if (_disposed || _sessionEnded) return;
    _queueChosenByRider = true;
    if (queue == value) return;
    queue = value;
    closeTask();
    _taskGeneration++;
    _moreGeneration++;
    loadingMore = false;
    _readFailures.remove(_WorkRead.tasks);
    _readFailures.remove(_WorkRead.more);
    _readFailures.remove(_WorkRead.detail);
    taskPage = null;
    taskSearch = '';
    taskData = const FeatureData.loading();
    _changed();
    unawaited(refreshTasks());
  }

  void searchTasks(String value) {
    taskSearch = value;
    _changed();
  }

  void searchTrips(String value) {
    tripSearch = value;
    tripPage = 0;
    _tripQueryChanged(debounce: true);
  }

  void filterPayment(PaymentFilter value) {
    payment = value;
    tripPage = 0;
    _tripQueryChanged();
  }

  void filterDates(DateTime? from, DateTime? to) {
    fromDate = from;
    toDate = to;
    tripPage = 0;
    _tripQueryChanged();
  }

  void filterTripPhase(String? value) {
    tripPhase = value;
    _tripQueryChanged();
  }

  void clearTripFilters() {
    tripSearch = '';
    payment = PaymentFilter.all;
    tripPhase = null;
    fromDate = null;
    toDate = null;
    tripPage = 0;
    _tripQueryChanged();
  }

  List<RiderTask> get visibleTasks => (taskData.data ?? [])
      .where(
        (t) => '${t.tracking} ${t.stop} ${t.address}'.toLowerCase().contains(
          taskSearch.trim().toLowerCase(),
        ),
      )
      .toList();
  List<RiderTrip> get filteredTrips => operations != null
      ? (tripData.data ?? [])
      : (tripData.data ?? []).where((t) {
          final day = manilaTime(t.recordedAt);
          final date = DateTime(day.year, day.month, day.day);
          return '${t.tracking} ${t.recipient} ${t.address}'
                  .toLowerCase()
                  .contains(tripSearch.trim().toLowerCase()) &&
              (payment == PaymentFilter.all || t.payment == payment) &&
              (fromDate == null || !date.isBefore(fromDate!)) &&
              (toDate == null || !date.isAfter(toDate!));
        }).toList();
  List<RiderTrip> get visibleTrips => operations != null
      ? filteredTrips
      : filteredTrips.skip(tripPage * pageSize).take(pageSize).toList();
  bool get hasNextTripPage => operations != null
      ? retainedTrips?.hasNext == true
      : (tripPage + 1) * pageSize < filteredTrips.length;
  void nextTripPage() {
    if (operations != null) {
      if (!loadingTrips && hasNextTripPage) {
        unawaited(refreshTrips(page: tripPage + 2, append: true));
      }
      return;
    }
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

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _cooldownTimer?.cancel();
    _tripSearchTimer?.cancel();
    _detailGeneration++;
    homeData = const FeatureData.loading();
    pendingIntent = null;
    selectedTask = null;
    unavailableTaskId = null;
    _unavailableTasks.clear();
    _readFailures.clear();
    _commandFailure = null;
    messages.removeListener(_changed);
    messages.dispose();
    taskData = const FeatureData.loading();
    tripData = const FeatureData.loading();
    retainedTrips = null;
    tripSearch = '';
    tripPhase = null;
    fromDate = toDate = null;
    loadingTrips = false;
    super.dispose();
  }
}
