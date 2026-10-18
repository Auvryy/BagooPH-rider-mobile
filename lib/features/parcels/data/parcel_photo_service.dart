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

/// A photo draft is separate from a dispatched command. Its protected original
/// is offered for 24 hours only for the exact account/API/task/action/version.
/// Expired drafts are removed when checked. Recovery never submits an outcome.
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
  RecoveredParcelPhoto? recovered;
  String? notice;

  void _guard() {
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

  ParcelProof? forTask(String taskId, String version, ParcelAction action) {
    final value = recovered;
    if (_disposed ||
        !isCurrent() ||
        value == null ||
        !_owns(value.context) ||
        !_fresh(value.context) ||
        value.context.taskId != taskId ||
        value.context.version != version ||
        value.context.action != action) {
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

  Future<void> _save(ParcelPhotoContext context, ParcelProof proof) async {
    _guard();
    final previous = await _saved();
    final reference = await proofs.save(context.key, proof);
    _guard();
    await _storage.write(
      key: _draftKey,
      value: jsonEncode({
        'context': context.toJson(),
        'proof': reference.toJson(),
      }),
    );
    _guard();
    recovered = RecoveredParcelPhoto(context, reference, proof);
    if (previous != null) {
      final old = ParcelProofReference.fromJson(Wire.object(previous['proof']));
      if (old.key != reference.key) await proofs.delete(old);
    }
  }

  Future<void> restore() async {
    if (_disposed || _restored || busy) return;
    busy = true;
    try {
      _guard();
      final draft = await _saved();
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
          recovered = RecoveredParcelPhoto(context, reference, proof);
        } else {
          await proofs.delete(reference);
          await _storage.delete(key: _draftKey);
        }
      }
      if (picker.recoversLostData) {
        // Run once at native workspace startup, including when there is no draft.
        final saved = await _storage.read(key: _pickerKey);
        final files = await picker.recover();
        _guard();
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
        notice = 'An unfinished photo could not be restored. Check saved work requests before choosing another image.';
      }
    } finally {
      _restored = true;
      if (!_disposed) {
        busy = false;
        _changed();
      }
    }
  }

  Future<ParcelProof?> choose({
    required String taskId,
    required String version,
    required ParcelAction action,
    required bool camera,
  }) async {
    _guard();
    if (busy || (camera && !picker.supportsCamera)) {
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
      if (file == null) return null;
      final proof = await ParcelProof.fromFile(file);
      await _save(context, proof);
      return proof;
    } finally {
      if (!_disposed && isCurrent()) {
        try {
          await _clearPicker(context.key);
        } finally {
          busy = false;
          _changed();
        }
      }
    }
  }

  Future<void> discard({String? expectedKey}) async {
    _guard();
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
    recovered = null;
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    recovered = null;
    notice = null;
    super.dispose();
  }
}
