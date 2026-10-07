import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({required Uri apiOrigin, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _key =
          'bagoo_rider_token_${base64UrlEncode(utf8.encode(apiOrigin.toString()))}';
  final FlutterSecureStorage _storage;
  final String _key;
  static const _legacyKey = 'bagoo_rider_token';
  @override
  Future<String?> read() async {
    // A token saved without an API identity cannot safely migrate environments.
    await _storage.delete(key: _legacyKey);
    return _storage.read(key: _key);
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _legacyKey);
  }
}

/// Explicit local development/test session. Never persists a bearer token.
class MemoryTokenStore implements TokenStore {
  String? _token;
  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
