import 'dart:async';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/geoapify_tiles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'geoapify_client_test.dart' show Immediate;

class TileAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int status = 200;
  final replies = <Completer<ResponseBody>>[];
  void Function()? onRequest;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    onRequest?.call();
    if (replies.isNotEmpty) return replies.removeAt(0).future;
    return ResponseBody.fromBytes(
      TileProvider.transparentImage,
      status,
      headers: {
        'content-type': ['image/png'],
        'retry-after': ['2'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'corrupt tile bytes are evicted even while a sibling tile has failed',
    () async {
      final adapter = TileAdapter()..status = 500, dio = Dio();
      dio.httpClientAdapter = adapter;
      final geo = GeoapifyClient(
        'synthetic-key',
        client: dio,
        scheduler: Immediate(),
      );
      addTearDown(geo.dispose);
      await expectLater(geo.tile(15, 21, 30), throwsA(isA<ProviderFailure>()));
      adapter.status = 200;
      final corrupt = Completer<ResponseBody>()
        ..complete(ResponseBody.fromBytes([0, 1, 2], 200));
      adapter.replies.add(corrupt);
      final tiles = GeoapifyTiles(geo);
      addTearDown(tiles.suspend);
      final cancel = Completer<void>();
      final image = tiles.getImageWithCancelLoadingSupport(
        const TileCoordinates(20, 30, 15),
        TileLayer(),
        cancel.future,
      );
      final decoded = Completer<void>();
      final stream = image.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!decoded.isCompleted) decoded.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!decoded.isCompleted) decoded.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      await decoded.future;
      stream.removeListener(listener);
      await geo.tile(15, 20, 30);
      expect(adapter.calls, hasLength(3));
      expect(geo.failure, isNotNull);
      cancel.complete();
    },
  );

  test('failures from a cancelled old viewport do not latch onto healthy new tiles', () async {
    final adapter = TileAdapter()..status = 500, dio = Dio();
    dio.httpClientAdapter = adapter;
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
    );
    addTearDown(geo.dispose);
    final cancel = CancelToken();
    await expectLater(
      geo.tile(15, 20, 30, cancel: cancel),
      throwsA(isA<ProviderFailure>()),
    );
    cancel.cancel();
    adapter.status = 200;
    await geo.tile(15, 21, 30);
    expect(geo.failure, isNull);
  });
  test('a healthy sibling tile does not hide a failed tile until that tile recovers', () async {
    final adapter = TileAdapter()..status = 500, dio = Dio();
    dio.httpClientAdapter = adapter;
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
    );
    addTearDown(geo.dispose);
    await expectLater(geo.tile(15, 20, 30), throwsA(isA<ProviderFailure>()));
    adapter.status = 200;
    await geo.tile(15, 21, 30);
    expect(geo.failure, isNotNull);
    expect(geo.canRetryTiles, isTrue);
    await geo.tile(15, 20, 30);
    expect(geo.failure, isNull);
  });
  test(
    'warm tiles avoid network and loading is cleared after completion',
    () async {
      final adapter = TileAdapter(), dio = Dio();
      dio.httpClientAdapter = adapter;
      final geo = GeoapifyClient(
        'synthetic-key',
        client: dio,
        scheduler: Immediate(),
      );
      addTearDown(geo.dispose);
      final first = await geo.tile(15, 20, 30);
      final warm = await geo.tile(15, 20, 30);
      expect(warm, same(first));
      expect(adapter.calls, hasLength(1));
      expect(adapter.calls.single.connectTimeout, const Duration(seconds: 20));
      expect(
        adapter.calls.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(geo.loadingTiles, isFalse);
    },
  );

  test('a cancelled old tile cannot poison a new visible request for the same coordinates', () async {
    final adapter = TileAdapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    final old = Completer<ResponseBody>(), fresh = Completer<ResponseBody>();
    adapter.replies.addAll([old, fresh]);
    final firstStarted = Completer<void>(), secondStarted = Completer<void>();
    adapter.onRequest = () {
      if (adapter.calls.length == 1) firstStarted.complete();
      if (adapter.calls.length == 2) secondStarted.complete();
    };
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
    );
    addTearDown(geo.dispose);
    final cancel = CancelToken();
    final first = geo.tile(15, 20, 30, cancel: cancel);
    final rejected = expectLater(first, throwsA(isA<DioException>()));
    await firstStarted.future;
    cancel.cancel();
    final second = geo.tile(15, 20, 30, cancel: CancelToken());
    await secondStarted.future;
    expect(adapter.calls, hasLength(2));
    await rejected;
    expect(geo.loadingTiles, isTrue);
    fresh.complete(ResponseBody.fromBytes(TileProvider.transparentImage, 200));
    expect(await second, isNotEmpty);
    old.complete(ResponseBody.fromBytes(TileProvider.transparentImage, 200));
    expect(geo.failure, isNull);
    expect(geo.loadingTiles, isFalse);
  });

  test('quota cooldown enables one explicit tile retry without an automatic request loop', () async {
    final adapter = TileAdapter()..status = 429, dio = Dio();
    dio.httpClientAdapter = adapter;
    final geo = GeoapifyClient(
      'synthetic-key',
      client: dio,
      scheduler: Immediate(),
    );
    addTearDown(geo.dispose);
    await expectLater(geo.tile(15, 20, 30), throwsA(isA<ProviderFailure>()));
    expect(geo.canRetryTiles, isFalse);
    expect(geo.retryTiles(), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    expect(geo.canRetryTiles, isTrue);
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.uri.host, 'maps.geoapify.com');
    expect(adapter.calls.single.headers['Accept'], 'image/png');
    expect(geo.retryTiles(), isTrue);
    expect(geo.retryTiles(), isFalse);
    expect(geo.tileRevision, 1);
    adapter.status = 200;
    await geo.tile(15, 20, 30);
    expect(adapter.calls, hasLength(2));
    expect(geo.failure, isNull);
  });

  test(
    'decoded-image keys isolate old view scopes and failed-tile retries',
    () async {
      final geo = GeoapifyClient('synthetic-key');
      addTearDown(geo.dispose);
      final a = GeoapifyTiles(geo), b = GeoapifyTiles(geo);
      final layer = TileLayer();
      const coordinate = TileCoordinates(20, 30, 15);
      final cancelA = Completer<void>(), cancelB = Completer<void>();
      final old = a.getImageWithCancelLoadingSupport(
        coordinate,
        layer,
        cancelA.future,
      );
      final other = b.getImageWithCancelLoadingSupport(
        coordinate,
        layer,
        cancelB.future,
      );
      expect(old, isNot(equals(other)));
      geo.failure = 'Synthetic tile failure';
      expect(geo.retryTiles(), isTrue);
      final retry = a.getImageWithCancelLoadingSupport(
        coordinate,
        layer,
        cancelA.future,
      );
      expect(old, isNot(equals(retry)));
      a.suspend();
      b.suspend();
      cancelA.complete();
      cancelB.complete();
      expect(old.toString(), isNot(contains('synthetic-key')));
    },
  );
}
