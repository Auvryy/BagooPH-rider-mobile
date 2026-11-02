import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class Adapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int status = 200;
  Map<String, dynamic>? response;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? cancel,
  ) async {
    calls.add(o);
    return ResponseBody.fromString(
      jsonEncode(
        response ??
            {
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'legs': [
                      {
                        'steps': [
                          {'from_index': 0, 'to_index': 1},
                        ],
                      },
                    ],
                  },
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [121, 14],
                      [121.01, 14.01],
                    ],
                  },
                },
              ],
            },
      ),
      status,
      headers: {
        'content-type': ['application/json'],
        'retry-after': ['60'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class Immediate extends ProviderScheduler {
  @override
  Future<void> acquire(
    CancelToken? cancel, {
    ProviderRequestKind kind = ProviderRequestKind.route,
  }) async {}
}

class OversizedAdapter implements HttpClientAdapter {
  OversizedAdapter({required this.declared});
  final bool declared;
  bool closed = false;
  late final StreamController<Uint8List> data = StreamController<Uint8List>(
    onListen: () {
      if (!declared) data.add(Uint8List(2000001));
    },
    onCancel: () {
      closed = true;
    },
  );
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody(
    data.stream,
    200,
    headers: {
      'content-type': ['application/json'],
      if (declared) 'content-length': ['2000001'],
    },
  );
  @override
  void close({bool force = false}) {}
}

class StalledAdapter implements HttpClientAdapter {
  bool closed = false;
  final listening = Completer<void>();
  late final stream = StreamController<Uint8List>(
    onListen: () => listening.complete(),
    onCancel: () {
      closed = true;
    },
  );
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? request,
    Future<void>? cancel,
  ) async => ResponseBody(
    stream.stream,
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('a stalled route response times out and closes its stream', () async {
    final adapter = StalledAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
      routeStreamTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(() async {
      geo.dispose();
      await adapter.stream.close();
    });
    await expectLater(
      geo.route(
        const LatLng(14, 121),
        const LatLng(14.01, 121.01),
        NavigationProfile.drive,
        CancelToken(),
      ),
      throwsA(isA<ProviderFailure>()),
    );
    expect(adapter.closed, isTrue);
  });
  test('stopping navigation cancels the provider response stream', () async {
    final adapter = StalledAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
    );
    addTearDown(() async {
      geo.dispose();
      await adapter.stream.close();
    });
    final token = CancelToken();
    final result = expectLater(
      geo.route(
        const LatLng(14, 121),
        const LatLng(14.01, 121.01),
        NavigationProfile.drive,
        token,
      ),
      throwsA(
        isA<DioException>().having(
          CancelToken.isCancel,
          'is cancellation',
          isTrue,
        ),
      ),
    );
    await adapter.listening.future.timeout(const Duration(seconds: 2));
    token.cancel();
    await result;
    expect(adapter.closed, isTrue);
  });
  for (final declared in [true, false]) {
    test(
      'oversized ${declared ? 'declared' : 'streamed'} route responses are closed and rejected',
      () async {
        final adapter = OversizedAdapter(declared: declared);
        final dio = Dio()..httpClientAdapter = adapter;
        final geo = GeoapifyClient(
          'synthetic-key',
          client: dio,
          scheduler: Immediate(),
        );
        final token = CancelToken();
        addTearDown(geo.dispose);
        await expectLater(
          geo.route(
            const LatLng(14, 121),
            const LatLng(14.01, 121.01),
            NavigationProfile.drive,
            token,
          ),
          throwsA(isA<ProviderFailure>()),
        );
        expect(adapter.closed, isTrue);
        expect(token.isCancelled, isFalse);
      },
    );
  }
  test(
    'Geoapify sends client key and lat/lon waypoints with no Bagoo bearer',
    () async {
      final adapter = Adapter(), dio = Dio();
      dio.httpClientAdapter = adapter;
      final geo = GeoapifyClient(
        'synthetic-key',
        client: dio,
        scheduler: Immediate(),
      );
      await geo.route(
        const LatLng(14, 121),
        const LatLng(14.01, 121.01),
        NavigationProfile.motorcycle,
        CancelToken(),
      );
      final req = adapter.calls.single;
      expect(req.uri.host, 'api.geoapify.com');
      expect(req.headers.containsKey('Authorization'), false);
      expect(req.queryParameters['mode'], 'motorcycle');
      expect(req.queryParameters['waypoints'], '14.0,121.0|14.01,121.01');
      expect(req.followRedirects, false);
      geo.dispose();
    },
  );
  test(
    'rejects road lines that miss the requested stop or contain gaps',
    () async {
      final adapter = Adapter(), dio = Dio()..httpClientAdapter = adapter;
      final client = GeoapifyClient(
        'synthetic-key',
        client: dio,
        scheduler: Immediate(),
      );
      addTearDown(client.dispose);
      Future<RoadRoute> route() => client.route(
        const LatLng(14, 121),
        const LatLng(14.01, 121.01),
        NavigationProfile.drive,
        CancelToken(),
      );
      await expectLater(route(), completes);
      adapter.response = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'legs': [
                {
                  'steps': [{}],
                },
              ],
            },
            'geometry': {
              'type': 'MultiLineString',
              'coordinates': [
                [
                  [121.0, 14.0],
                  [121.001, 14.001],
                ],
                [
                  [121.009, 14.009],
                  [121.01, 14.01],
                ],
              ],
            },
          },
        ],
      };
      await expectLater(route(), throwsA(isA<ProviderFailure>()));
      adapter.response = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'legs': [
                {
                  'steps': [{}],
                },
              ],
            },
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [121.0, 14.0],
                [121.4, 14.4],
              ],
            },
          },
        ],
      };
      await expectLater(route(), throwsA(isA<ProviderFailure>()));
      adapter.response = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [121.0, 14.0],
                [121.01, 14.01],
              ],
            },
          },
        ],
      };
      await expectLater(route(), throwsA(isA<ProviderFailure>()));
    },
  );
  test(
    'missing key and exhausted quota prevent further network requests',
    () async {
      final adapter = Adapter(), dio = Dio();
      dio.httpClientAdapter = adapter;
      var geo = GeoapifyClient('', client: dio, scheduler: Immediate());
      await expectLater(
        geo.route(
          const LatLng(14, 121),
          const LatLng(14.01, 121.01),
          NavigationProfile.drive,
          CancelToken(),
        ),
        throwsA(isA<ProviderFailure>()),
      );
      expect(adapter.calls, isEmpty);
      geo = GeoapifyClient(
        'synthetic-key',
        client: dio,
        scheduler: Immediate(),
      );
      adapter.status = 429;
      for (var i = 0; i < 2; i++) {
        await expectLater(
          geo.route(
            const LatLng(14, 121),
            const LatLng(14.01, 121.01),
            NavigationProfile.drive,
            CancelToken(),
          ),
          throwsA(isA<ProviderFailure>()),
        );
      }
      expect(adapter.calls.length, 1);
      expect(geo.failure, contains('quota'));
      geo.dispose();
    },
  );
  testWidgets(
    'provider scheduler keeps routes within four credits per rolling second',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now),
          started = <DateTime>[];
      final jobs = List.generate(
        5,
        (_) => scheduler.acquire(null).then((_) {
          started.add(tester.binding.clock.now());
          scheduler.release();
        }),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 75));
      }
      await Future.wait(jobs);
      expect(
        started[4].difference(started[0]).inMilliseconds,
        greaterThanOrEqualTo(1000),
      );
      final cancel = CancelToken()..cancel();
      await expectLater(
        scheduler.acquire(cancel),
        throwsA(isA<DioException>()),
      );
      scheduler.dispose();
    },
  );
}
