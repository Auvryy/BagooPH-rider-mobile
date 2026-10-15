import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/handover_support.dart';

class EvidenceAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int status = 200;
  Uint8List bytes = pngEvidence;
  Map<String, List<String>> headers = {
    'content-type': ['image/png'],
    'cache-control': ['private, no-store'],
    'x-content-type-options': ['nosniff'],
    'x-request-id': ['00000000-0000-4000-8000-000000000001'],
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
  test('private bytes stay at the configured API origin without redirects or duplicated API prefix', () async {
    final adapter = EvidenceAdapter(), dio = Dio()..httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    final document = await client.evidence(
      'rider/handover-issues/1/evidence',
      token: 'synthetic-session',
    );
    expect(document.bytes, pngEvidence);
    expect(document.mimeType, 'image/png');
    expect(
      adapter.calls.single.uri.toString(),
      'https://bagoo.example.test/api/v1/rider/handover-issues/1/evidence',
    );
    expect(
      adapter.calls.single.headers['Authorization'],
      'Bearer synthetic-session',
    );
    expect(adapter.calls.single.followRedirects, false);
    for (final path in [
      'https://foreign.test/',
      '//foreign.test/file',
      '/api/v1/rider/handover-issues/1/evidence',
      'rider/handover-issues/1/evidence?url=foreign',
      'rider/handover-issues/../evidence',
    ]) {
      await expectLater(
        client.evidence(path, token: 'synthetic-session'),
        throwsA(isA<AccountFailure>()),
      );
    }
    expect(adapter.calls.length, 1);
  });
  for (final status in [401, 403, 404, 409, 422, 429, 503, 200]) {
    test(
      'binary request decodes JSON error $status before displaying a document',
      () async {
        final adapter = EvidenceAdapter()
          ..status = status
          ..bytes = Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'code': 'EVIDENCE_UNAVAILABLE',
                'message': 'Private evidence is unavailable.',
                'errors': {
                  'evidence': ['Original evidence failed verification.'],
                },
                'request_id': '00000000-0000-4000-8000-000000000001',
              }),
            ),
          )
          ..headers = {
            'content-type': ['application/json'],
            'retry-after': ['45'],
          };
        final dio = Dio()..httpClientAdapter = adapter;
        final client = RiderApiClient(
          const AppConfig('https://bagoo.example.test/api/v1'),
          client: dio,
        );
        await expectLater(
          client.evidence(
            'rider/handover-issues/1/evidence',
            token: 'synthetic-session',
          ),
          throwsA(
            isA<AccountFailure>()
                .having((e) => e.status, 'status', status)
                .having(
                  (e) => e.fields['evidence'],
                  'field',
                  'Original evidence failed verification.',
                )
                .having((e) => e.retryAfterSeconds, 'cooldown', 45),
          ),
        );
      },
    );
  }
  test('missing privacy headers, foreign redirect, unsupported MIME and oversized bytes fail closed', () async {
    final adapter = EvidenceAdapter(), dio = Dio()..httpClientAdapter = adapter;
    final client = RiderApiClient(
      const AppConfig('https://bagoo.example.test/api/v1'),
      client: dio,
    );
    final valid = Map<String, List<String>>.from(adapter.headers);
    for (final field in [
      'cache-control',
      'x-content-type-options',
      'content-type',
    ]) {
      adapter.headers = Map.from(valid)..remove(field);
      await expectLater(
        client.evidence(
          'rider/handover-issues/1/evidence',
          token: 'synthetic-session',
        ),
        throwsA(isA<AccountFailure>()),
      );
    }
    adapter.headers = valid;
    adapter.status = 302;
    await expectLater(
      client.evidence(
        'rider/handover-issues/1/evidence',
        token: 'synthetic-session',
      ),
      throwsA(isA<AccountFailure>()),
    );
    adapter.status = 200;
    adapter.bytes = Uint8List(5242881);
    await expectLater(
      client.evidence(
        'rider/handover-issues/1/evidence',
        token: 'synthetic-session',
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(adapter.calls.every((o) => o.followRedirects == false), true);
  });
}
