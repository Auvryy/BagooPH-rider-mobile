import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' show CachedMapTileMetadata;
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';
import 'road_routing.dart';
export 'road_routing.dart';
import 'map_tile_source.dart';
import 'map_tile_cache.dart';
import 'provider_scheduler.dart';

export 'provider_scheduler.dart';

/// This client has no dependency on RiderSessionApi or token storage. Tile
/// requests identify the requested map tiles; route requests also send the
/// origin and stop coordinates to Geoapify with the public client key. Requests
/// use fixed map/API hosts and follow no redirects.
class GeoapifyClient extends ChangeNotifier implements RoadRoutingClient {
  static const _maxRouteBytes = 2000000;
  GeoapifyClient(
    this.apiKey, {
    Dio? client,
    ProviderScheduler? scheduler,
    this.tileCache,
    this.routeStreamTimeout = const Duration(seconds: 20),
    DateTime Function()? now,
  }) : _client = client ?? Dio(),
       now = now ?? DateTime.now,
       scheduler = scheduler ?? ProviderScheduler();
  final String apiKey;
  final Dio _client;
  final ProviderScheduler scheduler;
  final MapTileCache? tileCache;
  final Duration routeStreamTimeout;
  final DateTime Function() now;
  final _tiles = <String, CachedTile>{};
  final _tileFailures = <String, ({String message, CancelToken? cancel})>{};
  final _inflight = <String, _TileRequest>{};
  DateTime? _blockedUntil, _retryUntil;
  Timer? _cooldownTimer, _retryTimer;
  bool _notificationQueued = false;
  int tileRevision = 0;
  String? failure;
  bool _disposed = false;
  @override
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
    unawaited(_removeCachedTile(path));
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
    await scheduler.acquire(
      cancel,
      kind: path.startsWith('/v1/tile/')
          ? ProviderRequestKind.tile
          : ProviderRequestKind.route,
    );
    try {
      if (_disposed) throw const ProviderFailure('Map provider stopped.');
      if (coolingDown) {
        throw ProviderFailure(failure ?? 'Map provider is cooling down.');
      }
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
      if (responseType == ResponseType.stream) {
        final body = response.data;
        if (body is! ResponseBody) {
          throw const FormatException('Route response is unavailable.');
        }
        final chunks = StreamIterator<Uint8List>(body.stream);
        var complete = false;
        try {
          final length = int.tryParse(
            response.headers.value('content-length') ?? '',
          );
          if (length != null && length > _maxRouteBytes) {
            throw const FormatException('Route response is too large.');
          }
          final bytes = BytesBuilder(copy: false);
          var total = 0;
          final elapsed = Stopwatch()..start();
          while (true) {
            final remaining = routeStreamTimeout - elapsed.elapsed;
            if (remaining <= Duration.zero) {
              throw TimeoutException('Route response timed out.');
            }
            if (!await chunks.moveNext().timeout(remaining)) break;
            final chunk = chunks.current;
            if (_disposed) throw const ProviderFailure('Map provider stopped.');
            if (cancel?.isCancelled == true) throw cancel!.cancelError!;
            total += chunk.length;
            if (total > _maxRouteBytes) {
              throw const FormatException('Route response is too large.');
            }
            bytes.add(chunk);
          }
          response.data = jsonDecode(utf8.decode(bytes.takeBytes()));
          complete = true;
        } on TimeoutException {
          throw const FormatException('Route response timed out.');
        } finally {
          if (!complete && cancel != null && !cancel.isCancelled) {
            cancel.cancel('Route response rejected.');
          }
          await chunks.cancel();
        }
      }
      if (path.startsWith('/v1/tile/')) _tileFailures.remove(path);
      _forgetCancelledTileFailures();
      if (!coolingDown) _report(_tileFailures.values.lastOrNull?.message);
      return response;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      if (responseType == ResponseType.stream &&
          cancel != null &&
          !cancel.isCancelled) {
        cancel.cancel('Route request failed.');
      }
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
        scheduler.rejectPending(ProviderFailure(message));
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
    } finally {
      scheduler.release();
    }
  }

  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel, {
    bool prioritizeHighways = true,
  }) async {
    if (!validPoint(origin) || !validPoint(target)) {
      throw const ProviderFailure(
        'Valid origin and stop coordinates are required.',
      );
    }
    final requestCancel = CancelToken();
    unawaited(
      cancel.whenCancel.then((_) {
        if (!requestCancel.isCancelled) {
          requestCancel.cancel('Navigation stopped.');
        }
      }),
    );
    if (cancel.isCancelled) requestCancel.cancel('Navigation stopped.');
    try {
      final data = (await _get(
        '/v1/routing',
        query: {
          'waypoints':
              '${origin.latitude},${origin.longitude}|${target.latitude},${target.longitude}',
          'mode': profile.mode,
          'format': 'geojson',
          'avoid': 'ferries',
          'details': 'route_details',
          if (prioritizeHighways) 'highways': 'prefer',
        },
        responseType: ResponseType.stream,
        cancel: requestCancel,
      )).data;
      if (data is! Map ||
          data['features'] is! List ||
          (data['features'] as List).isEmpty) {
        throw const FormatException('No road route was returned.');
      }
      final feature = (data['features'] as List).first;
      final properties = feature is Map ? feature['properties'] : null;
      final legs = properties is Map ? properties['legs'] : null;
      if (feature is! Map ||
          feature['type'] != 'Feature' ||
          legs is! List ||
          legs.isEmpty ||
          legs.any(
            (leg) =>
                leg is! Map ||
                leg['steps'] is! List ||
                (leg['steps'] as List).isEmpty,
          )) {
        throw const FormatException('Road route details are unavailable.');
      }
      final route = RoadRoute.geoJson(data);
      route.validateEndpoints(origin, target);
      return route;
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
    if (_disposed) throw const ProviderFailure('Map provider stopped.');
    if (!configured) {
      throw const ProviderFailure(
        'Map and road routing need a Geoapify client key.',
      );
    }
    final path = source.path(z, x, y);
    final cached = _tiles.remove(path);
    if (cached != null && cached.expiresAt.isAfter(now())) {
      _tiles[path] = cached;
      return cached.bytes;
    }
    final active = _inflight[path];
    if (active != null && !active.cancel.isCancelled) {
      final bytes = await active.future;
      if (cancel?.isCancelled == true) throw cancel!.cancelError!;
      return bytes;
    }
    final request = _TileRequest(cancel ?? CancelToken());
    request.future = () async {
      final stored = await _readCachedTile(path);
      if (_disposed) throw const ProviderFailure('Map provider stopped.');
      if (request.cancel.isCancelled) throw request.cancel.cancelError!;
      if (stored != null && stored.expiresAt.isAfter(now())) {
        _rememberTile(path, stored);
        _tileFailures.remove(path);
        if (!coolingDown) _report(_tileFailures.values.lastOrNull?.message);
        return stored.bytes;
      }
      final response = await _get(
        path,
        responseType: ResponseType.bytes,
        cancel: request.cancel,
      );
      final bytes = Uint8List.fromList(List<int>.from(response.data as List));
      final expiresAt = _tileExpiry(response.headers);
      if (expiresAt != null) {
        final tile = CachedTile(bytes, expiresAt);
        _rememberTile(path, tile);
        // Disk writes never hold up the first map paint.
        unawaited(_writeCachedTile(path, tile));
      } else {
        unawaited(_removeCachedTile(path));
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

  void _rememberTile(String path, CachedTile tile) {
    _tiles[path] = tile;
    while (_tiles.length > 128) {
      _tiles.remove(_tiles.keys.first);
    }
  }

  DateTime? _tileExpiry(Headers headers) {
    final control = (headers.value('cache-control') ?? '').toLowerCase();
    if (RegExp(r'(?:^|,)\s*(?:no-store|no-cache)\b').hasMatch(control)) {
      return null;
    }
    if (headers.value('date') != null || headers.value('expires') != null) {
      try {
        final expires = CachedMapTileMetadata.fromHttpHeaders({
          for (final entry in headers.map.entries)
            entry.key.toLowerCase(): entry.value.join(', '),
          if (control.isEmpty && headers.value('expires') != null)
            'cache-control': 'public',
        }).staleAt;
        if (!expires.isAfter(now())) return null;
        final limit = now().add(const Duration(days: 30));
        return expires.isAfter(limit) ? limit : expires;
      } catch (_) {
        // Malformed freshness headers must not turn into long-lived cache hits.
        return null;
      }
    }
    final maxAge = RegExp(r'(?:^|,)\s*max-age\s*=\s*(\d+)').firstMatch(control);
    final seconds = maxAge == null ? 7 * 86400 : int.tryParse(maxAge[1]!) ?? 0;
    final age = int.tryParse(headers.value('age') ?? '') ?? 0;
    final remaining = (seconds - age).clamp(0, 30 * 86400);
    return remaining == 0 ? null : now().add(Duration(seconds: remaining));
  }

  Future<CachedTile?> _readCachedTile(String path) async {
    try {
      return await tileCache?.read(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedTile(String path, CachedTile tile) async {
    try {
      await tileCache?.write(path, tile);
    } catch (_) {
      /* Network still works. */
    }
  }

  Future<void> _removeCachedTile(String path) async {
    try {
      await tileCache?.remove(path);
    } catch (_) {
      /* Network still works. */
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
    scheduler.dispose();
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
