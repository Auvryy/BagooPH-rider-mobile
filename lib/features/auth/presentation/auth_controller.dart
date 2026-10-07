import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/security/token_store.dart';
import '../data/account.dart';
import '../data/auth_repository.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.environment());
final tokenStoreProvider = Provider<TokenStore>((ref) {
  final config = ref.watch(appConfigProvider);
  try {
    if (config.ephemeralLocalSession) return MemoryTokenStore();
  } on FormatException {
    /* Configuration errors are presented by the repository. */
  }
  if (kIsWeb) return _UnavailableBrowserStore();
  try {
    return SecureTokenStore(apiOrigin: config.origin);
  } on FormatException {
    return _UnconfiguredTokenStore();
  }
});
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(appConfigProvider),
    ref.watch(tokenStoreProvider),
  ),
);
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({
    this.user,
    this.initializing = false,
    this.busy = false,
    this.error,
    this.fields = const {},
  });
  final RiderAccount? user;
  final bool initializing, busy;
  final String? error;
  final Map<String, String> fields;
}

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;
  String? rememberedEmail;
  int _generation = 0;
  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    ref.onDispose(() => _generation++);
    unawaited(Future.microtask(_restore));
    return const AuthState(initializing: true);
  }

  AccountFailure _failure(Object error) => error is AccountFailure
      ? error
      : const AccountFailure(
          'The account request could not be confirmed. Please try again.',
        );
  Future<void> _restore() async {
    final generation = ++_generation;
    try {
      final user = await _repository.restore();
      if (generation == _generation) state = AuthState(user: user);
    } catch (error) {
      if (generation == _generation) {
        state = AuthState(error: _failure(error).message);
      }
    }
  }

  Future<bool> _authenticate(Future<RiderAccount> Function() operation) async {
    if (state.busy) return false;
    final generation = ++_generation;
    state = const AuthState(busy: true);
    try {
      final user = await operation();
      if (generation != _generation) return false;
      state = AuthState(user: user);
      return true;
    } catch (error) {
      if (generation == _generation) {
        final failure = _failure(error);
        state = AuthState(error: failure.message, fields: failure.fields);
      }
      return false;
    }
  }

  Future<bool> login(String email, String password) =>
      _authenticate(() => _repository.login(email, password));
  void rememberEmail(String? email) {
    rememberedEmail = email;
  }

  void clearError() {
    if (!state.busy && (state.error != null || state.fields.isNotEmpty)) {
      state = AuthState(user: state.user);
    }
  }

  Future<bool> register(Map<String, String> values, Map<String, XFile> files) =>
      _authenticate(() => _repository.register(values, files));
  Future<void> logout() async {
    if (state.busy) return;
    final user = state.user;
    final generation = ++_generation;
    state = AuthState(user: user, busy: true);
    try {
      await _repository.logout();
      if (generation == _generation) state = const AuthState();
    } catch (error) {
      if (generation == _generation) {
        state = AuthState(user: user, error: _failure(error).message);
      }
    }
  }

  Future<void> refresh() async {
    if (state.busy) return;
    final user = state.user;
    final generation = ++_generation;
    state = AuthState(user: user, busy: true);
    try {
      final fresh = await _repository.refresh();
      if (generation == _generation) state = AuthState(user: fresh);
    } catch (error) {
      final failure = _failure(error);
      if (failure.invalidSession) {
        try {
          await _repository.logout();
        } catch (_) {}
        if (generation == _generation) {
          state = AuthState(error: failure.message);
        }
      } else if (generation == _generation) {
        state = AuthState(user: user, error: failure.message);
      }
    }
  }
}

class _UnavailableBrowserStore implements TokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(String token) async => throw StateError(
    'Browser sessions require the explicit local development configuration.',
  );
}

class _UnconfiguredTokenStore implements TokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(String token) async => throw StateError(
    'Configure the account service before storing a session.',
  );
}
