import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/data/operations_models.dart';
import '../data/handover_intent.dart';
import '../data/handover_models.dart';
import '../data/handover_repository.dart';

final handoverRepositoryProvider = Provider.autoDispose<HandoverRepository?>(
  (ref) {
    final account = ref.watch(
      authControllerProvider.select(
        (s) => (
          id: s.user?.id,
          approved: s.user?.approved,
          operations: s.user?.operationsApiVersion,
          handover: s.user?.handoverApiVersion,
        ),
      ),
    );
    final api = ref.watch(authRepositoryProvider),
        config = ref.watch(appConfigProvider);
    if (account.id == null ||
        account.approved != true ||
        account.operations != 1 ||
        api is! RiderSessionApi) {
      return null;
    }
    var alive = true;
    ref.onDispose(() => alive = false);
    return HandoverRepository(
      api as RiderSessionApi,
      accountId: account.id!,
      journal: SecureHandoverJournal(
        origin: config.origin,
        accountId: account.id!,
      ),
      writesVerified: config.handoverWritesVerified,
      sessionVersion: account.handover,
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

final handoverControllerProvider = Provider.autoDispose<HandoverController>((
  ref,
) {
  final controller = HandoverController(
    ref.watch(handoverRepositoryProvider),
    onSessionEnd: (notice) =>
        ref.read(authControllerProvider.notifier).discardSession(notice),
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [handoverRepositoryProvider, authControllerProvider]);

class HandoverController extends ChangeNotifier {
  HandoverController(
    this.repository, {
    this.onSessionEnd,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final HandoverRepository? repository;
  final Future<void> Function(String notice)? onSessionEnd;
  final DateTime Function() now;
  OperationsHome? home;
  List<HandoverSummary> items = const [];
  HandoverPage? page;
  HandoverDetail? selected;
  String? selectedId;
  String status = 'open';
  HandoverIntent? pendingIntent;
  AccountFailure? failure;
  String? notice;
  bool loading = false,
      loadingMore = false,
      busy = false,
      detailLoading = false;
  bool _disposed = false,
      _foreground = true,
      _visible = true,
      _resumeRequested = false,
      _denied = false,
      _fresh = false;
  int _generation = 0;
  DateTime? _cooldownUntil;
  Timer? _cooldown;
  bool get coolingDown => _cooldownUntil?.isAfter(now()) ?? false;
  bool get active => !_disposed && _foreground && _visible && !_denied;
  bool get canRead =>
      active &&
      !coolingDown &&
      home != null &&
      repository?.canRead(home!) == true;
  bool get canWrite =>
      canRead &&
      _fresh &&
      !loading &&
      !busy &&
      !detailLoading &&
      pendingIntent == null &&
      repository?.canWrite(home!) == true;
  String get availability => repository == null
      ? 'Handover issues need an approved rider and the deployed operations API.'
      : home == null
      ? 'Refresh work to check handover availability.'
      : repository!.canRead(home!) == false
      ? 'Handover issues are unavailable on this deployment.'
      : !repository!.writesVerified
      ? 'Reporting and acknowledgement await handover deployment verification.'
      : repository!.sessionVersion != 1 ||
            home!.capabilities['handover_reporting'] != true
      ? 'Sign out and sign in again for the current handover permission.'
      : 'Report observations only. Review and hub receipt remain separate.';
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void setForeground(bool value) {
    _foreground = value;
    _visibilityChanged();
  }

  void setVisible(bool value) {
    _visible = value;
    _visibilityChanged();
  }

  void _visibilityChanged() {
    if (_disposed) return;
    _generation++;
    _fresh = false;
    if (!active) {
      loading = loadingMore = detailLoading = false;
    } else {
      _resumeRequested = true;
      _resume();
    }
    _changed();
  }

  void _resume() {
    if (_resumeRequested &&
        active &&
        !busy &&
        !loading &&
        !detailLoading &&
        !coolingDown) {
      _resumeRequested = false;
      unawaited(refresh());
    }
  }

  bool _current(int generation) => active && generation == _generation;
  Future<void> handleFailure(Object error) async {
    if (_disposed) return;
    failure = error is AccountFailure
        ? error
        : const AccountFailure(
            'Could not verify handover data. Refresh and try again.',
          );
    final retry = failure!.retryAfterSeconds;
    if (retry != null) {
      _cooldown?.cancel();
      _cooldownUntil = now().add(Duration(seconds: retry));
      _cooldown = Timer(Duration(seconds: retry), () {
        _cooldownUntil = null;
        _changed();
        _resume();
      });
    }
    if (failure!.invalidSession) {
      _denied = true;
      _generation++;
      items = const [];
      page = null;
      home = null;
      selected = null;
      selectedId = null;
      pendingIntent = null;
      notice = null;
      loading = loadingMore = detailLoading = false;
      _changed();
      await onSessionEnd?.call(failure!.message);
    } else if (failure!.status == 404 && selectedId != null) {
      final missing = selectedId;
      selected = null;
      items = List.unmodifiable(items.where((item) => item.id != missing));
    }
    _changed();
  }

  Future<void> refresh({bool checkPending = true}) async {
    final repo = repository;
    if (repo == null || !active || busy || loading || coolingDown) return;
    final generation = ++_generation;
    loading = true;
    _fresh = false;
    failure = null;
    _changed();
    try {
      final pending = await repo.pending();
      if (!_current(generation)) return;
      pendingIntent = pending;
      final fresh = await repo.home();
      if (!_current(generation)) return;
      home = fresh;
      if (!repo.canRead(fresh)) {
        items = const [];
        page = null;
        selected = null;
        return;
      }
      if (pending != null && checkPending) {
        final result = await repo.reconcile();
        if (!_current(generation)) return;
        pendingIntent = await repo.pending();
        if (!_current(generation)) return;
        notice = result == null
            ? 'The saved request has no confirmed result. Check again or retry the same intent.'
            : 'The original request was committed. Current records are refreshed below.';
      }
      final rows = await repo.list(status: status);
      if (!_current(generation)) return;
      page = rows;
      items = _dedupe(rows.items);
      if (selectedId != null) {
        try {
          final detail = await repo.detail(selectedId!);
          if (!_current(generation)) return;
          selected = detail;
        } on AccountFailure catch (e) {
          if (e.status == 404) selected = null;
          rethrow;
        }
      }
      _fresh = true;
    } catch (error) {
      if (_current(generation)) await handleFailure(error);
    } finally {
      if (generation == _generation && !_disposed) {
        loading = false;
        _changed();
        _resume();
      }
    }
  }

  List<HandoverSummary> _dedupe(Iterable<HandoverSummary> rows) =>
      List.unmodifiable({for (final row in rows) row.id: row}.values);
  Future<void> changeStatus(String value) async {
    if (!['open', 'recovered', 'dismissed', 'all'].contains(value) ||
        busy ||
        loading ||
        coolingDown) {
      return;
    }
    status = value;
    items = const [];
    page = null;
    selected = null;
    selectedId = null;
    await refresh();
  }

  Future<void> more() async {
    if (!canRead || busy || loading || loadingMore || page?.hasNext != true) {
      return;
    }
    final generation = _generation, next = page!.page + 1;
    loadingMore = true;
    failure = null;
    _changed();
    try {
      final rows = await repository!.list(status: status, page: next);
      if (!_current(generation)) return;
      page = rows;
      items = _dedupe([...items, ...rows.items]);
    } catch (error) {
      if (_current(generation)) await handleFailure(error);
    } finally {
      if (generation == _generation && !_disposed) {
        loadingMore = false;
        _changed();
      }
    }
  }

  Future<void> open(String id) async {
    if (!canRead || busy) return;
    final generation = ++_generation;
    selectedId = id;
    selected = null;
    detailLoading = true;
    failure = null;
    _fresh = false;
    _changed();
    try {
      final detail = await repository!.detail(id);
      if (_current(generation)) {
        selected = detail;
        _fresh = true;
      }
    } catch (error) {
      if (_current(generation)) await handleFailure(error);
    } finally {
      if (generation == _generation && !_disposed) {
        detailLoading = false;
        _changed();
        _resume();
      }
    }
  }

  void closeDetail() {
    _generation++;
    selected = null;
    selectedId = null;
    loading = loadingMore = detailLoading = false;
    failure = null;
    _changed();
    if (active && !busy) unawaited(refresh());
  }

  Future<bool> report({
    required String barcode,
    required String holder,
    required String location,
    required String notes,
    required HandoverFile file,
  }) => _command(
    () => repository!.report(
      barcode: barcode,
      holder: holder,
      location: location,
      notes: notes,
      file: file,
    ),
  );
  Future<bool> acknowledge({
    required String barcode,
    required String notes,
    required bool possessionVerified,
  }) async {
    final reviewed = selected;
    if (reviewed == null) return false;
    return _command(
      () => repository!.acknowledge(
        reviewed,
        barcode: barcode,
        notes: notes,
        possessionVerified: possessionVerified,
      ),
    );
  }

  Future<bool> _command(Future<Map<String, dynamic>> Function() action) async {
    if (!canWrite) return false;
    busy = true;
    failure = null;
    notice = null;
    _changed();
    bool committed = false;
    try {
      final result = await action();
      if (_disposed || !repository!.isCurrent()) return false;
      committed = true;
      selectedId = Wire.id(result['issue_id']);
      notice = 'The request was recorded. Only actual hub receipt clears a recovery hold.';
    } catch (error) {
      if (!_disposed && repository!.isCurrent()) await handleFailure(error);
    } finally {
      if (!_disposed && repository!.isCurrent()) {
        try {
          pendingIntent = await repository!.pending();
        } catch (error) {
          await handleFailure(error);
        }
        busy = false;
        _changed();
        final commandFailure = failure;
        if (active && !coolingDown) {
          await refresh();
        } else {
          _resumeRequested = true;
        }
        if (commandFailure != null && !_denied) {
          failure = commandFailure;
          _changed();
        }
      }
    }
    return committed;
  }

  Future<void> reconcile({bool retry = false}) async {
    if (!canRead || busy || loading || pendingIntent == null) return;
    busy = true;
    failure = null;
    notice = null;
    _changed();
    try {
      final result = await repository!.reconcile(retryUnknown: retry);
      if (_disposed || !repository!.isCurrent()) return;
      if (result != null) selectedId = Wire.id(result['issue_id']);
      notice = result == null
          ? 'The original request is still unconfirmed. A new intent remains blocked.'
          : 'The original request was committed; current detail is refreshed.';
    } catch (error) {
      if (!_disposed && repository!.isCurrent()) await handleFailure(error);
    } finally {
      if (!_disposed && repository!.isCurrent()) {
        try {
          pendingIntent = await repository!.pending();
        } catch (error) {
          await handleFailure(error);
        }
        busy = false;
        _changed();
        final commandFailure = failure;
        if (active && !coolingDown) {
          await refresh(checkPending: false);
        } else {
          _resumeRequested = true;
        }
        if (commandFailure != null && !_denied) {
          failure = commandFailure;
          _changed();
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cooldown?.cancel();
    super.dispose();
  }
}
