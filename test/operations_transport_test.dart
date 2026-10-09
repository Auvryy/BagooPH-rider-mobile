import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class TransportAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int status = 200;
  Object body = {'data': {}};
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? cancel,
  ) async {
    calls.add(o);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
        'retry-after': ['45'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('command correlation stays separate from durable intent and cannot override origin or bearer', () async {
    final adapter = TransportAdapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    const key = '00000000-0000-4000-8000-000000000001',
        request = '00000000-0000-4000-8000-000000000002';
    await client.request(
      'rider/duty',
      method: 'PATCH',
      token: 'synthetic-session',
      data: {'on_duty': true},
      headers: {'Idempotency-Key': key, 'X-Request-ID': request},
    );
    expect(
      adapter.calls.single.headers['Authorization'],
      'Bearer synthetic-session',
    );
    expect(adapter.calls.single.headers['Idempotency-Key'], key);
    expect(adapter.calls.single.headers['X-Request-ID'], request);
    expect(adapter.calls.single.followRedirects, false);
    for (final path in [
      'https://api.geoapify.com/',
      '//foreign.test',
      '../rider/home',
    ]) {
      await expectLater(
        client.request(path, token: 'synthetic-session'),
        throwsA(isA<AccountFailure>()),
      );
    }
    await expectLater(
      client.request('rider/home', headers: {'Authorization': 'injected'}),
      throwsA(isA<AccountFailure>()),
    );
    expect(adapter.calls.length, 1);
  });
  test('stale, denied, unavailable and quota errors preserve safe diagnostic facts', () async {
    final adapter = TransportAdapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    for (final code in {
      409: 'STALE_RESOURCE',
      403: 'DENIED',
      503: 'OPERATIONS_UNAVAILABLE',
      429: 'RATE_LIMITED',
    }.entries) {
      adapter.status = code.key;
      adapter.body = {
        'message': 'Work unavailable',
        'code': code.value,
        'errors': {},
        'request_id': '00000000-0000-4000-8000-000000000001',
      };
      try {
        await client.request('rider/duty', method: 'PATCH');
        fail('expected failure');
      } on AccountFailure catch (e) {
        expect(e.status, code.key);
        expect(e.code, code.value);
        expect(e.requestId, '00000000-0000-4000-8000-000000000001');
        expect(e.retryAfterSeconds, 45);
        expect(e.unconfirmed, code.key == 503);
      }
    }
  });
}
