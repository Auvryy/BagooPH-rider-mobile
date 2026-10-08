import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_models.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_repository.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// Synthetic example from backend docs/api/RIDER_SETTINGS_API.md at 1dba047.
Map<String, dynamic> snapshot() =>
    jsonDecode(File('test/fixtures/rider_settings_v1.json').readAsStringSync())
        as Map<String, dynamic>;
const account = {
  'id': '7',
  'name': 'Example Rider',
  'email': 'rider@example.test',
  'role': 'courier',
  'status': 'active',
  'kyc_status': 'approved',
  'email_verified': true,
  'can_access_portal': true,
  'access_state': 'approved',
  'settings_api_version': 1,
};

ResponseBody jsonReply(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        'cache-control': ['no-store, private'],
      },
    );

class SettingsAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  ResponseBody Function(RequestOptions) reply = (_) => jsonReply(snapshot());
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/rider/me')) {
      return jsonReply({'data': account});
    }
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<
  ({
    ApiSettingsRepository settings,
    ApiAuthRepository auth,
    MemoryTokenStore store,
    SettingsAdapter adapter,
  })
>
setup() async {
  final adapter = SettingsAdapter();
  final store = MemoryTokenStore();
  await store.write('synthetic-contract-session');
  final auth = ApiAuthRepository(
    const AppConfig('https://bagoo.example.test/api/v1'),
    store,
    client: Dio()..httpClientAdapter = adapter,
  );
  expect((await auth.restore())?.settingsApiVersion, 1);
  adapter.requests.clear();
  return (
    settings: ApiSettingsRepository(
      auth,
      accountId: '7',
      originalEmail: 'rider@example.test',
    ),
    auth: auth,
    store: store,
    adapter: adapter,
  );
}

void main() {
  test(
    'backend v1 example decodes and contact saves use the canonical snapshot',
    () async {
      final h = await setup();
      final initial = await h.settings.read();
      expect(initial.name, 'Example Rider');
      expect(initial.managedAvailable, isFalse);
      expect(initial.phone, isNull);
      expect(initial.emails.single.id, '11');
      final saved = snapshot();
      (saved['data'] as Map)['revision'] = 'b' * 64;
      ((saved['data'] as Map)['profile'] as Map)['phone'] = '+639171234567';
      h.adapter.reply = (_) => jsonReply(saved);
      final result = await h.settings.updatePhone(
        '0917 123 4567',
        initial.revision,
      );
      expect(result.phone, '+639171234567');
      expect(result.revision, 'b' * 64);
      final request = h.adapter.requests.last;
      expect(
        request.path,
        'https://bagoo.example.test/api/v1/rider/settings/profile',
      );
      expect(request.method, 'PATCH');
      expect(request.data, {
        'phone': '0917 123 4567',
        'revision': initial.revision,
      });
      expect(
        request.headers['Authorization'],
        'Bearer synthetic-contract-session',
      );
      expect(request.followRedirects, isFalse);
      expect(request.queryParameters, isEmpty);
    },
  );

  test(
    'all email routes use bearer JSON, listed fields and confirmed snapshots',
    () async {
      final h = await setup();
      h.adapter.reply = (_) => jsonReply({
        'success': true,
        'message': 'Code sent.',
        'cooldown': 60,
        'expires_in': 600,
      });
      final challenge = await h.settings.sendEmailCode(
        'contact@example.test',
        'current-secret',
      );
      expect(challenge.cooldown, 60);
      expect(challenge.expiresIn, 600);
      h.adapter.reply = (_) => jsonReply(snapshot());
      await h.settings.confirmEmail(
        'contact@example.test',
        'current-secret',
        '123456',
      );
      await h.settings.preferEmail('9223372036854775807', 'current-secret');
      await h.settings.removeEmail('11', 'current-secret');
      expect(
        h.adapter.requests.map((r) => (r.method, Uri.parse(r.path).path)),
        [
          ('POST', '/api/v1/rider/settings/emails/send'),
          ('POST', '/api/v1/rider/settings/emails/confirm'),
          (
            'PATCH',
            '/api/v1/rider/settings/emails/9223372036854775807/preferred',
          ),
          ('DELETE', '/api/v1/rider/settings/emails/11'),
        ],
      );
      expect(h.adapter.requests.map((r) => r.data), [
        {'email': 'contact@example.test', 'current_password': 'current-secret'},
        {
          'email': 'contact@example.test',
          'current_password': 'current-secret',
          'code': '123456',
        },
        {'current_password': 'current-secret'},
        {'current_password': 'current-secret'},
      ]);
      for (final r in h.adapter.requests) {
        expect(r.headers['Authorization'], 'Bearer synthetic-contract-session');
        expect(r.queryParameters, isEmpty);
        expect(r.followRedirects, isFalse);
      }
    },
  );

  test(
    'malformed revisions and unsupported email IDs never produce a write',
    () async {
      final h = await setup();
      for (final id in [
        '0',
        '01',
        '-1',
        '11\n',
        '../11',
        '9223372036854775808',
        '1' * 30,
      ]) {
        await expectLater(
          h.settings.removeEmail(id, 'current-secret'),
          throwsA(isA<AccountFailure>()),
        );
        final bad = snapshot();
        (((bad['data'] as Map)['emails'] as List).single as Map)['id'] = id;
        expect(
          () => SettingsSnapshot.decode(
            bad,
            accountId: '7',
            originalEmail: 'rider@example.test',
          ),
          throwsA(isA<AccountFailure>()),
        );
      }
      for (final revision in [
        '',
        'a' * 63,
        'a' * 65,
        'A' * 64,
        '${'a' * 64}\n',
      ]) {
        await expectLater(
          h.settings.updatePhone(null, revision),
          throwsA(isA<AccountFailure>()),
        );
        final bad = snapshot();
        (bad['data'] as Map)['revision'] = revision;
        expect(
          () => SettingsSnapshot.decode(
            bad,
            accountId: '7',
            originalEmail: 'rider@example.test',
          ),
          throwsA(isA<AccountFailure>()),
        );
      }
      expect(h.adapter.requests, isEmpty);
    },
  );

  test(
    'HTTP stale edits and field errors preserve data without a retry',
    () async {
      final h = await setup();
      final c = SettingsController(
        h.settings,
        onSessionEnd: (_) async {},
        onSaved: () async {},
      );
      addTearDown(c.dispose);
      await c.load();
      while (c.loading) {
        await Future<void>.delayed(Duration.zero);
      }
      final initial = c.data!;
      h.adapter.reply = (_) => jsonReply({
        'message': 'Changed. Reload settings.',
        'data': snapshot()['data'],
      }, 409);
      expect(await c.savePhone('09171234567', initial.revision), isFalse);
      expect(c.data, same(initial));
      expect(c.needsRefresh, isTrue);
      final count = h.adapter.requests.length;
      expect(await c.savePhone(null, initial.revision), isFalse);
      expect(h.adapter.requests.length, count);
      h.adapter.reply = (_) => jsonReply(snapshot());
      expect(await c.load(), isTrue);
      h.adapter.reply = (_) => jsonReply({
        'message': 'Invalid phone.',
        'errors': {
          'phone': ['Use a Philippine mobile number.'],
        },
      }, 422);
      expect(await c.savePhone('letters', initial.revision), isFalse);
      expect(c.failure?.fields['phone'], 'Use a Philippine mobile number.');
      expect(c.result, isNull);
      expect(await h.store.read(), isNotNull);
    },
  );

  test(
    'old account-only settings denial requires a fresh native login',
    () async {
      final h = await setup();
      h.adapter.reply = (_) => jsonReply({
        'message': 'Sign in again to enable native account settings.',
      }, 403);
      final c = SettingsController(
        h.settings,
        onSessionEnd: (_) => h.auth.discardSession(),
        onSaved: () async {},
      );
      addTearDown(c.dispose);
      while (c.failure == null) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.failure?.status, 403);
      expect(await h.store.read(), isNull);
      expect(c.data, isNull);
    },
  );

  test('password confirmation clears access and mail failure never confirms delivery', () async {
    final h = await setup();
    final c = SettingsController(
      h.settings,
      onSessionEnd: (_) => h.auth.discardSession(),
      onSaved: () async {},
    );
    addTearDown(c.dispose);
    while (c.data == null) {
      await Future<void>.delayed(Duration.zero);
    }
    h.adapter.reply = (_) =>
        jsonReply({'success': false, 'message': 'Mail unavailable.'}, 503);
    expect(await c.sendCode('contact@example.test', 'current-secret'), isFalse);
    expect(c.challengeEmail, isNull);
    expect(c.result, isNull);
    h.adapter.reply = (_) => jsonReply(snapshot());
    expect(await c.load(), isTrue);
    h.adapter.reply = (_) => jsonReply({
      'data': {'password_changed': true, 'reauthentication_required': true},
    });
    expect(
      await c.changePassword(
        'current-secret',
        'new-secret-1234',
        'new-secret-1234',
      ),
      isTrue,
    );
    expect(await h.store.read(), isNull);
    final request = h.adapter.requests.last;
    expect(request.method, 'PUT');
    expect(Uri.parse(request.path).path, '/api/v1/rider/settings/password');
    expect(request.data, {
      'current_password': 'current-secret',
      'password': 'new-secret-1234',
      'password_confirmation': 'new-secret-1234',
    });
  });
}
