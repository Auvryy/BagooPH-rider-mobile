import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'map_tile_cache.dart';

MapTileCache createCache() => FileMapTileCache(
  directory: () async =>
      Directory('${(await getApplicationCacheDirectory()).path}/basemap-v1'),
);

/// Async, atomic files with a strict byte budget and oldest-used eviction.
/// A cache error disables caching for this instance; network maps keep working.
class FileMapTileCache implements MapTileCache {
  FileMapTileCache({
    required this.directory,
    this.maxBytes = 64 * 1024 * 1024,
    this.maxTileBytes = 2 * 1024 * 1024,
  });

  final Future<Directory> Function() directory;
  final int maxBytes, maxTileBytes;
  Directory? _directory;
  final _entries = <String, int>{};
  int _size = 0;
  bool _disabled = false;
  Future<void> _tail = Future.value();
  static const _magic = 0x42474d31; // BGM1

  Future<T?> _run<T>(Future<T?> Function() action) {
    final result = _tail.then<T?>((_) async {
      if (_disabled) return null;
      try {
        await _open();
        return await action();
      } catch (_) {
        _disabled = true;
        return null;
      }
    });
    _tail = result.then((_) {});
    return result.timeout(
      const Duration(milliseconds: 250),
      onTimeout: () {
        // Cold directory discovery may outlast a frame on slower storage.
        // Let it finish so subsequent views can still benefit from caching.
        return null;
      },
    );
  }

  Future<void> _open() async {
    if (_directory != null) return;
    final dir = await directory();
    await dir.create(recursive: true);
    final files = <({File file, FileStat stat})>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.endsWith('.tmp')) {
        await entity.delete();
      } else if (RegExp(r'^[a-f0-9]{64}\.tile$').hasMatch(name)) {
        files.add((file: entity, stat: await entity.stat()));
      }
    }
    files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    _directory = dir;
    for (final item in files) {
      _entries[item.file.uri.pathSegments.last] = item.stat.size;
      _size += item.stat.size;
    }
    await _trim(0);
  }

  String _key(String path) => '${sha256.convert(utf8.encode(path))}.tile';
  File _file(String key) => File('${_directory!.path}/$key');

  Future<void> _delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
    _size -= _entries.remove(key) ?? 0;
  }

  Future<void> _trim(int incoming) async {
    while (_entries.isNotEmpty && _size + incoming > maxBytes) {
      await _delete(_entries.keys.first);
    }
  }

  @override
  Future<CachedTile?> read(String path) => _run(() async {
    final key = _key(path);
    if (!_entries.containsKey(key)) return null;
    if (_entries[key]! > maxTileBytes + 12) {
      await _delete(key);
      return null;
    }
    final file = _file(key);
    if (!await file.exists()) {
      await _delete(key);
      return null;
    }
    final data = await file.readAsBytes();
    if (data.length < 20 ||
        data.length > maxTileBytes + 12 ||
        data.buffer.asByteData().getUint32(0) != _magic) {
      await _delete(key);
      return null;
    }
    final expiry = data.buffer.asByteData().getInt64(4);
    if (expiry < 0 || expiry > 8640000000000000) {
      await _delete(key);
      return null;
    }
    final size = _entries.remove(key)!;
    _entries[key] = size;
    return CachedTile(
      Uint8List.sublistView(data, 12),
      DateTime.fromMillisecondsSinceEpoch(expiry, isUtc: true),
    );
  });

  @override
  Future<void> write(String path, CachedTile tile) async {
    if (tile.bytes.length > maxTileBytes || tile.bytes.length + 12 > maxBytes) {
      return;
    }
    await _run<void>(() async {
      final key = _key(path);
      await _delete(key);
      final data = Uint8List(tile.bytes.length + 12);
      data.buffer.asByteData()
        ..setUint32(0, _magic)
        ..setInt64(4, tile.expiresAt.millisecondsSinceEpoch);
      data.setRange(12, data.length, tile.bytes);
      await _trim(data.length);
      final temporary = File('${_file(key).path}.tmp');
      await temporary.writeAsBytes(data, flush: true);
      await temporary.rename(_file(key).path);
      _entries[key] = data.length;
      _size += data.length;
    });
  }

  @override
  Future<void> remove(String path) async {
    await _run<void>(() async {
      await _delete(_key(path));
    });
  }
}
