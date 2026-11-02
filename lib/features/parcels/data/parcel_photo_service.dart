import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/commands/command_intent.dart';
import '../../../core/commands/parcel_proof.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/wire.dart';

abstract interface class ParcelPhotoPicker {
  bool get supportsCamera;
  bool get recoversLostData;
  Future<XFile?> choose({required bool camera});
  Future<List<XFile>> recover();
}

class PlatformParcelPhotoPicker implements ParcelPhotoPicker {
  PlatformParcelPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  @override
  bool get supportsCamera =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  bool get recoversLostData => supportsCamera;
  @override
  Future<XFile?> choose({required bool camera}) => _picker.pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    // No quality/resize options: fingerprints and retries use original bytes.
    requestFullMetadata: false,
  );
  @override
  Future<List<XFile>> recover() async {
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    return response.files ?? [];
  }
}

class ParcelPhotoContext {
  ParcelPhotoContext({
    required this.origin,
    required this.accountId,
    required this.taskId,
    required this.version,
    required this.action,
    required this.key,
    required this.createdAt,
  }) {
    Wire.id(accountId);
    Wire.taskId(taskId);
    Wire.version(version);
    Wire.uuid(key);
    if (!action.requiresProof) Wire.invalid();
  }
  factory ParcelPhotoContext.fromJson(Map<String, dynamic> j) =>
      ParcelPhotoContext(
        origin: Wire.string(j['origin']),
        accountId: Wire.id(j['account_id']),
        taskId: Wire.taskId(j['task_id']),
        version: Wire.version(j['version']),
        action: ParcelAction.values.byName(Wire.string(j['action'])),
        key: Wire.uuid(j['key']),
        createdAt: Wire.time(j['created_at']),
      );
  final String origin, accountId, taskId, version, key;
  final ParcelAction action;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'origin': origin,
    'account_id': accountId,
    'task_id': taskId,
    'version': version,
    'action': action.name,
    'key': key,
    'created_at': DateTime.fromMillisecondsSinceEpoch(
      createdAt.millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String(),
  };
}

class RecoveredParcelPhoto {
  const RecoveredParcelPhoto(this.context, this.reference, this.proof);
  final ParcelPhotoContext context;
  final ParcelProofReference reference;
  final ParcelProof proof;
}

typedef _PendingPhotoExpiry = ({
  ParcelPhotoContext context,
  ParcelProofReference reference,
});

/// A photo draft is separate from a dispatched command. Its protected original
/// is offered for 24 hours only for the exact account/API/task/action/version.
/// Backgrounding clears the in-memory image and expiry callback. Resume reloads
/// the encrypted draft only while fresh; dispatched commands keep their own
/// proof copy. Recovery never submits an outcome.
class ParcelPhotoService extends ChangeNotifier {
  ParcelPhotoService({
    required this.origin,
    required this.accountId,
    required this.proofs,
    required this.isCurrent,
    ParcelPhotoPicker? picker,
    FlutterSecureStorage? storage,
    DateTime Function()? now,
  }) : picker = picker ?? PlatformParcelPhotoPicker(),
       _storage = storage ?? const FlutterSecureStorage(),
       now = now ?? DateTime.now,
       _draftKey =
           'bagoo_rider_parcel_photo_${base64UrlEncode(utf8.encode('$origin/$accountId'))}';
  final Uri origin;
  final String accountId, _draftKey;
  final ParcelProofStore proofs;
  final bool Function() isCurrent;
  final ParcelPhotoPicker picker;
  final FlutterSecureStorage _storage;
  final DateTime Function() now;
  static const _pickerKey = 'bagoo_rider_parcel_active_photo';
  bool busy = false, _restored = false, _disposed = false;
  bool _foreground = true, _restorePending = false, _endingSession = false;
  bool _lostDataRestoreAttempted = false;
  bool _accessLossBlocked = false;
  int _foregroundGeneration = 0;
  RecoveredParcelPhoto? recovered;
  String? notice;
  Timer? _draftExpiryTimer;
  String? _scheduledExpiryKey;
  String? _expiringDraftKey;
  _PendingPhotoExpiry? _queuedExpiredDraft;
  Future<void>? _accessLossCleanup;
  String get _accessLossKey => '${_draftKey}_access_lost';

  void _guard() {
    if (_disposed || _endingSession || !isCurrent()) {
      recovered = null;
      notice = null;
      throw const AccountFailure('Please sign in again.', status: 401);
    }
  }

  void _guardSessionOwner() {
    if (_disposed || !isCurrent()) {
      recovered = null;
      notice = null;
      throw const AccountFailure('Please sign in again.', status: 401);
    }
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool _owns(ParcelPhotoContext context) =>
      context.origin == origin.toString() && context.accountId == accountId;
  bool _fresh(ParcelPhotoContext context) {
    final age = now().toUtc().difference(context.createdAt);
    return !age.isNegative && age < const Duration(hours: 24);
  }

  bool isUsableDraft(
    ParcelProof proof, {
    required String taskId,
    required String version,
    required ParcelAction action,
  }) {
    final draft = recovered;
    if (_disposed ||
        !_foreground ||
        !isCurrent() ||
        draft == null ||
        !identical(draft.proof, proof) ||
        !_owns(draft.context) ||
        draft.context.taskId != taskId ||
        draft.context.version != version ||
        draft.context.action != action) {
      return false;
    }
    if (!_fresh(draft.context)) {
      _queueExpiry(draft);
      return false;
    }
    return true;
  }

  ParcelProof? forTask(String taskId, String version, ParcelAction action) {
    final value = recovered;
    if (value == null ||
        !isUsableDraft(
          value.proof,
          taskId: taskId,
          version: version,
          action: action,
        )) {
      return null;
    }
    return value.proof;
  }

  Future<Map<String, dynamic>?> _saved() async {
    final value = await _storage.read(key: _draftKey);
    _guard();
    return value == null ? null : Wire.object(jsonDecode(value));
  }

  Future<void> _clearPicker(String key) async {
    final saved = await _storage.read(key: _pickerKey);
    if (saved == null) return;
    final context = ParcelPhotoContext.fromJson(Wire.object(jsonDecode(saved)));
    if (context.key == key) await _storage.delete(key: _pickerKey);
  }

  Future<void> _clearOwnedDraftData({required bool requireSessionOwner}) async {
    final pendingPicker = await _storage.read(key: _pickerKey);
    if (requireSessionOwner) _guardSessionOwner();
    if (pendingPicker != null) {
      final context = ParcelPhotoContext.fromJson(
        Wire.object(jsonDecode(pendingPicker)),
      );
      if (_owns(context)) {
        await _storage.delete(key: _pickerKey);
        if (requireSessionOwner) _guardSessionOwner();
      }
    }
    final saved = await _storage.read(key: _draftKey);
    if (requireSessionOwner) _guardSessionOwner();
    if (saved == null) return;
    final draft = Wire.object(jsonDecode(saved));
    final context = ParcelPhotoContext.fromJson(Wire.object(draft['context']));
    if (!_owns(context)) Wire.invalid();
    final reference = ParcelProofReference.fromJson(
      Wire.object(draft['proof']),
    );
    if (reference.key != context.key) Wire.invalid();
    await proofs.delete(reference);
    if (requireSessionOwner) _guardSessionOwner();
    await _storage.delete(key: _draftKey);
    if (requireSessionOwner) _guardSessionOwner();
  }

  Future<void> _save(ParcelPhotoContext context, ParcelProof proof) async {
    _guard();
    final previous = await _saved();
    final reference = await proofs.save(context.key, proof);
    try {
      _guard();
      await _storage.write(
        key: _draftKey,
        value: jsonEncode({
          'context': context.toJson(),
          'proof': reference.toJson(),
        }),
      );
      _guard();
    } catch (_) {
      await _deleteDraftIfMatches(context, reference);
      rethrow;
    }
    if (_foreground) {
      recovered = RecoveredParcelPhoto(context, reference, proof);
      _scheduleExpiry(recovered!);
    } else {
      recovered = null;
      _restorePending = true;
    }
    if (previous != null) {
      final old = ParcelProofReference.fromJson(Wire.object(previous['proof']));
      if (old.key != reference.key) await proofs.delete(old);
    }
  }

  Future<void> _deleteDraftIfMatches(
    ParcelPhotoContext context,
    ParcelProofReference reference,
  ) async {
    try {
      final value = await _storage.read(key: _draftKey);
      if (value != null) {
        final saved = Wire.object(jsonDecode(value));
        final savedContext = ParcelPhotoContext.fromJson(
          Wire.object(saved['context']),
        );
        final savedReference = ParcelProofReference.fromJson(
          Wire.object(saved['proof']),
        );
        if (savedContext.key == context.key &&
            savedReference.key == reference.key &&
            savedReference.digest == reference.digest &&
            savedReference.extension == reference.extension) {
          await _storage.delete(key: _draftKey);
        }
      }
    } finally {
      await proofs.delete(reference);
    }
  }

  Future<void> restore() async {
    if (_disposed || _endingSession) return;
    if (!_foreground || busy) {
      _restorePending = true;
      return;
    }
    if (_restored && recovered != null) return;
    busy = true;
    _restorePending = false;
    final generation = _foregroundGeneration;
    try {
      _guard();
      if (await _storage.read(key: _accessLossKey) != null) {
        _guard();
        _accessLossBlocked = true;
        await _clearOwnedDraftData(requireSessionOwner: true);
        _guard();
        await _storage.delete(key: _accessLossKey);
        _guard();
        _accessLossBlocked = false;
      }
      if (recovered == null) {
        final draft = await _saved();
        if (!_foreground || generation != _foregroundGeneration) {
          _restorePending = true;
          return;
        }
        if (draft != null) {
          final context = ParcelPhotoContext.fromJson(
            Wire.object(draft['context']),
          );
          if (!_owns(context)) Wire.invalid();
          final reference = ParcelProofReference.fromJson(
            Wire.object(draft['proof']),
          );
          if (reference.key != context.key) Wire.invalid();
          if (_fresh(context)) {
            final proof = await proofs.read(reference);
            _guard();
            if (!_foreground || generation != _foregroundGeneration) {
              _restorePending = true;
              return;
            }
            recovered = RecoveredParcelPhoto(context, reference, proof);
            _scheduleExpiry(recovered!);
          } else {
            await proofs.delete(reference);
            _guard();
            await _storage.delete(key: _draftKey);
          }
        }
      }
      if (picker.recoversLostData && !_lostDataRestoreAttempted) {
        _lostDataRestoreAttempted = true;
        // Run once at native workspace startup, including when there is no draft.
        final saved = await _storage.read(key: _pickerKey);
        final files = await picker.recover();
        _guard();
        if (!_foreground || generation != _foregroundGeneration) {
          _restorePending = true;
          return;
        }
        if (saved != null) {
          final context = ParcelPhotoContext.fromJson(
            Wire.object(jsonDecode(saved)),
          );
          if (_owns(context) && _fresh(context) && files.length == 1) {
            await _save(context, await ParcelProof.fromFile(files.single));
          }
          await _clearPicker(context.key);
        }
      }
    } catch (_) {
      if (!_disposed && isCurrent()) {
        notice = _accessLossBlocked
            ? 'Unfinished photo cleanup could not be confirmed. Refresh Rider before choosing another image.'
            : 'An unfinished photo could not be restored. Check saved work requests before choosing another image.';
      }
    } finally {
      _restored = true;
      if (!_disposed) {
        busy = false;
        _changed();
        _drainQueuedExpiry();
        _retryPendingRestore();
      }
    }
  }

  void _scheduleExpiry(RecoveredParcelPhoto draft) {
    _scheduleSavedDraftExpiry(draft.context, draft.reference);
  }

  void _scheduleSavedDraftExpiry(
    ParcelPhotoContext context,
    ParcelProofReference reference,
  ) {
    if (_endingSession || _disposed) return;
    _draftExpiryTimer?.cancel();
    _scheduledExpiryKey = context.key;
    final expiresAt = context.createdAt.toUtc().add(const Duration(hours: 24));
    final delay = expiresAt.difference(now().toUtc());
    _draftExpiryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (_scheduledExpiryKey == context.key) {
        _draftExpiryTimer = null;
        _scheduledExpiryKey = null;
      }
      _queueSavedDraftExpiry(context, reference);
    });
  }

  void _queueExpiry(RecoveredParcelPhoto draft) {
    _queueSavedDraftExpiry(draft.context, draft.reference);
  }

  void _queueSavedDraftExpiry(
    ParcelPhotoContext context,
    ParcelProofReference reference,
  ) {
    if (_disposed || _endingSession || _expiringDraftKey != null) return;
    if (_fresh(context)) {
      _scheduleSavedDraftExpiry(context, reference);
      return;
    }
    if (_scheduledExpiryKey == context.key) {
      _draftExpiryTimer?.cancel();
      _draftExpiryTimer = null;
      _scheduledExpiryKey = null;
    }
    if (recovered?.context.key == context.key) recovered = null;
    final pending = (context: context, reference: reference);
    if (busy) {
      _queuedExpiredDraft = pending;
      return;
    }
    _expiringDraftKey = context.key;
    // forTask() and isUsableDraft() may be called during widget builds.
    // Defer notifications and storage cleanup until after the current frame.
    unawaited(Future<void>.microtask(() => _expireDraft(pending)));
  }

  Future<void> _expireDraft(_PendingPhotoExpiry draft) async {
    final context = draft.context;
    final reference = draft.reference;
    final key = context.key;
    try {
      if (_disposed) return;
      busy = true;
      _changed();
      _guard();
      final value = await _storage.read(key: _draftKey);
      _guard();
      if (value == null) {
        _guard();
        await proofs.delete(reference);
        return;
      }
      final saved = Wire.object(jsonDecode(value));
      final savedContext = ParcelPhotoContext.fromJson(
        Wire.object(saved['context']),
      );
      if (savedContext.key != key) {
        // A newer draft replaced this one while it was being selected.
        // Preserve its metadata and remove only the expired draft's file.
        await proofs.delete(reference);
        return;
      }
      final savedReference = ParcelProofReference.fromJson(
        Wire.object(saved['proof']),
      );
      if (savedReference.key != reference.key ||
          savedReference.digest != reference.digest ||
          savedReference.extension != reference.extension) {
        Wire.invalid();
      }
      // The submitted command owns a separate proof copy under its command key.
      // Expiring this picker draft cannot remove that unresolved command proof.
      await proofs.delete(reference);
      _guard();
      await _storage.delete(key: _draftKey);
    } catch (_) {
      if (!_disposed && isCurrent()) {
        notice = 'An expired photo could not be removed. Check saved work requests before continuing.';
      }
    } finally {
      busy = false;
      if (_expiringDraftKey == key) _expiringDraftKey = null;
      _changed();
      _drainQueuedExpiry();
      _retryPendingRestore();
    }
  }

  void _drainQueuedExpiry() {
    final draft = _queuedExpiredDraft;
    _queuedExpiredDraft = null;
    if (draft != null) {
      _queueSavedDraftExpiry(draft.context, draft.reference);
    }
  }

  void _retryPendingRestore() {
    if (_restorePending &&
        _foreground &&
        !_disposed &&
        !_endingSession &&
        !busy) {
      _restorePending = false;
      unawaited(restore());
    }
  }

  void setForeground(bool value) {
    if (_disposed || _endingSession || _foreground == value) return;
    _foreground = value;
    _foregroundGeneration++;
    if (!value) {
      _draftExpiryTimer?.cancel();
      _draftExpiryTimer = null;
      _scheduledExpiryKey = null;
      recovered = null;
      notice = null;
      _changed();
      return;
    }
    _restorePending = true;
    _retryPendingRestore();
  }

  Future<ParcelProof?> choose({
    required String taskId,
    required String version,
    required ParcelAction action,
    required bool camera,
  }) async {
    _guard();
    if (_accessLossBlocked ||
        !_foreground ||
        busy ||
        _expiringDraftKey != null ||
        _queuedExpiredDraft != null ||
        (camera && !picker.supportsCamera)) {
      throw const AccountFailure(
        'Photo capture is unavailable. Choose a supported original image.',
      );
    }
    final context = ParcelPhotoContext(
      origin: origin.toString(),
      accountId: accountId,
      taskId: taskId,
      version: version,
      action: action,
      key: commandUuid(),
      createdAt: now().toUtc(),
    );
    busy = true;
    notice = null;
    _changed();
    try {
      // This marker survives Android destroying the activity while its picker is open.
      if (picker.recoversLostData) {
        await _storage.write(
          key: _pickerKey,
          value: jsonEncode(context.toJson()),
        );
      }
      _guard();
      final file = await picker.choose(camera: camera);
      _guard();
      if (!_foreground) {
        throw const AccountFailure('Return to Rider before choosing a photo.');
      }
      if (file == null) return null;
      final proof = await ParcelProof.fromFile(file);
      await _save(context, proof);
      if (!_foreground) {
        throw const AccountFailure('Return to Rider before choosing a photo.');
      }
      return proof;
    } finally {
      if (!_disposed && isCurrent()) {
        try {
          await _clearPicker(context.key);
        } finally {
          busy = false;
          _changed();
          _drainQueuedExpiry();
          _retryPendingRestore();
        }
      }
    }
  }

  Future<void> discard({String? expectedKey}) async {
    _guard();
    if (_expiringDraftKey != null &&
        (expectedKey == null || expectedKey == _expiringDraftKey)) {
      return;
    }
    if (_queuedExpiredDraft != null &&
        (expectedKey == null ||
            expectedKey == _queuedExpiredDraft!.context.key)) {
      return;
    }
    if (expectedKey == null || _scheduledExpiryKey == expectedKey) {
      _draftExpiryTimer?.cancel();
      _draftExpiryTimer = null;
      _scheduledExpiryKey = null;
    }
    final saved = await _saved();
    if (saved == null) return;
    final context = ParcelPhotoContext.fromJson(Wire.object(saved['context']));
    if (!_owns(context) ||
        (expectedKey != null && context.key != expectedKey)) {
      return;
    }
    await proofs.delete(
      ParcelProofReference.fromJson(Wire.object(saved['proof'])),
    );
    _guard();
    await _storage.delete(key: _draftKey);
    _draftExpiryTimer?.cancel();
    _draftExpiryTimer = null;
    _scheduledExpiryKey = null;
    _queuedExpiredDraft = null;
    recovered = null;
    _changed();
  }

  /// Removes only an unsubmitted photo draft before the user signs out.
  /// Unresolved command proof remains stored under its separate command key.
  Future<void> clearForSignOut() async {
    _guard();
    _endingSession = true;
    _foregroundGeneration++;
    _restorePending = false;
    _draftExpiryTimer?.cancel();
    _draftExpiryTimer = null;
    _scheduledExpiryKey = null;
    recovered = null;
    notice = null;
    _changed();
    try {
      await _clearOwnedDraftData(requireSessionOwner: true);
      await _storage.delete(key: _accessLossKey);
      _guardSessionOwner();
      _accessLossBlocked = false;
      _queuedExpiredDraft = null;
      _changed();
    } catch (_) {
      _endingSession = false;
      _changed();
      if (_foreground) {
        _restorePending = true;
        _retryPendingRestore();
      }
      rethrow;
    }
  }

  /// Purges a temporary draft when authoritative account access is lost.
  /// A secure marker makes a later workspace retry cleanup before recovery.
  Future<void> clearForAccessLoss() {
    final pending = _accessLossCleanup;
    if (pending != null) return pending;
    if (_endingSession) return Future<void>.value();
    return _accessLossCleanup = _clearForAccessLoss();
  }

  Future<void> _clearForAccessLoss() async {
    _endingSession = true;
    _foregroundGeneration++;
    _restorePending = false;
    _draftExpiryTimer?.cancel();
    _draftExpiryTimer = null;
    _scheduledExpiryKey = null;
    recovered = null;
    notice = null;
    _accessLossBlocked = true;
    _changed();
    var markerStored = false;
    try {
      try {
        await _storage.write(key: _accessLossKey, value: '1');
        markerStored = true;
      } catch (_) {
        // Still remove the draft now; retry the marker if cleanup then fails.
      }
      await _clearOwnedDraftData(requireSessionOwner: false);
      if (markerStored) await _storage.delete(key: _accessLossKey);
      _accessLossBlocked = false;
      _queuedExpiredDraft = null;
      _changed();
    } catch (_) {
      if (!markerStored) {
        try {
          await _storage.write(key: _accessLossKey, value: '1');
        } catch (_) {}
      }
      _accessLossBlocked = true;
      _changed();
      rethrow;
    }
  }

  void cancelSignOut() {
    if (_disposed || !_endingSession) return;
    _endingSession = false;
    _foregroundGeneration++;
    _restorePending = true;
    _changed();
    _retryPendingRestore();
  }

  @override
  void dispose() {
    _disposed = true;
    _draftExpiryTimer?.cancel();
    _draftExpiryTimer = null;
    recovered = null;
    notice = null;
    super.dispose();
  }
}
