import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart';
import '../../workspace/data/workspace_models.dart';
import '../data/notification_models.dart';
import '../data/notifications_repository.dart';

/// One account, one inbox. Workspace owns periodic refresh; surface leases
/// prevent hidden routes, background frames and late responses from reading.
class NotificationsController extends ChangeNotifier {
  NotificationsController(this.repository, {this.onSessionEnd}) {
    if (repository is UnavailableNotificationsRepository) {
      capabilityUnavailable();
    }
  }
  final NotificationsRepository repository;
  final Future<void> Function(String message)? onSessionEnd;
  FeatureData<List<RiderNotification>> inbox = const FeatureData.loading();
  NotificationPage? pagination;
  RiderNotification? selected;
  int? unreadCount;
  int revision = 0;
  bool loadingMore = false, working = false, resolving = false;
  CommandIntent? pendingIntent;
  bool pendingLoaded = false, commandUnknown = false;
  AccountFailure? failure;
  String? readError, targetError, moreError, notice;
  final _surfaces = <Object, bool>{};
  final _displayed = <Object, Set<String>>{};
  bool _foreground = true, _disposed = false, _accessLost = false;
  bool _refreshing = false, _verified = false;
  int _epoch = 0, _generation = 0;
  RiderReadCancellation? _listRead, _targetRead;
  DateTime? _cooldownUntil;
  Timer? _cooldown;
  static const maxLoaded = 200;

  bool get active =>
      !_disposed && !_accessLost && _foreground && _surfaces.isNotEmpty;
  bool get inboxActive => active && _surfaces.values.any((value) => value);
  bool get coolingDown => _cooldownUntil?.isAfter(DateTime.now()) ?? false;
  bool get canRefresh => active && !working && !_refreshing && !coolingDown;
  bool get canWrite =>
      inboxActive &&
      _verified &&
      !working &&
      !_refreshing &&
      !coolingDown &&
      repository.writesVerified &&
      pendingLoaded &&
      pendingIntent == null;
  bool get canRetryOriginal =>
      inboxActive &&
      _verified &&
      !working &&
      !coolingDown &&
      repository.writesVerified &&
      pendingIntent != null &&
      commandUnknown;
  bool get hasMore =>
      pagination?.hasMore == true && (inbox.data?.length ?? 0) < maxLoaded;
  Set<String> get displayedUnreadIds {
    final visible = _displayed.values.expand((ids) => ids).toSet();
    return {
      for (final item in inbox.data ?? <RiderNotification>[])
        if (item.unread && visible.contains(item.id)) item.id,
      if (selected?.unread == true && visible.contains(selected!.id))
        selected!.id,
    };
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int epoch) => active && epoch == _epoch;
  void _invalidate() {
    _epoch++;
    _generation++;
    _listRead?.cancel();
    _targetRead?.cancel();
    _displayed.clear();
    _refreshing = loadingMore = resolving = false;
    _verified = false;
    revision++;
  }

  void setSurfaceActive(Object owner, bool value, {bool inbox = false}) {
    if (_disposed) return;
    final wasActive = active;
    final wasInbox = inboxActive;
    if (value) {
      _surfaces[owner] = inbox;
    } else {
      _surfaces.remove(owner);
      _displayed.remove(owner);
    }
    if (wasActive != active || wasInbox != inboxActive) {
      _invalidate();
      if (active) unawaited(refresh());
    }
  }

  void setDisplayed(Object owner, Iterable<String> ids, int renderedRevision) {
    if (!inboxActive ||
        _surfaces[owner] != true ||
        renderedRevision != revision) {
      return;
    }
    final known = {
      for (final item in inbox.data ?? <RiderNotification>[]) item.id,
      if (selected != null) selected!.id,
    };
    _displayed[owner] = ids.where(known.contains).toSet();
  }

  void setForeground(bool value) {
    if (_disposed || _foreground == value) return;
    _foreground = value;
    _invalidate();
    if (!value) {
      _clearPrivate();
    } else if (active) {
      unawaited(refresh());
    }
    _changed();
  }

  void _clearPrivate() {
    inbox = const FeatureData.loading();
    pagination = null;
    unreadCount = null;
    selected = null;
    pendingIntent = null;
    pendingLoaded = commandUnknown = false;
    failure = null;
    readError = targetError = moreError = notice = null;
  }

  void revoke(String message) {
    if (_disposed) return;
    _accessLost = true;
    _invalidate();
    _clearPrivate();
    inbox = FeatureData.unavailable(message);
    _cooldown?.cancel();
    _changed();
  }

  void capabilityUnavailable() {
    if (_disposed) return;
    _invalidate();
    _clearPrivate();
    inbox = const FeatureData.unavailable(
      'Notifications are unavailable for this account. Refresh or sign in again after the service is enabled.',
    );
    _changed();
  }

  Future<void> _error(Object error) async {
    final problem = error is AccountFailure
        ? error
        : const AccountFailure(
            'Notifications could not be verified. Refresh and try again.',
          );
    failure = problem;
    if (problem.retryAfterSeconds != null) {
      _cooldown?.cancel();
      final delay = Duration(seconds: problem.retryAfterSeconds!);
      _cooldownUntil = DateTime.now().add(delay);
      _cooldown = Timer(delay, () {
        _cooldownUntil = null;
        _changed();
      });
    }
    if (problem.invalidSession) {
      revoke(problem.message);
      await onSessionEnd?.call(problem.message);
    } else if (problem.code == 'NOTIFICATIONS_UNAVAILABLE') {
      capabilityUnavailable();
    }
  }

  Future<void> reportTargetFailure(Object error) => _error(error);
  List<RiderNotification> _merge(
    Iterable<RiderNotification> rows, {
    bool append = false,
  }) {
    final known = {
      for (final item in inbox.data ?? <RiderNotification>[]) item.id: item,
    };
    final selectedNotice = selected;
    if (selectedNotice != null) {
      known[selectedNotice.id] = selectedNotice;
    }
    final next = <String, RiderNotification>{if (append) ...known};
    for (var item in rows) {
      final read = known[item.id]?.readAt;
      if (read != null && item.unread) item = item.read(read);
      next[item.id] = item;
      if (selected?.id == item.id) selected = item;
    }
    final sorted = next.values.toList()
      ..sort((a, b) {
        final date = b.recordedAt.compareTo(a.recordedAt);
        return date == 0 ? b.id.compareTo(a.id) : date;
      });
    return List.unmodifiable(sorted.take(maxLoaded));
  }

  Future<void> refresh({bool? available}) async {
    if (!canRefresh) return;
    final epoch = _epoch, generation = ++_generation;
    final cancellation = RiderReadCancellation();
    _listRead?.cancel();
    _listRead = cancellation;
    final previous = inbox.data;
    _refreshing = true;
    loadingMore = false;
    _verified = false;
    _displayed.clear();
    revision++;
    inbox = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _changed();
    try {
      final enabled = available ?? await repository.available();
      if (!_current(epoch) || generation != _generation) return;
      if (!enabled) {
        capabilityUnavailable();
        return;
      }
      final saved = await repository.pending();
      if (!_current(epoch) || generation != _generation) return;
      if (saved?.key != pendingIntent?.key) commandUnknown = false;
      pendingIntent = saved;
      pendingLoaded = true;
      if (saved != null) {
        final result = await repository.reconcile(mayDispatch: () => false);
        if (!_current(epoch) || generation != _generation) return;
        commandUnknown = result == null;
        if (result != null) {
          _apply(result);
          pendingIntent = null;
        }
      }
      final page = await repository.page(cancellation: cancellation);
      if (!_current(epoch) || generation != _generation) return;
      inbox = FeatureData.ready(_merge(page.items));
      pagination = page;
      unreadCount = page.unreadCount;
      _verified = true;
      failure = null;
      revision++;
    } catch (error) {
      if (_current(epoch) && generation == _generation) {
        await _error(error);
        if (_current(epoch) && generation == _generation) {
          inbox = FeatureData.failed(failure!.message, previous);
          unreadCount = null;
        }
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _refreshing = false;
        _changed();
      }
    }
  }

  Future<void> loadMore() async {
    if (!active ||
        working ||
        _refreshing ||
        loadingMore ||
        coolingDown ||
        !hasMore ||
        inbox.status != FeatureStatus.ready) {
      return;
    }
    final epoch = _epoch, generation = _generation;
    final cancellation = RiderReadCancellation();
    _listRead = cancellation;
    loadingMore = true;
    moreError = null;
    _changed();
    try {
      final page = await repository.page(
        page: pagination!.page + 1,
        cancellation: cancellation,
      );
      if (!_current(epoch) || generation != _generation) return;
      inbox = FeatureData.ready(_merge(page.items, append: true));
      pagination = page;
      unreadCount = page.unreadCount;
      failure = null;
      _displayed.clear();
      revision++;
    } catch (error) {
      if (_current(epoch) && generation == _generation) {
        await _error(error);
        if (_current(epoch)) moreError = failure?.message;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        _changed();
      }
    }
  }

  void select(RiderNotification? item) {
    if (!inboxActive || working) return;
    _targetRead?.cancel();
    resolving = false;
    targetError = null;
    selected = item;
    _displayed.clear();
    revision++;
    _changed();
  }

  void _apply(NotificationReadResult result) {
    final ids = result.ids.toSet();
    if (inbox.data != null) {
      inbox = FeatureData.ready(
        List.unmodifiable(
          inbox.data!.map(
            (item) =>
                ids.contains(item.id) ? item.read(result.recordedAt) : item,
          ),
        ),
      );
    }
    if (selected != null && ids.contains(selected!.id)) {
      selected = selected!.read(result.recordedAt);
    }
    unreadCount = null;
    _displayed.clear();
    revision++;
  }

  Future<void> _restorePending() async {
    if (!active) return;
    final epoch = _epoch;
    try {
      final saved = await repository.pending();
      if (!_current(epoch)) return;
      pendingIntent = saved;
      pendingLoaded = true;
    } catch (_) {
      if (_current(epoch)) pendingLoaded = false;
    }
  }

  Future<void> acknowledgeDisplayed(
    Iterable<String> ids,
    int renderedRevision,
  ) async {
    final exact = ids.toSet();
    if (!canWrite ||
        renderedRevision != revision ||
        exact.isEmpty ||
        exact.length > 50 ||
        !exact.every(displayedUnreadIds.contains)) {
      return;
    }
    final epoch = _epoch;
    _listRead?.cancel();
    _generation++;
    loadingMore = false;
    working = true;
    readError = notice = null;
    commandUnknown = false;
    _changed();
    var confirmed = false;
    try {
      final result = await repository.acknowledge(
        exact.toList(),
        mayDispatch: () => _current(epoch) && inboxActive && _verified,
      );
      if (!_current(epoch)) return;
      _apply(result);
      notice = 'Read status saved.';
      confirmed = true;
    } catch (error) {
      if (_current(epoch)) {
        await _error(error);
        readError = failure?.message;
      }
    } finally {
      if (!_disposed) {
        working = false;
        await _restorePending();
        _changed();
        if (confirmed && _current(epoch)) await refresh();
      }
    }
  }

  Future<void> reconcile({bool retryUnknown = false}) async {
    if (!inboxActive ||
        working ||
        coolingDown ||
        (retryUnknown && !canRetryOriginal)) {
      return;
    }
    final epoch = _epoch;
    working = true;
    readError = notice = null;
    _changed();
    var confirmed = false;
    try {
      final result = await repository.reconcile(
        retryUnknown: retryUnknown,
        mayDispatch: () => _current(epoch) && inboxActive && _verified,
      );
      if (!_current(epoch)) return;
      commandUnknown = result == null;
      if (result == null) {
        notice = 'No saved result is visible yet. This does not prove the read failed.';
      } else {
        _apply(result);
        notice = 'Original read request confirmed.';
        confirmed = true;
      }
    } catch (error) {
      if (_current(epoch)) {
        await _error(error);
        readError = failure?.message;
      }
    } finally {
      if (!_disposed) {
        working = false;
        await _restorePending();
        _changed();
        if (confirmed && _current(epoch)) await refresh();
      }
    }
  }

  Future<NotificationDestination?> resolveSelected() async {
    final item = selected, target = selected?.target;
    if (!inboxActive ||
        !_verified ||
        resolving ||
        working ||
        coolingDown ||
        item == null ||
        target == null) {
      return null;
    }
    final epoch = _epoch;
    final cancellation = RiderReadCancellation();
    _targetRead?.cancel();
    _targetRead = cancellation;
    resolving = true;
    targetError = null;
    _changed();
    try {
      final result = await repository.resolve(
        target,
        cancellation: cancellation,
      );
      if (!_current(epoch) ||
          selected?.id != item.id ||
          cancellation.cancelled) {
        return null;
      }
      return result;
    } catch (error) {
      if (_current(epoch) &&
          selected?.id == item.id &&
          !cancellation.cancelled) {
        await _error(error);
        if (_current(epoch)) {
          targetError = failure?.status == 404
              ? 'This linked item is no longer available. The notification remains here.'
              : failure?.message;
        }
      }
      return null;
    } finally {
      if (!_disposed && identical(_targetRead, cancellation)) {
        resolving = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidate();
    _clearPrivate();
    _surfaces.clear();
    _cooldown?.cancel();
    super.dispose();
  }
}
