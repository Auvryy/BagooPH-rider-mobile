import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';

class ProviderFailure implements Exception {
  const ProviderFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A single queue covers tiles and routes, capped conservatively below 4/s.
class ProviderScheduler {
  Future<void> _tail = Future.value();
  DateTime? _last;
  Future<void> acquire(CancelToken? cancel) {
    final job = _tail.then((_) async {
      if (cancel?.isCancelled == true) {
        throw cancel!.cancelError!;
      }
      if (_last != null) {
        final wait =
            const Duration(milliseconds: 260) -
            DateTime.now().difference(_last!);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      if (cancel?.isCancelled == true) {
        throw cancel!.cancelError!;
      }
      _last = DateTime.now();
    });
    _tail = job.then((_) {}, onError: (Object _) {});
    return job;
  }
}

/// This client has no dependency on RiderSessionApi or token storage. It sends
/// only Geoapify's client key to the fixed provider host and follows no redirects.
class GeoapifyClient extends ChangeNotifier {
  GeoapifyClient(this.apiKey, {Dio? client, ProviderScheduler? scheduler})
    : _client = client ?? Dio(),
      scheduler = scheduler ?? ProviderScheduler();
  final String apiKey;
  final Dio _client;
  final ProviderScheduler scheduler;
  final _tiles = <String, Uint8List>{};
  final _inflight = <String, Future<Uint8List>>{};
  DateTime? _blockedUntil;
  String? failure;
  bool _disposed = false;
  bool get configured => apiKey.trim().isNotEmpty;
  void _report(String? value) {
    failure = value;
    if (!_disposed) notifyListeners();
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic> query = const {},
    ResponseType responseType = ResponseType.json,
    CancelToken? cancel,
  }) async {
    if (!configured) {
      throw const ProviderFailure(
        'Map and road routing need a Geoapify client key.',
      );
    }
    if (_blockedUntil?.isAfter(DateTime.now()) == true) {
      throw ProviderFailure(failure ?? 'Map provider is cooling down.');
    }
    await scheduler.acquire(cancel);
    if (_disposed) throw const ProviderFailure('Map provider stopped.');
    if (_blockedUntil?.isAfter(DateTime.now()) == true) {
      throw ProviderFailure(failure ?? 'Map provider is cooling down.');
    }
    try {
      final response = await _client.get(
        'https://api.geoapify.com$path',
        queryParameters: {...query, 'apiKey': apiKey},
        cancelToken: cancel,
        options: Options(
          responseType: responseType,
          followRedirects: false,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      );
      // Never include provider URLs or client keys in user-visible exceptions.
      if (_blockedUntil?.isAfter(DateTime.now()) != true) _report(null);
      return response;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      final status = error.response?.statusCode;
      final retry = int.tryParse(
        error.response?.headers.value('retry-after') ?? '',
      );
      final message = status == 429
          ? 'Map provider quota or rate limit reached. Retry later.'
          : status == 401 || status == 403
          ? 'The map provider key or quota needs checking.'
          : 'Could not load the map or road route. Check your connection.';
      if (status == 429 || status == 401 || status == 403) {
        _blockedUntil = DateTime.now().add(
          Duration(
            seconds: (retry ?? (status == 429 ? 60 : 300)).clamp(1, 86400),
          ),
        );
      }
      _report(message);
      throw ProviderFailure(message);
    }
  }

  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel,
  ) async {
    if (!validPoint(origin) || !validPoint(target)) {
      throw const ProviderFailure(
        'Valid origin and stop coordinates are required.',
      );
    }
    try {
      return RoadRoute.geoJson(
        (await _get(
          '/v1/routing',
          query: {
            'waypoints':
                '${origin.latitude},${origin.longitude}|${target.latitude},${target.longitude}',
            'mode': profile.mode,
            'format': 'geojson',
          },
          cancel: cancel,
        )).data,
      );
    } on FormatException {
      throw const ProviderFailure('No valid road route was returned.');
    }
  }

  Future<Uint8List> tile(int z, int x, int y, {CancelToken? cancel}) async {
    final path = '/v1/tile/positron/$z/$x/$y.png';
    final cached = _tiles.remove(path);
    if (cached != null) {
      _tiles[path] = cached;
      return cached;
    }
    final active = _inflight[path];
    if (active != null) return active;
    final future = () async {
      final response = await _get(
        path,
        responseType: ResponseType.bytes,
        cancel: cancel,
      );
      final bytes = Uint8List.fromList(List<int>.from(response.data as List));
      _tiles[path] = bytes;
      while (_tiles.length > 128) {
        _tiles.remove(_tiles.keys.first);
      }
      return bytes;
    }();
    _inflight[path] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(path);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close(force: true);
    _tiles.clear();
    super.dispose();
  }
}
