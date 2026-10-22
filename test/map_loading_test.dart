import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_cache.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_cache_io.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'geoapify_client_test.dart' show Immediate;
import 'map_tile_lifecycle_test.dart' show TileAdapter;

class _Cache implements MapTileCache {
  final tiles = <String, CachedTile>{};
  bool broken = false;
  @override
  Future<CachedTile?> read(String path) async {
    if (broken) throw const FileSystemException('Unavailable');
    return tiles[path];
  }

  @override
  Future<void> write(String path, CachedTile tile) async {
    if (broken) throw const FileSystemException('Unavailable');
    tiles[path] = tile;
  }

  @override
  Future<void> remove(String path) async => tiles.remove(path);
}

class _DeferredCache extends _Cache {
  final result = Completer<CachedTile?>();
  @override
  Future<CachedTile?> read(String path) => result.future;
}

GeoapifyClient _client(
  TileAdapter adapter,
  MapTileCache cache, {
  DateTime Function()? now,
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = GeoapifyClient(
    'synthetic-key',
    client: dio,
    scheduler: Immediate(),
    tileCache: cache,
    now: now,
  );
  addTearDown(client.dispose);
  return client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cancellation during disk lookup rejects late bytes without network work',
    () async {
      final cache = _DeferredCache(),
          adapter = TileAdapter(),
          cancel = CancelToken();
      final client = _client(adapter, cache);
      final pending = client.tile(15, 20, 30, cancel: cancel);
      final rejected = expectLater(pending, throwsA(isA<DioException>()));
      cancel.cancel();
      cache.result.complete(
        CachedTile(
          TileProvider.transparentImage,
          DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await rejected;
      expect(adapter.calls, isEmpty);
      expect(client.loadingTiles, isFalse);
      expect(client.failure, isNull);
    },
  );

  testWidgets(
    'a quota denial immediately clears pending work and the queue recovers',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now);
      addTearDown(scheduler.dispose);
      await scheduler.acquire(null, kind: ProviderRequestKind.tile);
      final queued = expectLater(
        scheduler.acquire(null),
        throwsA(isA<ProviderFailure>()),
      );
      scheduler.rejectPending(const ProviderFailure('quota'));
      await queued;
      scheduler.release();
      var next = false;
      final ready = scheduler.acquire(null).then((_) => next = true);
      await tester.pump(const Duration(milliseconds: 75));
      await ready;
      expect(next, isTrue);
    },
  );

  test('fresh files survive a new cache and client, isolate style/density, and work offline', () async {
    final directory = await Directory.systemTemp.createTemp('rider-basemap-');
    addTearDown(() => directory.delete(recursive: true));
    final cache = FileMapTileCache(directory: () async => directory);
    final adapter = TileAdapter();
    final first = _client(adapter, cache);
    const sources = [
      MapTileSource(style: MapTileStyle.dark),
      MapTileSource(style: MapTileStyle.dark, retina: true),
      MapTileSource(style: MapTileStyle.bright),
    ];
    for (final source in sources) {
      await first.tile(15, 20, 30, source: source);
      expect(await cache.read(source.path(15, 20, 30)), isNotNull);
    }
    expect(adapter.calls, hasLength(3));
    final offline = TileAdapter()..status = 500;
    final second = _client(
      offline,
      FileMapTileCache(directory: () async => directory),
    );
    for (final source in sources) {
      expect(
        await second.tile(15, 20, 30, source: source),
        TileProvider.transparentImage,
      );
    }
    expect(offline.calls, isEmpty);
    final files = await directory.list().where((e) => e is File).toList();
    expect(files, hasLength(3));
    for (final file in files.cast<File>()) {
      expect(
        file.uri.pathSegments.last,
        matches(RegExp(r'^[a-f0-9]{64}\.tile$')),
      );
      expect(
        utf8.decode(await file.readAsBytes(), allowMalformed: true),
        isNot(contains('synthetic-key')),
      );
    }
  });

  test(
    'strict disk budget evicts oldest-used files and survives reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp('rider-basemap-');
      addTearDown(() => directory.delete(recursive: true));
      final size = TileProvider.transparentImage.length + 12;
      final cache = FileMapTileCache(
        directory: () async => directory,
        maxBytes: size * 2,
      );
      final tile = CachedTile(
        TileProvider.transparentImage,
        DateTime.now().add(const Duration(days: 1)),
      );
      await cache.write('a', tile);
      await cache.write('b', tile);
      await cache.read('a');
      await cache.write('c', tile);
      expect(await cache.read('a'), isNotNull);
      expect(await cache.read('b'), isNull);
      expect(await cache.read('c'), isNotNull);
      var bytes = 0;
      await for (final file in directory.list()) {
        bytes += (await file.stat()).size;
      }
      expect(bytes, lessThanOrEqualTo(size * 2));
      final reopened = FileMapTileCache(
        directory: () async => directory,
        maxBytes: size,
      );
      await reopened.read('c');
      bytes = 0;
      await for (final file in directory.list()) {
        bytes += (await file.stat()).size;
      }
      expect(bytes, lessThanOrEqualTo(size));
    },
  );

  test(
    'disk corruption and interrupted writes recover with network tiles',
    () async {
      final directory = await Directory.systemTemp.createTemp('rider-basemap-');
      addTearDown(() => directory.delete(recursive: true));
      final cache = FileMapTileCache(directory: () async => directory);
      final first = _client(TileAdapter(), cache);
      await first.tile(15, 20, 30);
      await cache.read(const MapTileSource().path(15, 20, 30));
      final file = (await directory.list().toList()).whereType<File>().single;
      await file.writeAsBytes([1, 2, 3]);
      await File('${directory.path}/interrupted.tmp').writeAsBytes([0]);
      final adapter = TileAdapter();
      final repaired = FileMapTileCache(directory: () async => directory);
      await _client(adapter, repaired).tile(15, 20, 30);
      expect(adapter.calls, hasLength(1));
      expect(
        (await repaired.read(const MapTileSource().path(15, 20, 30)))!.bytes,
        TileProvider.transparentImage,
      );
      expect(await File('${directory.path}/interrupted.tmp').exists(), isFalse);
    },
  );

  test(
    'cache filesystem errors do not block maps or latch a provider error',
    () async {
      final adapter = TileAdapter(), cache = _Cache()..broken = true;
      final client = _client(adapter, cache);
      expect(await client.tile(15, 20, 30), isNotEmpty);
      expect(adapter.calls, hasLength(1));
      expect(client.failure, isNull);
    },
  );

  test('slow cache initialization falls back instead of blocking map loading', () async {
    final ready = Completer<Directory>();
    final adapter = TileAdapter();
    final cache = FileMapTileCache(directory: () => ready.future);
    final client = _client(adapter, cache);
    await client.tile(15, 20, 30);
    expect(adapter.calls, hasLength(1));
    final directory = await Directory.systemTemp.createTemp('rider-basemap-');
    ready.complete(directory);
    await cache.remove('unused');
    // Let the original initialization settle before cleaning up its directory.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await directory.delete(recursive: true);
  });

  test(
    'expired memory and disk tiles are replaced with fresh provider bytes',
    () async {
      var time = DateTime.now();
      final cache = _Cache(), adapter = TileAdapter();
      final client = _client(adapter, cache, now: () => time);
      await client.tile(15, 20, 30);
      await Future<void>.delayed(Duration.zero);
      time = time.add(const Duration(days: 8));
      await client.tile(15, 20, 30);
      expect(adapter.calls, hasLength(2));
      expect(cache.tiles.values.single.expiresAt.isAfter(time), isTrue);
    },
  );

  for (final control in ['no-store', 'no-cache', 'max-age=0', 'max-age=20']) {
    test('respects cache-control $control and Age', () async {
      final adapter = TileAdapter(), cache = _Cache();
      adapter.replies.add(
        Completer<ResponseBody>()..complete(
          ResponseBody.fromBytes(
            TileProvider.transparentImage,
            200,
            headers: {
              'cache-control': [control],
              'age': ['25'],
            },
          ),
        ),
      );
      final client = _client(adapter, cache);
      await client.tile(15, 20, 30);
      await Future<void>.delayed(Duration.zero);
      expect(cache.tiles, isEmpty);
      await client.tile(15, 20, 30);
      expect(adapter.calls, hasLength(2));
    });
  }

  test(
    'fresh cache remains available during a provider quota cooldown',
    () async {
      final cache = _Cache(), adapter = TileAdapter();
      await _client(TileAdapter(), cache).tile(15, 20, 30);
      await Future<void>.delayed(Duration.zero);
      final client = _client(adapter, cache);
      adapter.status = 429;
      await expectLater(
        client.tile(15, 21, 30),
        throwsA(isA<ProviderFailure>()),
      );
      expect(await client.tile(15, 20, 30), isNotEmpty);
      expect(adapter.calls, hasLength(1));
      expect(client.coolingDown, isTrue);
      expect(client.failure, contains('quota'));
    },
  );

  test(
    'Date/Expires freshness is honored and expired responses are not cached',
    () async {
      final cache = _Cache(), adapter = TileAdapter();
      final time = DateTime.now().toUtc();
      for (final expires in [
        time.add(const Duration(hours: 1)),
        time.subtract(const Duration(hours: 1)),
      ]) {
        adapter.replies.add(
          Completer<ResponseBody>()..complete(
            ResponseBody.fromBytes(
              TileProvider.transparentImage,
              200,
              headers: {
                'expires': [HttpDate.format(expires)],
              },
            ),
          ),
        );
      }
      final client = _client(adapter, cache);
      await client.tile(15, 20, 30);
      await Future<void>.delayed(Duration.zero);
      expect(cache.tiles, hasLength(1));
      final ttl = cache.tiles.values.single.expiresAt.difference(time);
      expect(ttl.inMinutes, inInclusiveRange(59, 60));
      await client.tile(15, 21, 30);
      await Future<void>.delayed(Duration.zero);
      expect(cache.tiles, hasLength(1));
    },
  );

  test('image decode failure invalidates disk as well as memory', () async {
    final cache = _Cache(), adapter = TileAdapter();
    final client = _client(adapter, cache);
    await client.tile(15, 20, 30);
    await Future<void>.delayed(Duration.zero);
    expect(cache.tiles, isNotEmpty);
    client.tileDecodeFailed(15, 20, 30);
    await Future<void>.delayed(Duration.zero);
    expect(cache.tiles, isEmpty);
    await client.tile(15, 20, 30);
    expect(adapter.calls, hasLength(2));
    expect(client.failure, isNull);
  });

  testWidgets(
    'navigation jumps ahead of queued tiles and cancellation releases the queue',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now);
      addTearDown(scheduler.dispose);
      final order = <String>[];
      Future<void> request(
        String name,
        ProviderRequestKind kind, [
        CancelToken? cancel,
      ]) => scheduler.acquire(cancel, kind: kind).then((_) {
        order.add(name);
        scheduler.release();
      });
      final first = request('tile-1', ProviderRequestKind.tile);
      final second = request('tile-2', ProviderRequestKind.tile);
      final cancel = CancelToken();
      final rejected = expectLater(
        request('cancelled', ProviderRequestKind.tile, cancel),
        throwsA(isA<DioException>()),
      );
      final route = request('route', ProviderRequestKind.route);
      cancel.cancel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(order, ['tile-1', 'route']);
      await tester.pump(const Duration(milliseconds: 75));
      expect(order, ['tile-1', 'route', 'tile-2']);
      await Future.wait([first, second, route, rejected]);
    },
  );

  testWidgets(
    'mixed tile/route traffic stays within budget and faster tile starts',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now);
      addTearDown(scheduler.dispose);
      final starts = <({DateTime at, int units})>[];
      final jobs = List.generate(40, (i) {
        final kind = i % 9 == 0
            ? ProviderRequestKind.route
            : ProviderRequestKind.tile;
        return scheduler.acquire(null, kind: kind).then((_) {
          starts.add((
            at: tester.binding.clock.now(),
            units: kind == ProviderRequestKind.tile ? 1 : 4,
          ));
          scheduler.release();
        });
      });
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 75));
      }
      await Future.wait(jobs);
      expect(starts, hasLength(40));
      for (final start in starts) {
        final window = starts.where(
          (r) =>
              !r.at.isBefore(start.at) &&
              r.at.difference(start.at) < const Duration(seconds: 1),
        );
        expect(
          window.fold(0, (sum, r) => sum + r.units),
          lessThanOrEqualTo(16),
        );
      }
      final tiles = starts.where((r) => r.units == 1).toList();
      expect(
        tiles[19].at.difference(tiles.first.at),
        lessThan(const Duration(seconds: 3)),
      );
    },
  );

  testWidgets(
    'limits network concurrency and resumes when a slot is released',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now);
      final started = <int>[];
      final jobs = List.generate(
        8,
        (i) => scheduler
            .acquire(null, kind: ProviderRequestKind.tile)
            .then((_) => started.add(i)),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 75));
      }
      expect(started, hasLength(6));
      scheduler.release();
      await tester.pump();
      expect(started, hasLength(7));
      scheduler.release();
      await tester.pump(const Duration(milliseconds: 75));
      expect(started, hasLength(8));
      await Future.wait(jobs);
      scheduler.dispose();
    },
  );

  testWidgets(
    'disposing the queue rejects pending work and cancels its timer',
    (tester) async {
      final scheduler = ProviderScheduler(now: tester.binding.clock.now);
      await scheduler.acquire(null);
      final queued = expectLater(scheduler.acquire(null), throwsStateError);
      scheduler.dispose();
      await queued;
    },
  );
}
