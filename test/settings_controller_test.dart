import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_models.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_repository.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';
import 'support/test_settings_repository.dart';

class TestSettingsApi implements RiderSessionApi {
  final requests = <({String path, String method, Object? data})>[];
  Map<String, dynamic> reply = settingsWire();
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    requests.add((path: path, method: method, data: data));
    return reply;
  }
}

class TestSessionAuth extends TestAuthRepository implements RiderSessionApi {
  int settingsRequests = 0;
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
  }) async {
    settingsRequests++;
    return settingsWire();
  }
}

void main() {
  test('settings snapshot rejects foreign identity, malformed capabilities and missing managed fields', () {
    expect(decodeSettings(settingsWire()).managedAvailable, isFalse);
    final foreign = settingsWire();
    (foreign['data'] as Map)['account_id'] = '8';
    expect(() => decodeSettings(foreign), throwsA(isA<AccountFailure>()));
    final caps = settingsWire();
    (caps['data'] as Map)['capabilities'] = <String, dynamic>{
      'update_contact': true,
      'change_password': true,
      'manage_emails': 'true',
    };
    expect(() => decodeSettings(caps), throwsA(isA<AccountFailure>()));
    final incomplete = settingsWire();
    ((incomplete['data'] as Map)['managed_details'] as Map)['available'] = true;
    expect(() => decodeSettings(incomplete), throwsA(isA<AccountFailure>()));
    final unverified = decodeSettings(settingsWire(verified: false));
    expect(unverified.canChangePassword, isFalse);
    expect(unverified.emails.single.verified, isFalse);
  });
  test(
    'account-only deployments do not request proposed settings endpoints',
    () async {
      final auth = TestSessionAuth()..account = TestAuthRepository.approved;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final repo = container.read(
        settingsRepositoryProvider(const SettingsIdentity('7')),
      );
      expect(repo.available, isFalse);
      expect(auth.refreshCalls, 0);
      expect(auth.loginCalls, 0);
      expect(auth.settingsRequests, 0);
      final original = auth.account!;
      auth.account = RiderAccount(
        id: original.id,
        name: original.name,
        email: original.email,
        status: original.status,
        kycStatus: original.kycStatus,
        approved: original.approved,
        emailVerified: original.emailVerified,
        settingsApiVersion: 1,
      );
      await container.read(authControllerProvider.notifier).refresh();
      final supported = container.read(
        settingsRepositoryProvider(const SettingsIdentity('7')),
      );
      expect(supported.available, isTrue);
      await supported.read();
      expect(auth.settingsRequests, 1);
    },
  );
  test('settings writes only permitted fields and reject an unconfirmed password result', () async {
    final api = TestSettingsApi();
    final repo = ApiSettingsRepository(
      api,
      accountId: '7',
      originalEmail: 'rider@example.com',
    );
    await repo.updatePhone(null, 'revision-1');
    expect(api.requests.single.path, 'rider/settings/profile');
    expect(api.requests.single.method, 'PATCH');
    expect(api.requests.single.data, {'phone': null, 'revision': 'revision-1'});
    await expectLater(
      repo.changePassword(
        'current-secret',
        'new-secret-1234',
        'new-secret-1234',
      ),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.unconfirmed,
          'unknown result',
          isTrue,
        ),
      ),
    );
    api.reply = {
      'data': {'password_changed': true, 'reauthentication_required': true},
    };
    await repo.changePassword(
      'current-secret',
      'new-secret-1234',
      'new-secret-1234',
    );
    await expectLater(
      repo.removeEmail('../foreign', 'current-secret'),
      throwsA(isA<AccountFailure>()),
    );
    api.reply = {
      'data': {'account_id': 'foreign'},
    };
    await expectLater(
      repo.updatePhone('09171234567', 'revision-1'),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.unconfirmed,
          'unknown save',
          isTrue,
        ),
      ),
    );
  });
  test('failed refresh and rejected save keep confirmed data; stale edits require refresh', () async {
    final repo = TestSettingsRepository();
    final c = SettingsController(
      repo,
      onSessionEnd: (_) async {},
      onSaved: () async {},
    );
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    final original = c.data;
    repo.readFailure = const AccountFailure('Read unavailable', status: 503);
    await c.load();
    expect(c.data, same(original));
    repo.readFailure = null;
    repo.mutationFailure = const AccountFailure(
      'Phone invalid',
      status: 422,
      fields: {'phone': 'Invalid number'},
    );
    expect(await c.savePhone('letters', 'revision-1'), isFalse);
    expect(c.data, same(original));
    expect(c.result, isNull);
    expect(c.failure!.fields['phone'], 'Invalid number');
    repo.mutationFailure = const AccountFailure('Stale revision', status: 409);
    await c.savePhone('09171234567', 'revision-1');
    expect(c.needsRefresh, isTrue);
    expect(await c.savePhone('09171234567', 'revision-1'), isFalse);
    expect(repo.phoneCalls, 2);
    repo.mutationFailure = null;
    await c.load();
    expect(c.needsRefresh, isFalse);
    expect(await c.savePhone('09171234567', 'revision-1'), isTrue);
    expect(c.data!.phone, '09171234567');
  });
  test('duplicate and disposed saves cannot alter another session', () async {
    final repo = TestSettingsRepository()
      ..pendingPhone = Completer<SettingsSnapshot>();
    int saved = 0;
    final c = SettingsController(
      repo,
      onSessionEnd: (_) async {},
      onSaved: () async {
        saved++;
      },
    );
    await Future<void>.delayed(Duration.zero);
    final pending = c.savePhone('09171234567', 'revision-1');
    expect(await c.savePhone('09171234567', 'revision-1'), isFalse);
    expect(repo.phoneCalls, 1);
    c.dispose();
    repo.pendingPhone!.complete(
      decodeSettings(settingsWire(phone: '09171234567')),
    );
    expect(await pending, isFalse);
    expect(saved, 0);
  });
  test('late password replies cannot end a replacement session', () async {
    final repo = TestSettingsRepository()..pendingPassword = Completer<void>();
    var ended = 0;
    final controller = SettingsController(
      repo,
      onSessionEnd: (_) async {
        ended++;
      },
      onSaved: () async {},
    );
    await Future<void>.delayed(Duration.zero);
    final pending = controller.changePassword(
      'old',
      'new-secret-1234',
      'new-secret-1234',
    );
    expect(
      await controller.changePassword(
        'old',
        'new-secret-1234',
        'new-secret-1234',
      ),
      isFalse,
    );
    controller.dispose();
    repo.pendingPassword!.complete();
    expect(await pending, isFalse);
    expect(ended, 0);
    expect(controller.data, isNull);
  });
  test('password confirmation, unknown results and denied sessions follow cleanup policy', () async {
    final repo = TestSettingsRepository();
    final notices = <String>[];
    final c = SettingsController(
      repo,
      onSessionEnd: (n) async {
        notices.add(n);
      },
      onSaved: () async {},
    );
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    repo.mutationFailure = const AccountFailure(
      'Wrong current password',
      status: 422,
      fields: {'current_password': 'Incorrect'},
    );
    expect(
      await c.changePassword('old', 'new-secret-1234', 'new-secret-1234'),
      isFalse,
    );
    expect(notices, isEmpty);
    repo.mutationFailure = const AccountFailure(
      'Lost response',
      unconfirmed: true,
    );
    expect(
      await c.changePassword('old', 'new-secret-1234', 'new-secret-1234'),
      isFalse,
    );
    expect(notices.single, contains('not confirmed'));
    expect(c.result, isNull);
    repo.mutationFailure = null;
    await c.load();
    expect(
      await c.changePassword('old', 'new-secret-1234', 'new-secret-1234'),
      isTrue,
    );
    expect(notices.last, contains('Password updated'));
    repo.readFailure = const AccountFailure('Revoked', status: 401);
    await c.load();
    expect(notices.last, contains('access changed'));
  });
  test(
    'email cooldown, challenge binding and original-address protections',
    () async {
      final repo = TestSettingsRepository();
      final c = SettingsController(
        repo,
        onSessionEnd: (_) async {},
        onSaved: () async {},
      );
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(await c.sendCode('contact@example.test', 'secret'), isTrue);
      expect(await c.sendCode('contact@example.test', 'secret'), isFalse);
      expect(repo.sendCalls, 1);
      c.changedEmail('different@example.test');
      expect(
        await c.confirmEmail('different@example.test', 'secret', '123456'),
        isFalse,
      );
      expect(repo.confirmCalls, 0);
      expect(await c.removeEmail('1', 'secret'), isFalse);
      expect(await c.removeEmail('foreign', 'secret'), isFalse);
      expect(repo.manageCalls, 0);
      repo.mutationFailure = const AccountFailure(
        'Cooldown',
        status: 429,
        retryAfterSeconds: 120,
      );
      c.resendAt = null;
      await c.sendCode('contact@example.test', 'secret');
      expect(c.cooldownSeconds, greaterThan(100));
      expect(c.challengeEmail, isNull);
    },
  );
}
