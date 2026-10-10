import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/geoapify_client.dart';

class GeoapifyTiles extends TileProvider {
  GeoapifyTiles(this.client);
  final GeoapifyClient client;
  @override
  bool get supportsCancelLoading => true;
  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    final cancel = CancelToken();
    cancelLoading.then((_) => cancel.cancel());
    return _TileImage(
      client,
      coordinates.z,
      coordinates.x,
      coordinates.y,
      cancel,
    );
  }
}

class _TileImage extends ImageProvider<_TileImage> {
  const _TileImage(this.client, this.z, this.x, this.y, this.cancel);
  final GeoapifyClient client;
  final int z, x, y;
  final CancelToken cancel;
  @override
  Future<_TileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(_TileImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: 1,
        debugLabel: 'Geoapify map tile',
      );
  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    try {
      return await decode(
        await ui.ImmutableBuffer.fromUint8List(
          await client.tile(z, x, y, cancel: cancel),
        ),
      );
    } catch (_) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(this));
      // Blank tiles preserve truthful address-first dashboard behavior. The
      // provider's visible failure message explains missing map data.
      return await decode(
        await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _TileImage &&
      identical(client, other.client) &&
      z == other.z &&
      x == other.x &&
      y == other.y;
  @override
  int get hashCode => Object.hash(client, z, x, y);
  @override
  String toString() => 'Geoapify map tile';
}
