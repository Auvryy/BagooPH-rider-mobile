import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';

final philippinesMapRegionProvider = FutureProvider<PhilippinesMapRegion>(
  (ref) async => compute(
    PhilippinesMapRegion.decode,
    await rootBundle.loadString('assets/maps/philippines-display.geojson'),
  ),
);

/// A cartographic display footprint. This is never assignment, eligibility or
/// proof of a legal boundary. Saved task coordinates are never moved into it.
class PhilippinesMapRegion {
  PhilippinesMapRegion._(this.polygons)
    : _bounds = [
        for (final polygon in polygons) LatLngBounds.fromPoints(polygon.first),
      ];
  static final cameraBounds = LatLngBounds(
    const LatLng(4.0, 113.8),
    const LatLng(21.8, 127.3),
  );
  static const minimumZoom = 4.0;
  static const maximumZoom = 19.0;
  final List<List<List<LatLng>>> polygons;
  final List<LatLngBounds> _bounds;

  static PhilippinesMapRegion decode(String text) {
    final value = jsonDecode(text);
    if (value is! Map || value['type'] != 'MultiPolygon') {
      throw const FormatException(
        'The Philippines map outline is unavailable.',
      );
    }
    final coordinates = value['coordinates'];
    if (coordinates is! List ||
        coordinates.isEmpty ||
        coordinates.length > 4000) {
      throw const FormatException('Invalid Philippines map outline.');
    }
    var vertices = 0;
    final polygons = <List<List<LatLng>>>[];
    for (final rawPolygon in coordinates) {
      if (rawPolygon is! List || rawPolygon.isEmpty) {
        throw const FormatException('Invalid map island.');
      }
      final rings = <List<LatLng>>[];
      for (final rawRing in rawPolygon) {
        if (rawRing is! List || rawRing.length < 4) {
          throw const FormatException('Invalid map island ring.');
        }
        final ring = <LatLng>[];
        for (final rawPoint in rawRing) {
          if (rawPoint is! List ||
              rawPoint.length != 2 ||
              rawPoint[0] is! num ||
              rawPoint[1] is! num) {
            throw const FormatException('Invalid map outline coordinates.');
          }
          final point = LatLng(
            (rawPoint[1] as num).toDouble(),
            (rawPoint[0] as num).toDouble(),
          );
          if (!inCameraArea(point) || ++vertices > 150000) {
            throw const FormatException('Invalid map outline extent.');
          }
          ring.add(point);
        }
        if (ring.first != ring.last) {
          throw const FormatException('The map outline ring is not closed.');
        }
        rings.add(List.unmodifiable(ring));
      }
      polygons.add(List.unmodifiable(rings));
    }
    return PhilippinesMapRegion._(List.unmodifiable(polygons));
  }

  static bool inCameraArea(LatLng point) =>
      validPoint(point) && cameraBounds.contains(point);

  bool containsLand(LatLng point) {
    if (!inCameraArea(point)) return false;
    for (var i = 0; i < polygons.length; i++) {
      if (!_bounds[i].contains(point)) continue;
      final rings = polygons[i];
      if (_inside(point, rings.first) &&
          !rings.skip(1).any((ring) => _inside(point, ring))) {
        return true;
      }
    }
    return false;
  }

  static bool _inside(LatLng point, List<LatLng> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i], b = ring[j];
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
          point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Avoid downloading tiles wholly outside the display's bounding envelope.
  /// Tiles touching coastlines still load; the island mask clips their artwork.
  static bool tileIntersectsDisplay(int z, int x, int y) {
    if (z < 0 || z > 20) return false;
    final count = 1 << z;
    if (x < 0 || y < 0 || x >= count || y >= count) return false;
    double latitude(int row) {
      final n = math.pi * (1 - 2 * row / count);
      return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    }

    final west = x / count * 360 - 180, east = (x + 1) / count * 360 - 180;
    return east >= cameraBounds.west &&
        west <= cameraBounds.east &&
        latitude(y) >= cameraBounds.south &&
        latitude(y + 1) <= cameraBounds.north;
  }
}
