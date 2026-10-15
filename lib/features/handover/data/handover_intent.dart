import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_failure.dart';
import '../../home/data/operations_models.dart';
import 'handover_models.dart';

const evidenceLimit = 5242880;
const evidenceMimes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'pdf': 'application/pdf',
};

bool evidenceMatches(Uint8List bytes, String mime) {
  bool starts(List<int> prefix) =>
      bytes.length >= prefix.length &&
      List.generate(
        prefix.length,
        (i) => bytes[i] == prefix[i],
      ).every((v) => v);
  return switch (mime) {
    'image/jpeg' => starts([255, 216, 255]),
    'image/png' => starts([137, 80, 78, 71, 13, 10, 26, 10]),
    'image/webp' =>
      starts([82, 73, 70, 70]) &&
          bytes.length >= 12 &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP',
    'application/pdf' => starts([37, 80, 68, 70, 45]),
    _ => false,
  };
}

class HandoverFile {
  HandoverFile(Uint8List value, this.extension)
    : bytes = Uint8List.fromList(value).asUnmodifiableView() {
    if (bytes.isEmpty ||
        bytes.length > evidenceLimit ||
        !evidenceMimes.containsKey(extension) ||
        !evidenceMatches(bytes, mime)) {
      throw const AccountFailure(
        'Choose an actual JPG/JPEG/PNG/WEBP/PDF up to 5 MB.',
        fields: {
          'evidence':
              'The file must be non-empty and match its allowed extension.',
        },
      );
    }
  }
  final Uint8List bytes;
  final String extension;
  String get mime => evidenceMimes[extension]!;
  late final String digest = sha256.convert(bytes).toString();
  String get filename => 'handover-evidence.$extension';
  static Future<HandoverFile> fromFile(XFile file) async {
    final length = await file.length();
    if (length < 1 || length > evidenceLimit) {
      throw const AccountFailure(
        'Choose a non-empty evidence file up to 5 MB.',
        fields: {'evidence': 'Maximum file size is 5 MB.'},
      );
    }
    final extension = file.name.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    if (bytes.length != length) {
      throw const AccountFailure('The selected file changed. Choose it again.');
    }
    return HandoverFile(bytes, extension);
  }

  Map<String, dynamic> toJson() => {
    'extension': extension,
    'sha256': digest,
    'bytes': base64Encode(bytes),
  };
  factory HandoverFile.fromJson(Map<String, dynamic> j) {
    final encoded = Wire.string(j['bytes']);
    if (encoded.length > ((evidenceLimit + 2) ~/ 3) * 4) Wire.invalid();
    final file = HandoverFile(
      base64Decode(encoded),
      Wire.string(j['extension']),
    );
    if (file.digest != Wire.version(j['sha256'])) Wire.invalid();
    return file;
  }
}

String handoverBarcode(String value) {
  final code = value.trim().toUpperCase();
  if (code.length > 255 || !RegExp(r'^[A-Z0-9][A-Z0-9_-]*$').hasMatch(code)) {
    throw const AccountFailure(
      'Enter the actual parcel waybill.',
      fields: {'barcode': 'Use the parcel’s visible waybill code.'},
    );
  }
  return code;
}

String handoverText(String value, String field, int min, int max) {
  final text = value.trim();
  if (text.runes.length < min ||
      text.runes.length > max ||
      RegExp(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f<>`{}]').hasMatch(text) ||
      !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) {
    throw AccountFailure(
      'Check the handover report fields.',
      fields: {field: 'Use plain text between $min and $max characters.'},
    );
  }
  return text;
}

class HandoverIntent {
  HandoverIntent({
    required this.accountId,
    required this.key,
    required this.action,
    required this.resource,
    required Map<String, dynamic> body,
    required this.createdAt,
    this.issueId,
    this.file,
  }) : body = Map.unmodifiable(body) {
    Wire.id(accountId);
    Wire.uuid(key);
    if (action == 'handover.report') {
      if (resource != 'handover-report' ||
          body.length != 5 ||
          body['kind'] != 'missed_scan' ||
          file == null ||
          issueId != null) {
        Wire.invalid();
      }
      handoverBarcode(Wire.string(body['barcode']));
      handoverText(
        Wire.string(body['reported_holder']),
        'reported_holder',
        2,
        100,
      );
      handoverText(
        Wire.string(body['reported_location']),
        'reported_location',
        5,
        255,
      );
      handoverText(Wire.string(body['notes']), 'notes', 10, 1000);
    } else if (action == 'handover.acknowledge') {
      if (!resource.startsWith('handover-recovery-') ||
          body.length != 5 ||
          body['possession_verified'] != true ||
          body['possession_verified'] is! bool ||
          file != null ||
          issueId == null) {
        Wire.invalid();
      }
      Wire.id(resource.substring('handover-recovery-'.length));
      Wire.id(issueId);
      handoverVersion(body['expected_version']);
      Wire.version(body['source_token']);
      handoverBarcode(Wire.string(body['barcode']));
      handoverText(Wire.string(body['notes']), 'notes', 10, 1000);
    } else {
      Wire.invalid();
    }
  }
  final String accountId, key, action, resource;
  final String? issueId;
  final Map<String, dynamic> body;
  final DateTime createdAt;
  final HandoverFile? file;
  String get path => action == 'handover.report'
      ? 'rider/handover-issues'
      : 'rider/handover-recoveries/${resource.substring('handover-recovery-'.length)}/acknowledge';
  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'key': key,
    'action': action,
    'resource': resource,
    'body': body,
    'created_at': DateTime.fromMillisecondsSinceEpoch(
      createdAt.millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String(),
    'issue_id': issueId,
    'file': file?.toJson(),
  };
  factory HandoverIntent.fromJson(Map<String, dynamic> j) => HandoverIntent(
    accountId: Wire.id(j['account_id']),
    key: Wire.uuid(j['key']),
    action: Wire.string(j['action']),
    resource: Wire.string(j['resource']),
    body: Wire.object(j['body']),
    createdAt: Wire.time(j['created_at']),
    issueId: j['issue_id'] == null ? null : Wire.id(j['issue_id']),
    file: j['file'] == null
        ? null
        : HandoverFile.fromJson(Wire.object(j['file'])),
  );
}

abstract interface class HandoverJournal {
  Future<HandoverIntent?> read();
  Future<void> write(HandoverIntent value);
  Future<void> clear();
}

/// Original bytes and intent are encrypted together before dispatch. No shared
/// downloads/temp files, public storage path or token is retained. An uncertain
/// intent stays account/API-scoped through logout until its outcome is known.
class SecureHandoverJournal implements HandoverJournal {
  SecureHandoverJournal({
    required Uri origin,
    required this.accountId,
    FlutterSecureStorage? storage,
  }) : storage = storage ?? const FlutterSecureStorage(),
       key =
           'bagoo_handover_${base64UrlEncode(utf8.encode('$origin/$accountId'))}';
  final String accountId, key;
  final FlutterSecureStorage storage;
  @override
  Future<HandoverIntent?> read() async {
    final value = await storage.read(key: key);
    if (value == null) return null;
    final intent = HandoverIntent.fromJson(Wire.object(jsonDecode(value)));
    if (intent.accountId != accountId) Wire.invalid();
    return intent;
  }

  @override
  Future<void> write(HandoverIntent value) async {
    if (value.accountId != accountId) Wire.invalid();
    await storage.write(key: key, value: jsonEncode(value.toJson()));
  }

  @override
  Future<void> clear() => storage.delete(key: key);
}
