import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class ReadAdapter implements HttpClientAdapter {
  final started = Completer<void>();
  final calls = <RequestOptions>[];
  bool delay = true, cancelled = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    calls.add(request);
    if (!started.isCompleted) started.complete();
    if (delay) {
      await cancel;
      cancelled = true;
      throw DioException(
        requestOptions: request,
        type: DioExceptionType.cancel,
        error: 'Cancelled selected read',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('the native transport cancels a selected read without refunding its shared budget', () async {
    final adapter = ReadAdapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    final cancel = RiderReadCancellation();
    final reading = client.request(
      'rider/conversations/pickup-1-2-3/messages',
      token: 'synthetic-session',
      cancellation: cancel,
    );
    final assertion = expectLater(
      reading,
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.code,
          'cancelled',
          'REQUEST_CANCELLED',
        ),
      ),
    );
    await adapter.started.future;
    cancel.cancel();
    await assertion;
    await Future<void>.delayed(Duration.zero);
    expect(adapter.cancelled, isTrue);
    expect(
      adapter.calls.single.headers['Authorization'],
      'Bearer synthetic-session',
    );
    expect(adapter.calls.single.followRedirects, isFalse);
    adapter.delay = false;
    for (var i = 0; i < 29; i++) {
      await client.request('rider/home');
    }
    await expectLater(
      client.request('rider/conversations'),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.code,
          'budget',
          'CLIENT_REQUEST_BUDGET',
        ),
      ),
    );
    expect(adapter.calls, hasLength(30));
  });
  test('an already cancelled read and cancellation attached to a write never reach HTTP', () async {
    final adapter = ReadAdapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    final old = RiderReadCancellation()..cancel();
    await expectLater(
      client.request('rider/conversations', cancellation: old),
      throwsA(isA<AccountFailure>()),
    );
    await expectLater(
      client.request(
        'rider/conversations/pickup-1-2-3/messages',
        method: 'POST',
        cancellation: RiderReadCancellation(),
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(adapter.calls, isEmpty);
  });
}
