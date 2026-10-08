import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/rider_api_client.dart';
import '../../auth/data/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider =
    Provider.family<SettingsRepository, SettingsIdentity>((ref, identity) {
      final account = ref.watch(
        authControllerProvider.select(
          (s) => (
            id: s.user?.id,
            email: s.user?.email,
            approved: s.user?.approved,
            version: s.user?.settingsApiVersion,
          ),
        ),
      );
      final repository = ref.watch(authRepositoryProvider);
      if (identity.preview ||
          account.id != identity.accountId ||
          account.approved != true ||
          account.version != 1 ||
          repository is! RiderSessionApi) {
        return const UnavailableSettingsRepository();
      }
      return ApiSettingsRepository(
        repository as RiderSessionApi,
        accountId: identity.accountId,
        originalEmail: account.email!,
      );
    }, dependencies: [authControllerProvider, authRepositoryProvider]);

final settingsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<SettingsController, SettingsIdentity>(
      (ref, identity) => SettingsController(
        ref.watch(settingsRepositoryProvider(identity)),
        onSessionEnd: identity.preview
            ? (_) async {}
            : (notice) => ref
                  .read(authControllerProvider.notifier)
                  .discardSession(notice),
        onSaved: identity.preview
            ? () async {}
            : () => ref.read(authControllerProvider.notifier).refresh(),
      ),
      dependencies: [settingsRepositoryProvider, authControllerProvider],
    );

class SettingsController extends ChangeNotifier {
  SettingsController(
    this.repository, {
    required this.onSessionEnd,
    required this.onSaved,
  }) {
    unawaited(Future.microtask(load));
  }
  final SettingsRepository repository;
  final Future<void> Function(String notice) onSessionEnd;
  final Future<void> Function() onSaved;
  SettingsSnapshot? data;
  AccountFailure? failure;
  bool loading = false, busy = false, needsRefresh = false;
  String? result, challengeEmail;
  DateTime? resendAt, challengeExpiresAt;
  int _generation = 0;
  bool _disposed = false;
  bool get available => repository.available;
  bool get editable => data != null && !busy && !loading && !needsRefresh;
  int get cooldownSeconds {
    final remaining = resendAt?.difference(DateTime.now()).inMilliseconds ?? 0;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  void clearFeedback() {
    if (_disposed || busy) return;
    failure = null;
    result = null;
    _publish();
  }

  void closeChallenge() {
    challengeEmail = null;
    challengeExpiresAt = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    data = null;
    failure = null;
    result = null;
    challengeEmail = null;
    resendAt = null;
    challengeExpiresAt = null;
    super.dispose();
  }

  Future<bool> load() async {
    if (_disposed || busy || loading || !available) return false;
    final generation = ++_generation;
    loading = true;
    failure = null;
    _publish();
    try {
      final next = await repository.read();
      if (_disposed || generation != _generation) return false;
      data = next;
      needsRefresh = false;
      return true;
    } catch (error) {
      if (!_disposed && generation == _generation) await _failed(error);
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _publish();
      }
    }
  }

  Future<void> _failed(Object error) async {
    failure = error is AccountFailure
        ? error
        : const AccountFailure(
            'The account update could not be confirmed.',
            unconfirmed: true,
          );
    needsRefresh = failure!.unconfirmed || failure!.status == 409;
    final retry = failure!.retryAfterSeconds;
    if (retry != null) resendAt = DateTime.now().add(Duration(seconds: retry));
    if (failure!.invalidSession) {
      await onSessionEnd('Your account access changed. Please sign in again.');
    }
  }

  Future<bool> _change(
    Future<SettingsSnapshot> Function() action,
    String message,
  ) async {
    if (_disposed || !editable) return false;
    final generation = ++_generation;
    busy = true;
    failure = null;
    result = null;
    _publish();
    try {
      final saved = await action();
      if (_disposed || generation != _generation) return false;
      data = saved;
      result = message;
      await onSaved();
      return !_disposed && generation == _generation;
    } catch (error) {
      if (!_disposed && generation == _generation) await _failed(error);
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        _publish();
      }
    }
  }

  Future<bool> savePhone(String? phone, String revision) {
    if (data?.canUpdateContact != true) return Future.value(false);
    return _change(
      () => repository.updatePhone(phone, revision),
      'Contact details saved.',
    );
  }

  void changedEmail(String email) {
    if (challengeEmail != null &&
        challengeEmail != email.trim().toLowerCase()) {
      challengeEmail = null;
      challengeExpiresAt = null;
      result = null;
      _publish();
    }
  }

  Future<bool> sendCode(String email, String password) async {
    if (_disposed ||
        !editable ||
        data?.canManageEmails != true ||
        cooldownSeconds > 0) {
      return false;
    }
    final address = email.trim().toLowerCase();
    final generation = ++_generation;
    busy = true;
    failure = null;
    result = null;
    _publish();
    try {
      final sent = await repository.sendEmailCode(address, password);
      if (_disposed || generation != _generation) return false;
      challengeEmail = address;
      resendAt = DateTime.now().add(Duration(seconds: sent.cooldown));
      challengeExpiresAt = DateTime.now().add(
        Duration(seconds: sent.expiresIn),
      );
      result = 'Verification code requested. Check the additional email inbox.';
      return true;
    } catch (error) {
      if (!_disposed && generation == _generation) await _failed(error);
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        _publish();
      }
    }
  }

  Future<bool> confirmEmail(String email, String password, String code) async {
    if (data?.canManageEmails != true ||
        challengeEmail != email.trim().toLowerCase()) {
      return false;
    }
    final saved = await _change(
      () => repository.confirmEmail(challengeEmail!, password, code),
      'Email verified and added. Your sign-in email stays the same.',
    );
    if (saved) {
      challengeEmail = null;
      challengeExpiresAt = null;
      _publish();
    }
    return saved;
  }

  ContactEmail? _address(String id) {
    for (final email in data?.emails ?? <ContactEmail>[]) {
      if (email.id == id) return email;
    }
    return null;
  }

  Future<bool> preferEmail(String id, String password) {
    final email = _address(id);
    if (data?.canManageEmails != true ||
        email == null ||
        !email.verified ||
        email.preferred) {
      return Future.value(false);
    }
    return _change(
      () => repository.preferEmail(id, password),
      'Contact email updated.',
    );
  }

  Future<bool> removeEmail(String id, String password) {
    final email = _address(id);
    if (data?.canManageEmails != true || email == null || email.original) {
      return Future.value(false);
    }
    return _change(
      () => repository.removeEmail(id, password),
      'Additional email removed.',
    );
  }

  Future<bool> changePassword(
    String current,
    String next,
    String confirmation,
  ) async {
    if (_disposed || !editable || data?.canChangePassword != true) return false;
    final generation = ++_generation;
    busy = true;
    failure = null;
    result = null;
    _publish();
    try {
      await repository.changePassword(current, next, confirmation);
      if (_disposed || generation != _generation) return false;
      await onSessionEnd('Password updated. Sign in with your new password.');
      return true;
    } catch (error) {
      if (!_disposed && generation == _generation) {
        await _failed(error);
        if (!_disposed && failure?.unconfirmed == true) {
          await onSessionEnd(
            'The password update was not confirmed. Sign in again or use password recovery.',
          );
        }
      }
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        _publish();
      }
    }
  }
}
