import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart';
import '../data/cash_models.dart';
import '../data/cash_repository.dart';

/// Account-scoped volatile views. Closing, covering or backgrounding the surface
/// clears financial facts; only the original unresolved command is durable.
class CashController extends ChangeNotifier {
  CashController(
    this.repository, {
    this.onSessionEnd,
    this.onWorkChanged,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final CashRepository? repository;
  final Future<void> Function(String)? onSessionEnd;
  final Future<void> Function()? onWorkChanged;
  final DateTime Function() now;
  CashPage? page;
  CashAccount? detail;
  CommandIntent? pending;
  String query = '';
  String? selectedId;
  String? notice;
  AccountFailure? failure;
  bool loading = false, loadingMore = false, working = false, available = false;
  bool _foreground = true,
      _visible = false,
      _disposed = false,
      _revoked = false;
  int _generation = 0;
  RiderReadCancellation? _read;
  Timer? _poll, _cooldown;
  DateTime? _cooldownUntil;
  bool get active => !_disposed && !_revoked && _foreground && _visible;
  bool get coolingDown => _cooldownUntil?.isAfter(now()) ?? false;
  bool get canRefresh =>
      active && !working && !loading && !loadingMore && !coolingDown;
  bool get canOffer =>
      active &&
      available &&
      !working &&
      !loading &&
      !loadingMore &&
      !coolingDown &&
      pending == null &&
      repository?.cashWritesVerified == true &&
      detail?.canOffer == true &&
      detail!.recipients.isNotEmpty;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    _generation++;
    _read?.cancel();
    _read = null;
    page = null;
    detail = null;
    pending = null;
    available = false;
    loading = loadingMore = false;
    _poll?.cancel();
  }

  void setVisible(bool value) {
    if (_visible == value) return;
    _visible = value;
    if (!value) {
      _clear();
      _changed();
    } else if (active) {
      unawaited(refresh());
    }
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) {
      _clear();
      _changed();
    } else if (active) {
      unawaited(refresh());
    }
  }

  void capabilityUnavailable() {
    _clear();
    notice = 'Cash records are unavailable for this account.';
    _changed();
  }

  void revoke(String message) {
    _revoked = true;
    _clear();
    notice = message;
    _cooldown?.cancel();
    _changed();
  }

  Future<void> _error(Object error) async {
    final e = error is AccountFailure
        ? error
        : const AccountFailure(
            'Cash records could not be verified. Refresh and try again.',
          );
    failure = e;
    notice = e.message;
    if (e.retryAfterSeconds != null) {
      _cooldownUntil = now().add(Duration(seconds: e.retryAfterSeconds!));
      _cooldown?.cancel();
      _cooldown = Timer(Duration(seconds: e.retryAfterSeconds!), () {
        _cooldownUntil = null;
        _changed();
      });
    }
    if (e.invalidSession) {
      revoke(e.message);
      await onSessionEnd?.call(e.message);
    } else if (e.status == 403 || e.status == 404) {
      _clear();
    }
    _changed();
  }

  Future<void> refresh() async {
    if (!canRefresh) return;
    final repo = repository;
    if (repo == null) {
      notice = 'Cash records are unavailable for this account.';
      _changed();
      return;
    }
    final generation = ++_generation;
    final read = RiderReadCancellation();
    _read?.cancel();
    _read = read;
    loading = true;
    available = false;
    detail = null;
    page = null;
    failure = null;
    _changed();
    bool current() => active && generation == _generation && !read.cancelled;
    try {
      if (!await repo.cashAvailable()) {
        if (current()) {
          _clear();
          notice = 'Cash records are unavailable for this account.';
          _changed();
        }
        return;
      }
      if (!current()) return;
      final result = await repo.cashPage(query: query, cancellation: read);
      if (!current()) return;
      final selected = selectedId == null
          ? null
          : await repo.cashDetail(selectedId!, cancellation: read);
      if (!current()) return;
      final saved = await repo.pending();
      if (!current()) return;
      // Read-only lookup of any ordinary work result. No retry or replacement.
      if (saved != null) {
        await repo.reconcile();
        if (!current()) return;
      }
      final retained = await repo.pending();
      if (!current()) return;
      page = result;
      detail = selected;
      pending = retained;
      available = true;
      notice = null;
      if (saved != null && retained == null) {
        notice = saved.isCash
            ? 'Original cash offer recorded. Current receipt status is shown below.'
            : 'Original work request confirmed.';
        await onWorkChanged?.call();
      }
    } catch (error) {
      if (current()) await _error(error);
    } finally {
      if (generation == _generation) {
        loading = false;
        _read = null;
        _changed();
        _schedule();
      }
    }
  }

  void _schedule() {
    _poll?.cancel();
    if (active && !working) {
      _poll = Timer(const Duration(seconds: 60), () {
        if (canRefresh) {
          unawaited(refresh());
        } else {
          _schedule();
        }
      });
    }
  }

  Future<void> search(String value) async {
    if (!canRefresh) return;
    try {
      final next = cashQuery(value);
      if (next == query) return;
      query = next;
      selectedId = null;
      await refresh();
    } catch (error) {
      await _error(error);
      _changed();
    }
  }

  Future<void> select(String? id) async {
    if (!canRefresh) return;
    selectedId = id;
    await refresh();
  }

  Future<void> more() async {
    if (!canRefresh || page?.hasMore != true || repository == null) return;
    final generation = _generation;
    final previous = page!;
    final read = RiderReadCancellation();
    _read = read;
    loadingMore = true;
    _changed();
    try {
      if (!await repository!.cashAvailable()) {
        if (active && generation == _generation) capabilityUnavailable();
        return;
      }
      if (!active || generation != _generation) return;
      final next = await repository!.cashPage(
        page: previous.page + 1,
        query: query,
        cancellation: read,
      );
      if (!active || generation != _generation || read.cancelled) return;
      page = next; // Explicit paged navigation; authoritative summary remains all-owned.
      failure = null;
      notice = null;
    } catch (error) {
      if (active && generation == _generation) await _error(error);
    } finally {
      if (generation == _generation) {
        loadingMore = false;
        _changed();
      }
    }
  }

  Future<bool> offer({
    required String recipientId,
    required String amount,
    required String evidenceReference,
  }) async {
    if (!canOffer) return false;
    final reviewed = detail!;
    var refreshAfter = false;
    String? outcome;
    working = true;
    failure = null;
    notice = null;
    _changed();
    try {
      await repository!.offerCash(
        reviewed,
        recipientId: recipientId,
        amount: amount,
        evidenceReference: evidenceReference,
        mayDispatch: () => active && !coolingDown && selectedId == reviewed.id,
      );
      if (!active) return false;
      refreshAfter = true;
      outcome = 'Cash offered. Your held balance changes only after the hub records receipt.';
      notice = outcome;
      await onWorkChanged?.call();
      return true;
    } catch (error) {
      if (active) {
        await _error(error);
        try {
          pending = await repository!.pending();
        } catch (_) {}
        refreshAfter =
            pending != null || (error is AccountFailure && error.status == 409);
      }
      return false;
    } finally {
      working = false;
      _changed();
      if (active && refreshAfter) await refresh();
      if (active && outcome != null) {
        notice = outcome;
        _changed();
      }
    }
  }

  Future<void> recover({bool retryUnknown = false}) async {
    if (!canRefresh || repository == null) return;
    working = true;
    failure = null;
    var refreshAfter = false;
    String? outcome;
    _changed();
    try {
      final saved = await repository!.pending();
      final result = await repository!.reconcile(
        retryUnknown: retryUnknown,
        mayDispatch: () => active && !coolingDown,
      );
      if (active) {
        pending = await repository!.pending();
        outcome = result == null
            ? 'The original request is still unconfirmed. Check again or explicitly retry the saved request.'
            : saved?.isCash == true
            ? 'Original cash offer recorded. Current receipt status is shown below.'
            : 'Original work request confirmed.';
        refreshAfter = result != null;
        notice = outcome;
        if (result != null) await onWorkChanged?.call();
      }
    } catch (error) {
      if (active) await _error(error);
    } finally {
      working = false;
      _changed();
      if (active && refreshAfter) await refresh();
      if (active && outcome != null) {
        notice = outcome;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _clear();
    _cooldown?.cancel();
    super.dispose();
  }
}
