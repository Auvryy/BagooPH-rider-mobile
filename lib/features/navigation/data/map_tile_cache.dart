import 'dart:typed_data';

import 'map_tile_cache_stub.dart'
    if (dart.library.io) 'map_tile_cache_io.dart'
    as platform;

class CachedTile {
  const CachedTile(this.bytes, this.expiresAt);
  final Uint8List bytes;
  final DateTime expiresAt;
}

/// Basemap images only. Keys contain style/density/XYZ, never credentials,
/// rider identities, GPS samples, task details or route geometry.
abstract interface class MapTileCache {
  Future<CachedTile?> read(String path);
  Future<void> write(String path, CachedTile tile);
  Future<void> remove(String path);
}

MapTileCache createMapTileCache() => platform.createCache();
