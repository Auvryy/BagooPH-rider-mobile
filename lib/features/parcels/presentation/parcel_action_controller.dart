import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/commands/parcel_proof.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';

class ParcelActionController extends ChangeNotifier {
  ParcelActionController({
    required this.work,
    required this.taskId,
    required this.action,
  }) {
    work.addListener(_workChanged);
    unawaited(Future.microtask(refresh));
  }
  final WorkspaceController work;
  final String taskId;
  final ParcelAction action;
  OperationTask? task;
  String? barcode;
  AccountFailure? failure;
  Map<String, dynamic>? result;
  bool loading = false, submitting = false, foreground = true;
  bool needsRevalidation = true, _disposed = false;
  int _generation = 0;
  String? _waitingKey;

  bool get canCapture =>
      !_disposed &&
      foreground &&
      !loading &&
      !submitting &&
      !needsRevalidation &&
      result == null &&
      task?.actions[action.name] == true &&
      work.canWriteParcel &&
      work.selectedTask?.id == taskId;
  bool get canSubmit => canCapture && barcode == task?.tracking;
  String? get unavailableReason {
    if (!foreground) return 'Return to Rider to check this parcel again.';
    if (work.pendingIntent != null) {
      return 'Check the saved work request before continuing.';
    }
    if (work.coolingDown) {
      return 'Wait for the request cooldown before checking again.';
    }
    if (work.operations?.parcelWritesVerified != true) {
      return 'Parcel actions are not available yet. You can review this task and contact your hub.';
    }
    if (work.homeData.data?.capabilities['parcel_actions'] != true) {
      return 'Parcel actions are unavailable for this account.';
    }
    if (task?.actions[action.name] != true) {
      return task?.actionDenials[action.name] == 'UNSUPPORTED_PAYMENT_OUTCOME'
          ? 'This payment type cannot be recorded in the app yet. Contact your hub for the next step.'
          : 'This action is not available for the current parcel.';
    }
    if (needsRevalidation) return 'Refresh this parcel before continuing.';
    return null;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _workChanged() {
    if (_disposed) return;
    if (!work.hasWorkAccess) {
      _generation++;
      task = null;
      barcode = null;
      result = null;
      _waitingKey = null;
      loading = false;
      failure = const AccountFailure(
        'This parcel is no longer available for your session.',
      );
      needsRevalidation = true;
    } else if (_waitingKey != null &&
        work.reconciledWorkKey == _waitingKey &&
        work.reconciledWorkResult?['task_id'] == taskId &&
        work.reconciledWorkResult?['operational_stage'] ==
            action.recordedStage) {
      result = work.reconciledWorkResult;
      barcode = null;
      failure = null;
      _waitingKey = null;
    } else if (!loading && !submitting && task != null) {
      final selected = work.selectedTask;
      if (selected?.id != taskId) {
        task = null;
        barcode = null;
        needsRevalidation = true;
        failure = const AccountFailure(
          'This parcel is no longer available. Return to your current tasks.',
        );
      } else if (selected?.version != task?.version) {
        needsRevalidation = true;
        barcode = null;
      }
    }
    _changed();
  }

  Future<void> refresh() async {
    if (_disposed || loading || submitting || !foreground) return;
    final generation = ++_generation;
    loading = true;
    failure = null;
    needsRevalidation = true;
    _changed();
    try {
      if (work.homeData.status != FeatureStatus.ready) await work.refreshHome();
      if (_disposed || generation != _generation || !foreground) return;
      final fresh = await work.revalidateSelectedStop(taskId);
      if (_disposed || generation != _generation || !foreground) return;
      if (fresh == null ||
          fresh.preview ||
          fresh.actions[action.name] != true ||
          (action == ParcelAction.fail && fresh.failurePolicy == null)) {
        task = null;
        barcode = null;
        failure =
            work.workFailure ??
            const AccountFailure('This parcel action is no longer available.');
      } else {
        if (task != null && task!.version != fresh.version) barcode = null;
        task = fresh;
        needsRevalidation = false;
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        failure = error is AccountFailure
            ? error
            : const AccountFailure(
                'Could not check the current parcel. Try again.',
              );
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _changed();
      }
    }
  }

  void setForeground(bool value) {
    if (_disposed || foreground == value) return;
    foreground = value;
    _generation++;
    loading = false;
    needsRevalidation = true;
    _changed();
    if (value && !submitting) unawaited(refresh());
  }

  void acceptScan(String raw) {
    if (!canCapture) return;
    try {
      final actual = parcelWaybill(raw);
      if (actual != task!.tracking) {
        throw const AccountFailure(
          'That waybill belongs to a different parcel.',
          fields: {'barcode': 'Scan the waybill attached to this parcel.'},
        );
      }
      barcode = actual;
      failure = null;
    } on AccountFailure catch (error) {
      barcode = null;
      failure = error;
    }
    _changed();
  }

  void captureFailed() {
    failure = const AccountFailure(
      'Could not open the camera. Check permission and try again.',
    );
    _changed();
  }

  void clearFieldError(String field) {
    final previous = failure;
    if (previous == null || !previous.fields.containsKey(field)) return;
    final fields = {...previous.fields}..remove(field);
    failure = fields.isEmpty
        ? null
        : AccountFailure(
            previous.message,
            status: previous.status,
            code: previous.code,
            requestId: previous.requestId,
            unconfirmed: previous.unconfirmed,
            retryAfterSeconds: previous.retryAfterSeconds,
            fields: fields,
          );
    _changed();
  }

  Future<bool> submit({
    Map<String, dynamic> fields = const {},
    ParcelProof? proof,
  }) async {
    if (!canSubmit) return false;
    final reviewed = task!;
    final scanned = barcode!;
    submitting = true;
    final previousReconciledKey = work.reconciledWorkKey;
    failure = null;
    _changed();
    try {
      final committed = await work.performParcel(
        action,
        reviewed,
        barcode: scanned,
        fields: fields,
        proof: proof,
      );
      if (_disposed || !work.hasWorkAccess) return false;
      if (committed == null) {
        if (work.reconciledWorkKey != previousReconciledKey &&
            work.reconciledWorkResult?['task_id'] == taskId &&
            work.reconciledWorkResult?['operational_stage'] ==
                action.recordedStage) {
          result = work.reconciledWorkResult;
          barcode = null;
          return true;
        }
        final pending = work.pendingIntent;
        if (pending?.resource == taskId && pending?.action == action.name) {
          _waitingKey = pending!.key;
        }
        failure =
            work.workFailure ??
            const AccountFailure(
              'The action could not be confirmed. Check the saved request.',
            );
        if (failure!.status == 409 || failure!.status == 404) {
          needsRevalidation = true;
          barcode = null;
        }
        return false;
      }
      result = committed;
      barcode = null;
      return true;
    } catch (error) {
      if (!_disposed) {
        failure = error is AccountFailure
            ? error
            : const AccountFailure(
                'Could not confirm this action. Check the saved request.',
              );
      }
      return false;
    } finally {
      if (!_disposed) {
        submitting = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    barcode = null;
    task = null;
    work.removeListener(_workChanged);
    super.dispose();
  }
}
