import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/commands/command_intent.dart';
import 'operations_models.dart';

export '../../../core/commands/command_intent.dart';

abstract interface class CommandJournal {
  Future<CommandIntent?> read();
  Future<void> write(CommandIntent intent);
  Future<void> clear();
}

/// One unresolved intent per API/account/scope. Kept through logout and expiry until
/// reconciliation confirms a result or a definitive rejection. Selected outcome
/// fields are encrypted by secure storage; original proof has its own protected
/// file reference. No bearer credentials or travelled-location history is stored.
class SecureCommandJournal implements CommandJournal {
  SecureCommandJournal({
    required Uri origin,
    required this.accountId,
    String scope = 'work',
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _scope = scope,
       _key = _scopedKey(origin, accountId, scope);
  static String _scopedKey(Uri origin, String accountId, String scope) {
    if (!['work', 'messages', 'notifications', 'company'].contains(scope)) {
      Wire.invalid();
    }
    final namespace = scope == 'work' ? '' : '${scope}_';
    return 'bagoo_rider_command_$namespace${base64UrlEncode(utf8.encode('$origin/$accountId'))}';
  }

  final String accountId, _key, _scope;
  final FlutterSecureStorage _storage;
  @override
  Future<CommandIntent?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    final intent = CommandIntent.fromJson(Wire.object(jsonDecode(value)));
    if (intent.accountId != accountId || !_owns(intent)) {
      Wire.invalid();
    }
    return intent;
  }

  @override
  Future<void> write(CommandIntent intent) async {
    if (intent.accountId != accountId || !_owns(intent)) {
      Wire.invalid();
    }
    await _storage.write(key: _key, value: jsonEncode(intent.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);

  bool _owns(CommandIntent intent) =>
      (intent.isCompany
          ? 'company'
          : intent.isMessage
          ? 'messages'
          : intent.isNotification
          ? 'notifications'
          : 'work') ==
      _scope;
}
