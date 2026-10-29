import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_failure.dart';
import '../../home/data/command_journal.dart';
import '../data/company_models.dart';
import '../data/company_repository.dart';

class RiderCompanyController extends ChangeNotifier {
  RiderCompanyController(
    this.repository, {
    this.onAccessDenied,
    this.onAssignmentChanged,
  });
  final RiderCompanyRepository repository;
  final Future<void> Function(String)? onAccessDenied;
  final Future<void> Function()? onAssignmentChanged;
  CompanyAssignment? assignment;
  CompanyPage<RiderCompany>? companies;
  CompanyPage<CompanyApplication>? applications;
  CompanyApplication? selected;
  CommandIntent? pendingIntent;
  String? notice;
  Map<String, String> fields = const {};
  String search = '', province = '';
  bool busy = false,
      readVerified = false,
      unknownRequest = false,
      active = true;
  bool _disposed = false;
  int _epoch = 0;
  Timer? _cooldownTimer;
  DateTime? _cooldownUntil;
  bool get coolingDown => _cooldownUntil?.isAfter(DateTime.now()) == true;
  bool get canRefresh => active && !_disposed && !busy && !coolingDown;
  bool get canAct => canRefresh && readVerified && pendingIntent == null;
  bool _current(int epoch) => !_disposed && active && epoch == _epoch;
  bool get _mayDispatch => active && !_disposed && !coolingDown;

  Future<void> _failure(Object error) async {
    final failure = error is AccountFailure
        ? error
        : const AccountFailure(
            'The company response could not be verified. Refresh or check the saved request before trying again.',
          );
    notice = failure.message;
    fields = failure.fields;
    if (failure.retryAfterSeconds case final seconds?) {
      final wait = seconds.clamp(1, 300);
      _cooldownUntil = DateTime.now().add(Duration(seconds: wait));
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(Duration(seconds: wait), () {
        if (!_disposed) notifyListeners();
      });
    }
    if (failure.invalidSession) {
      assignment = null;
      companies = null;
      applications = null;
      selected = null;
      readVerified = false;
      await onAccessDenied?.call('Sign in again to check your company access.');
    }
  }

  Future<void> _read(int epoch) async {
    final membership = await repository.assignment();
    if (!_current(epoch)) return;
    final requests = await repository.applications();
    if (!_current(epoch)) return;
    final directory = membership.canApply
        ? await repository.companies(search: search, province: province)
        : null;
    if (!_current(epoch)) return;
    final detail = selected == null
        ? null
        : await repository.application(selected!.id);
    if (!_current(epoch)) return;
    assignment = membership;
    applications = requests;
    companies = directory;
    selected = detail;
    readVerified = true;
  }

  Future<void> refresh() async {
    if (!canRefresh) return;
    final epoch = _epoch;
    busy = true;
    readVerified = false;
    fields = const {};
    notice = null;
    notifyListeners();
    try {
      pendingIntent = await repository.pending();
      if (!_current(epoch)) return;
      unknownRequest = false;
      if (pendingIntent != null) {
        try {
          final saved = await repository.reconcile(
            mayDispatch: () => _mayDispatch,
          );
          if (!_current(epoch)) return;
          if (saved != null) notice = 'Your previous company request was recorded. Current details are shown below.';
        } on AccountFailure catch (error) {
          if (error.code != 'COMMAND_UNKNOWN' || error.status != 404) rethrow;
          unknownRequest = true;
        }
        pendingIntent = await repository.pending();
        if (!_current(epoch)) return;
      }
      await _read(epoch);
    } catch (error) {
      if (_current(epoch)) await _failure(error);
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> select(String id) async {
    if (!canRefresh) return;
    final epoch = _epoch;
    busy = true;
    notice = null;
    selected = null;
    notifyListeners();
    try {
      final detail = await repository.application(id);
      if (_current(epoch)) selected = detail;
    } catch (error) {
      if (_current(epoch)) await _failure(error);
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void closeDetail() {
    selected = null;
    fields = const {};
    notifyListeners();
  }

  Future<void> searchCompanies(String query, String area) async {
    if (!canRefresh) return;
    search = query;
    province = area;
    await refresh();
  }

  Future<void> companyPage(int page) async {
    if (!canRefresh || assignment?.canApply != true) return;
    final epoch = _epoch;
    busy = true;
    notice = null;
    notifyListeners();
    try {
      final result = await repository.companies(
        page: page,
        search: search,
        province: province,
      );
      if (_current(epoch)) companies = result;
    } catch (error) {
      if (_current(epoch)) await _failure(error);
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> applicationPage(int page) async {
    if (!canRefresh) return;
    final epoch = _epoch;
    busy = true;
    notice = null;
    notifyListeners();
    try {
      final result = await repository.applications(page: page);
      if (_current(epoch)) applications = result;
    } catch (error) {
      if (_current(epoch)) await _failure(error);
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> submit(
    RiderCompany company, {
    String? note,
    required bool acknowledged,
  }) => _command(
    () => repository.submit(
      company,
      note: note,
      sharingAcknowledged: acknowledged,
      mayDispatch: () => _mayDispatch,
    ),
  );
  Future<bool> decide(
    CompanyApplication request,
    String action, {
    String? reason,
    bool acknowledged = false,
  }) => _command(
    () => repository.decide(
      request,
      action,
      reason: reason,
      acknowledged: acknowledged,
      mayDispatch: () => _mayDispatch,
    ),
  );
  Future<bool> _command(Future<CompanyCommandReceipt> Function() send) async {
    if (!canAct) return false;
    final epoch = _epoch;
    busy = true;
    fields = const {};
    notice = null;
    notifyListeners();
    CompanyCommandReceipt? receipt;
    try {
      receipt = await send();
      if (!_current(epoch)) return false;
      pendingIntent = await repository.pending();
      await _read(epoch);
      if (!_current(epoch)) return false;
      notice = switch (receipt.status) {
        'accepted' =>
          'Assignment accepted. Go on duty from Home when you are ready.',
        'pending' => 'Your request was sent. The company will review it.',
        'declined' => 'Offer declined. The request remains in your history.',
        'withdrawn' => 'Request withdrawn. Its history is retained.',
        _ => 'Your request was recorded.',
      };
      if (receipt.status == 'accepted') await onAssignmentChanged?.call();
      return true;
    } catch (error) {
      if (_current(epoch)) {
        if (receipt != null) {
          readVerified = false;
          notice = 'Your company request was recorded, but current details could not refresh. Refresh before another action.';
        } else {
          await _failure(error);
          if (_current(epoch)) {
            try {
              pendingIntent = await repository.pending();
            } catch (_) {
              readVerified = false;
            }
          }
        }
      }
      return receipt != null;
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> recover({bool retryUnknown = false}) async {
    if (!canRefresh || pendingIntent == null || retryUnknown && !readVerified) {
      return;
    }
    final epoch = _epoch;
    busy = true;
    fields = const {};
    notice = null;
    notifyListeners();
    try {
      final result = await repository.reconcile(
        retryUnknown: retryUnknown,
        mayDispatch: () => _mayDispatch,
      );
      if (!_current(epoch)) return;
      pendingIntent = await repository.pending();
      unknownRequest = false;
      await _read(epoch);
      if (!_current(epoch)) return;
      notice = result == null ? 'There is no saved company request.' : 'The original company request was recorded. Current details are shown below.';
      if (result?.status == 'accepted') await onAssignmentChanged?.call();
    } catch (error) {
      if (_current(epoch)) {
        if (error is AccountFailure && error.code == 'COMMAND_UNKNOWN') {
          unknownRequest = true;
        }
        await _failure(error);
      }
    } finally {
      if (_current(epoch)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void setActive(bool value) {
    if (active == value || _disposed) return;
    active = value;
    _epoch++;
    busy = false;
    readVerified = false;
    if (!value) {
      assignment = null;
      companies = null;
      applications = null;
      selected = null;
      notice = null;
      fields = const {};
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
