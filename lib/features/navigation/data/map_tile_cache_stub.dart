import 'map_tile_cache.dart';

MapTileCache createCache() => _NoTileCache();

class _NoTileCache implements MapTileCache {
  @override
  Future<CachedTile?> read(String path) async => null;
  @override
  Future<void> write(String path, CachedTile tile) async {}
  @override
  Future<void> remove(String path) async {}
}
