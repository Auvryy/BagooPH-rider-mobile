import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'operations_models.dart';

String commandUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class CommandIntent {
  CommandIntent({
    required this.accountId,
    required this.key,
    required this.action,
    required this.resource,
    required Map<String, dynamic> body,
    required this.createdAt,
  }) : body = Map.unmodifiable(body) {
    Wire.id(accountId);
    Wire.uuid(key);
    if (action == 'duty') {
      if (resource != 'rider' || body.length != 1) Wire.invalid();
      Wire.boolean(body['on_duty']);
    } else if (action == 'claim') {
      if (!Wire.taskId(resource).startsWith('pickup-') || body.length != 1) {
        Wire.invalid();
      }
      Wire.version(body['expected_version']);
    } else {
      Wire.invalid();
    }
  }
  factory CommandIntent.fromJson(Map<String, dynamic> j) => CommandIntent(
    accountId: Wire.id(j['account_id']),
    key: Wire.uuid(j['key']),
    action: Wire.string(j['action']),
    resource: Wire.string(j['resource']),
    body: Wire.object(j['body']),
    createdAt: Wire.time(j['created_at']),
  );
  final String accountId, key, action, resource;
  final Map<String, dynamic> body;
  final DateTime createdAt;
  String get path => action == 'duty'
      ? 'rider/duty'
      : 'rider/pickup-jobs/${resource.substring(7)}/claim';
  String get method => action == 'duty' ? 'PATCH' : 'POST';
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
  };
}

abstract interface class CommandJournal {
  Future<CommandIntent?> read();
  Future<void> write(CommandIntent intent);
  Future<void> clear();
}

/// One unresolved intent per API/account. Kept through logout and expiry until
/// reconciliation confirms a result or a definitive rejection. No contacts,
/// location history, bearer credentials or proof bytes are stored here.
class SecureCommandJournal implements CommandJournal {
  SecureCommandJournal({
    required Uri origin,
    required this.accountId,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _key =
           'bagoo_rider_command_${base64UrlEncode(utf8.encode('$origin/$accountId'))}';
  final String accountId, _key;
  final FlutterSecureStorage _storage;
  @override
  Future<CommandIntent?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    final intent = CommandIntent.fromJson(Wire.object(jsonDecode(value)));
    if (intent.accountId != accountId) Wire.invalid();
    return intent;
  }

  @override
  Future<void> write(CommandIntent intent) async {
    if (intent.accountId != accountId) Wire.invalid();
    await _storage.write(key: _key, value: jsonEncode(intent.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
