import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';
import 'map_tile_source.dart';

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
/// only Geoapify's client key to its fixed map/API hosts and follows no redirects.
class GeoapifyClient extends ChangeNotifier {
  GeoapifyClient(
    this.apiKey, {
    Dio? client,
    ProviderScheduler? scheduler,
    DateTime Function()? now,
  }) : _client = client ?? Dio(),
       now = now ?? DateTime.now,
       scheduler = scheduler ?? ProviderScheduler();
  final String apiKey;
  final Dio _client;
  final ProviderScheduler scheduler;
  final DateTime Function() now;
  final _tiles = <String, Uint8List>{};
  final _tileFailures = <String, ({String message, CancelToken? cancel})>{};
  final _inflight = <String, _TileRequest>{};
  DateTime? _blockedUntil, _retryUntil;
  Timer? _cooldownTimer, _retryTimer;
  bool _notificationQueued = false;
  int tileRevision = 0;
  String? failure;
  bool _disposed = false;
  bool get configured => apiKey.trim().isNotEmpty;
  bool get loadingTiles => _inflight.isNotEmpty;
  bool get coolingDown => _blockedUntil?.isAfter(now()) == true;
  bool get canRetryTiles =>
      configured &&
      !_disposed &&
      failure != null &&
      !coolingDown &&
      _retryUntil?.isAfter(now()) != true;
  void _notify() {
    if (_disposed || _notificationQueued) return;
    _notificationQueued = true;
    scheduleMicrotask(() {
      _notificationQueued = false;
      if (!_disposed) notifyListeners();
    });
  }

  void _report(String? value) {
    if (failure == value) return;
    failure = value;
    _notify();
  }

  bool retryTiles() {
    if (!canRetryTiles) return false;
    _retryUntil = now().add(const Duration(seconds: 30));
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      _retryUntil = null;
      _notify();
    });
    tileRevision++;
    _notify();
    return true;
  }

  void _forgetCancelledTileFailures() {
    final previous = _tileFailures.length;
    _tileFailures.removeWhere(
      (_, failure) => failure.cancel?.isCancelled == true,
    );
    if (previous != _tileFailures.length && !coolingDown) {
      _report(_tileFailures.values.lastOrNull?.message);
    }
  }

  void tileDecodeFailed(
    int z,
    int x,
    int y, {
    CancelToken? cancel,
    MapTileSource source = const MapTileSource(),
  }) {
    final path = source.path(z, x, y);
    _tiles.remove(path);
    _tileFailures[path] = (
      message:
          'Map tiles could not be displayed. Retry or use the task address.',
      cancel: cancel,
    );
    while (_tileFailures.length > 128) {
      _tileFailures.remove(_tileFailures.keys.first);
    }
    _report(_tileFailures[path]!.message);
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
    if (coolingDown) {
      throw ProviderFailure(failure ?? 'Map provider is cooling down.');
    }
    await scheduler.acquire(cancel);
    if (_disposed) throw const ProviderFailure('Map provider stopped.');
    if (coolingDown) {
      throw ProviderFailure(failure ?? 'Map provider is cooling down.');
    }
    try {
      _client.options.connectTimeout ??= const Duration(seconds: 20);
      final response = await _client.get(
        'https://${path.startsWith('/v1/tile/') ? 'maps.geoapify.com' : 'api.geoapify.com'}$path',
        queryParameters: {...query, 'apiKey': apiKey},
        cancelToken: cancel,
        options: Options(
          responseType: responseType,
          followRedirects: false,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Accept': responseType == ResponseType.bytes
                ? 'image/png'
                : 'application/json',
          },
        ),
      );
      // Never include provider URLs or client keys in user-visible exceptions.
      if (_disposed) throw const ProviderFailure('Map provider stopped.');
      if (cancel?.isCancelled == true) throw cancel!.cancelError!;
      if (path.startsWith('/v1/tile/')) _tileFailures.remove(path);
      _forgetCancelledTileFailures();
      if (!coolingDown) _report(_tileFailures.values.lastOrNull?.message);
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
        final duration = Duration(
          seconds: (retry ?? (status == 429 ? 60 : 300)).clamp(1, 86400),
        );
        _blockedUntil = now().add(duration);
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer(duration, () {
          _blockedUntil = null;
          _notify();
        });
      }
      if (path.startsWith('/v1/tile/')) {
        _tileFailures[path] = (message: message, cancel: cancel);
        while (_tileFailures.length > 128) {
          _tileFailures.remove(_tileFailures.keys.first);
        }
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

  Future<Uint8List> tile(
    int z,
    int x,
    int y, {
    CancelToken? cancel,
    MapTileSource source = const MapTileSource(),
  }) async {
    _forgetCancelledTileFailures();
    if (cancel?.isCancelled == true) throw cancel!.cancelError!;
    final path = source.path(z, x, y);
    final cached = _tiles.remove(path);
    if (cached != null) {
      _tiles[path] = cached;
      return cached;
    }
    final active = _inflight[path];
    if (active != null && !active.cancel.isCancelled) {
      final bytes = await active.future;
      if (cancel?.isCancelled == true) throw cancel!.cancelError!;
      return bytes;
    }
    final request = _TileRequest(cancel ?? CancelToken());
    request.future = () async {
      final response = await _get(
        path,
        responseType: ResponseType.bytes,
        cancel: request.cancel,
      );
      final bytes = Uint8List.fromList(List<int>.from(response.data as List));
      _tiles[path] = bytes;
      while (_tiles.length > 128) {
        _tiles.remove(_tiles.keys.first);
      }
      return bytes;
    }();
    _inflight[path] = request;
    _notify();
    try {
      return await request.future;
    } finally {
      if (identical(_inflight[path], request)) _inflight.remove(path);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldownTimer?.cancel();
    _retryTimer?.cancel();
    for (final request in _inflight.values) {
      request.cancel.cancel();
    }
    _client.close(force: true);
    _tiles.clear();
    _tileFailures.clear();
    _inflight.clear();
    super.dispose();
  }
}

class _TileRequest {
  _TileRequest(this.cancel);
  final CancelToken cancel;
  late final Future<Uint8List> future;
}
