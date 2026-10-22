import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_cache_io.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// The previous production policy, retained only for a controlled comparison.
class _LegacyQueue extends ProviderScheduler {
  Future<void> _tail = Future.value();
  DateTime? _last;
  @override
  Future<void> acquire(
    CancelToken? cancel, {
    ProviderRequestKind kind = ProviderRequestKind.route,
  }) {
    final job = _tail.then((_) async {
      final last = _last;
      if (last != null) {
        final delay =
            const Duration(milliseconds: 260) - DateTime.now().difference(last);
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      }
      _last = DateTime.now();
    });
    _tail = job;
    return job;
  }
}

class _Tiles implements HttpClientAdapter {
  _Tiles(this.bytes, {this.offline = false});
  final Uint8List bytes;
  final bool offline;
  int calls = 0, transferred = 0, active = 0, peak = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    calls++;
    active++;
    if (active > peak) peak = active;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    active--;
    transferred += offline ? 0 : bytes.length;
    return ResponseBody.fromBytes(
      bytes,
      offline ? 503 : 200,
      headers: {
        'content-type': ['image/png'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'controlled cold, warm and process-restart map loading comparison',
    () async {
      const artwork = String.fromEnvironment('MAP_BENCHMARK_ARTWORK');
      final bytes = artwork.isEmpty
          ? TileProvider.transparentImage
          : await File(artwork).readAsBytes();
      final root = Directory('build/map-loading');
      await root.create(recursive: true);
      final directory = Directory('${root.path}/benchmark-cache');
      const source = MapTileSource(style: MapTileStyle.dark, retina: true);
      final resultsFile = File('${root.path}/benchmark.json');
      final restart = const bool.fromEnvironment('MAP_BENCHMARK_RESTART');
      final results = restart
          ? jsonDecode(await resultsFile.readAsString()) as Map<String, dynamic>
          : <String, dynamic>{
              'kind': 'controlled software comparison; not live network or phone timing',
              'tiles': 20,
              'latency_ms': 200,
              'tile_bytes': bytes.length,
              'initial_process': pid,
            };
      if (!restart && await directory.exists()) {
        await directory.delete(recursive: true);
      }

      Future<Map<String, Object>> load(
        GeoapifyClient client,
        _Tiles adapter,
      ) async {
        final watch = Stopwatch()..start();
        final before = adapter.calls, byteBefore = adapter.transferred;
        await Future.wait(
          List.generate(
            20,
            (i) =>
                client.tile(15, 27395 + i % 5, 15038 + i ~/ 5, source: source),
          ),
        );
        watch.stop();
        return {
          'elapsed_ms': watch.elapsedMicroseconds / 1000,
          'requests': adapter.calls - before,
          'bytes': adapter.transferred - byteBefore,
          'peak_active': adapter.peak,
        };
      }

      GeoapifyClient client(
        _Tiles adapter,
        ProviderScheduler scheduler, {
        FileMapTileCache? cache,
      }) {
        final geo = GeoapifyClient(
          'synthetic-key',
          client: Dio()..httpClientAdapter = adapter,
          scheduler: scheduler,
          tileCache: cache,
        );
        addTearDown(geo.dispose);
        return geo;
      }

      if (!restart) {
        final legacy = _Tiles(bytes);
        results['legacy_cold'] = await load(
          client(legacy, _LegacyQueue()),
          legacy,
        );
        final current = _Tiles(bytes),
            cache = FileMapTileCache(directory: () async => directory);
        final geo = client(current, ProviderScheduler(), cache: cache);
        results['current_cold'] = await load(geo, current);
        results['memory_warm'] = await load(geo, current);
        // Queue a read after every asynchronous write has been accepted.
        for (var i = 0; i < 20; i++) {
          expect(
            await cache.read(source.path(15, 27395 + i % 5, 15038 + i ~/ 5)),
            isNotNull,
          );
        }
        final offline = _Tiles(bytes, offline: true);
        results['disk_warm'] = await load(
          client(
            offline,
            ProviderScheduler(),
            cache: FileMapTileCache(directory: () async => directory),
          ),
          offline,
        );
        expect(offline.calls, 0);
        expect(current.calls, 20);
        expect(current.peak, lessThanOrEqualTo(6));
      } else {
        final offline = _Tiles(bytes, offline: true);
        results['restart_process'] = pid;
        results['process_restart_warm'] = await load(
          client(
            offline,
            ProviderScheduler(),
            cache: FileMapTileCache(directory: () async => directory),
          ),
          offline,
        );
        expect(offline.calls, 0);
        expect(pid, isNot(results['initial_process']));
      }
      await resultsFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(results),
      );
    },
    skip: !const bool.fromEnvironment('MAP_BENCHMARK'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
