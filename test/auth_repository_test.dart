import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const profile = {
  'id': '7',
  'name': 'Test Rider',
  'email': 'rider@example.test',
  'role': 'courier',
  'status': 'active',
  'kyc_status': 'approved',
  'email_verified': true,
  'can_access_portal': true,
  'access_state': 'approved',
};

class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final ResponseBody Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  test(
    'only an explicit supported integer settings version enables the API',
    () {
      expect(
        RiderAccount.fromJson({...profile, 'settings_api_version': 1})
            .settingsApiVersion,
        1,
      );
      for (final version in [null, '1', 1.0, 2]) {
        expect(
          RiderAccount.fromJson({...profile, 'settings_api_version': version})
              .settingsApiVersion,
          isNull,
        );
      }
    },
  );
  test(
    'known revoked sessions clear locally without a second network request',
    () async {
      final store = MemoryTokenStore();
      await store.write('revoked-session');
      final adapter = Adapter((_) => response({'data': profile}));
      final repo = ApiAuthRepository(
        const AppConfig('https://bagoo.example.test/api/v1'),
        store,
        client: Dio()..httpClientAdapter = adapter,
      );
      await repo.restore();
      final requestCount = adapter.requests.length;
      await repo.discardSession();
      expect(await store.read(), isNull);
      expect(adapter.requests.length, requestCount);
      expect(
        () => repo.authenticatedRequest('rider/settings'),
        throwsA(isA<AccountFailure>().having((e) => e.status, 'status', 401)),
      );
    },
  );
  test(
    'login confirms own account; logout revokes before clearing local state',
    () async {
      final store = MemoryTokenStore();
      final adapter = Adapter((request) {
        if (request.path.endsWith('/auth/tokens')) {
          return response({
            'data': {'token': 'test-session', 'user': profile},
          });
        }
        if (request.path.endsWith('/rider/me')) {
          expect(request.headers['Authorization'], 'Bearer test-session');
          return response({'data': profile});
        }
        return response({'message': 'Signed out.'});
      });
      final repo = ApiAuthRepository(
        const AppConfig('https://bagoo.example.test/api/v1'),
        store,
        client: Dio()..httpClientAdapter = adapter,
      );
      expect((await repo.login('rider@example.test', 'test-password')).id, '7');
      expect(await store.read(), 'test-session');
      await repo.logout();
      expect(adapter.requests.last.method, 'DELETE');
      expect(await store.read(), isNull);
      expect(
        adapter.requests.every(
          (request) => request.uri.host == 'bagoo.example.test',
        ),
        isTrue,
      );
    },
  );
  test(
    'expired session cannot restore a profile and clears the stored token',
    () async {
      final store = MemoryTokenStore();
      await store.write('expired');
      final repo = ApiAuthRepository(
        const AppConfig('https://bagoo.example.test/api/v1'),
        store,
        client: Dio()
          ..httpClientAdapter = Adapter(
            (_) => response({'message': 'Unauthenticated.'}, 401),
          ),
      );
      expect(await repo.restore(), isNull);
      expect(await store.read(), isNull);
    },
  );
  test('unconfirmed logout retains the session for retry', () async {
    final store = MemoryTokenStore();
    await store.write('valid');
    final adapter = Adapter(
      (request) => request.method == 'DELETE'
          ? response({'message': 'Unavailable.'}, 503)
          : response({'data': profile}),
    );
    final repo = ApiAuthRepository(
      const AppConfig('https://bagoo.example.test/api/v1'),
      store,
      client: Dio()..httpClientAdapter = adapter,
    );
    await repo.restore();
    await expectLater(repo.logout(), throwsA(isA<AccountFailure>()));
    expect(await store.read(), 'valid');
  });
  test('redirects never forward a bearer to another origin', () async {
    final store = MemoryTokenStore();
    await store.write('private');
    final adapter = Adapter(
      (_) => ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': ['https://foreign.example.test'],
        },
      ),
    );
    final repo = ApiAuthRepository(
      const AppConfig('https://bagoo.example.test/api/v1'),
      store,
      client: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(repo.restore(), throwsA(isA<AccountFailure>()));
    expect(adapter.requests.length, 1);
    expect(adapter.requests.single.followRedirects, isFalse);
  });
  test('privileged role and malformed account responses are rejected', () {
    expect(
      () => RiderAccount.fromJson({...profile, 'role': 'buyer'}),
      throwsFormatException,
    );
    expect(() => RiderAccount.fromJson({'id': '7'}), throwsFormatException);
    expect(
      () => RiderAccount.fromJson({...profile, 'status': 'suspended'}),
      throwsFormatException,
    );
    expect(
      () => RiderAccount.fromJson({...profile, 'access_state': 'holding'}),
      throwsFormatException,
    );
  });

  test('pending and rejected holding match the server feedback and flags', () {
    for (final review in ['pending_approval', 'rejected']) {
      final account = RiderAccount.fromJson({
        ...profile,
        'status': 'pending_approval',
        'kyc_status': review,
        'access_state': 'holding',
        'can_access_portal': false,
        'kyc_feedback': 'Test review feedback',
      });
      expect(account.approved, isFalse);
      expect(account.kycStatus, review);
      expect(account.feedback, 'Test review feedback');
    }
  });

  test('restricted session restoration clears the device token', () async {
    final store = MemoryTokenStore();
    await store.write('restricted-test-session');
    final repo = ApiAuthRepository(
      const AppConfig('https://bagoo.example.test/api/v1'),
      store,
      client: Dio()
        ..httpClientAdapter = Adapter(
          (_) => response({'message': 'This account is restricted.'}, 403),
        ),
    );
    expect(await repo.restore(), isNull);
    expect(await store.read(), isNull);
  });
}
