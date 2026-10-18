import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

class _TripDownload implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int status = 200;
  Uint8List bytes = parcelTestPng();
  Map<String, List<String>> headers = {
    'content-type': ['image/png'],
    'cache-control': ['no-store, private'],
    'x-content-type-options': ['nosniff'],
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    return ResponseBody(Stream.value(bytes), status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  RiderApiClient client(_TripDownload adapter) => RiderApiClient(
    const AppConfig('https://bagoo.example.test/api/v1'),
    client: Dio()..httpClientAdapter = adapter,
  );
  test(
    'both retained-proof paths use bearer transport with redirects disabled',
    () async {
      final a = _TripDownload(), rejected = _TripDownload();
      final c = client(rejected);
      final tested = client(a);
      for (final kind in ['checkpoints', 'attempts']) {
        final path = 'rider/trips/trip-41/$kind/42/proof';
        expect(
          (await tested.evidence(path, token: 'synthetic-session')).bytes,
          parcelTestPng(),
        );
        expect(
          a.calls.last.uri.toString(),
          'https://bagoo.example.test/api/v1/$path',
        );
        expect(
          a.calls.last.headers['Authorization'],
          'Bearer synthetic-session',
        );
        expect(a.calls.last.followRedirects, isFalse);
      }
      for (final path in [
        'https://foreign.test/proof',
        'rider/trips/trip-41/checkpoints/42/proof?x=1',
        'rider/trips/trip-41/checkpoints/42/proof\n',
        'rider/trips/trip-041/checkpoints/42/proof',
        'rider/trips/trip-41/checkpoints/9223372036854775808/proof',
        '/api/v1/rider/trips/trip-41/checkpoints/42/proof',
        'rider/trips/trip-41/other/42/proof',
      ]) {
        await expectLater(
          c.evidence(path, token: 'synthetic-session'),
          throwsA(anyOf(isA<AccountFailure>(), isA<FormatException>())),
        );
      }
      expect(rejected.calls, isEmpty);
    },
  );
  test('Trips rejects PDFs public caching missing sniff guard redirects and oversized streams', () async {
    final a = _TripDownload();
    const path = 'rider/trips/trip-41/checkpoints/42/proof';
    final tested = client(a), valid = Map<String, List<String>>.from(a.headers);
    for (final mime in ['application/pdf', 'text/html', 'image/svg+xml']) {
      a.headers = {
        ...valid,
        'content-type': [mime],
      };
      await expectLater(
        tested.evidence(path, token: 'synthetic-session'),
        throwsA(isA<AccountFailure>()),
      );
    }
    for (final field in ['cache-control', 'x-content-type-options']) {
      a.headers = {...valid}..remove(field);
      await expectLater(
        tested.evidence(path, token: 'synthetic-session'),
        throwsA(isA<AccountFailure>()),
      );
    }
    a.headers = valid;
    a.status = 302;
    await expectLater(
      tested.evidence(path, token: 'synthetic-session'),
      throwsA(isA<AccountFailure>()),
    );
    a.status = 200;
    a.bytes = Uint8List(5242881);
    await expectLater(
      tested.evidence(path, token: 'synthetic-session'),
      throwsA(isA<AccountFailure>()),
    );
  });
  test(
    'changed proof and quota JSON preserve error codes and shared cooldown',
    () async {
      for (final status in [409, 429]) {
        final a = _TripDownload()
          ..status = status
          ..headers = {
            'content-type': ['application/json'],
            'retry-after': ['40'],
          }
          ..bytes = Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'code': status == 409 ? 'EVIDENCE_CHANGED' : 'RATE_LIMITED',
                'message': 'Private proof unavailable',
              }),
            ),
          );
        final c = client(a);
        await expectLater(
          c.evidence(
            'rider/trips/trip-41/attempts/51/proof',
            token: 'synthetic-session',
          ),
          throwsA(
            isA<AccountFailure>()
                .having((e) => e.status, 'status', status)
                .having(
                  (e) => e.code,
                  'code',
                  status == 409 ? 'EVIDENCE_CHANGED' : 'RATE_LIMITED',
                ),
          ),
        );
        if (status == 429) {
          await expectLater(
            c.evidence(
              'rider/trips/trip-41/attempts/51/proof',
              token: 'synthetic-session',
            ),
            throwsA(isA<AccountFailure>()),
          );
          await expectLater(
            c.request('rider/home', token: 'synthetic-session'),
            throwsA(isA<AccountFailure>()),
          );
          expect(a.calls.length, 1);
        }
      }
    },
  );
}
