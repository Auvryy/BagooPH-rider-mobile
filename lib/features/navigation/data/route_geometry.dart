import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

bool validPoint(LatLng p) =>
    p.latitude.isFinite &&
    p.longitude.isFinite &&
    p.latitude >= -90 &&
    p.latitude <= 90 &&
    p.longitude >= -180 &&
    p.longitude <= 180;

enum NavigationProfile {
  motorcycle('Motorcycle', 'motorcycle'),
  scooter('Scooter', 'scooter'),
  drive('Sedan or van', 'drive');

  const NavigationProfile(this.label, this.mode);
  final String label, mode;
  static NavigationProfile? forVehicle(String? type) =>
      switch (type?.trim().toLowerCase()) {
        'motorcycle' => motorcycle,
        'scooter' => scooter,
        'sedan' || 'van' => drive,
        _ => null,
      };
}

class LocationFix {
  const LocationFix(this.point, this.recordedAt, this.accuracy);
  final LatLng point;
  final DateTime recordedAt;
  final double accuracy;
  bool goodAt(DateTime now) =>
      validPoint(point) &&
      accuracy.isFinite &&
      accuracy >= 0 &&
      accuracy <= 50 &&
      now.toUtc().difference(recordedAt.toUtc()) >= Duration.zero &&
      now.toUtc().difference(recordedAt.toUtc()) <= const Duration(seconds: 30);
}

class RouteProjection {
  const RouteProjection(this.distance, this.point, this.leg, this.segment);
  final double distance;
  final LatLng point;
  final int leg, segment;
}

class RoadRoute {
  RoadRoute(List<List<LatLng>> lines)
    : lines = List.unmodifiable(
        lines.map((l) => List<LatLng>.unmodifiable(l)),
      ) {
    if (lines.isEmpty ||
        lines.any((l) => l.length < 2 || l.any((p) => !validPoint(p)))) {
      throw const FormatException('The road route could not be verified.');
    }
  }
  factory RoadRoute.geoJson(Object? value) {
    if (value is! Map ||
        value['type'] != 'FeatureCollection' ||
        value['features'] is! List ||
        (value['features'] as List).isEmpty) {
      throw const FormatException('No road route was returned.');
    }
    final feature = (value['features'] as List).first;
    if (feature is! Map || feature['geometry'] is! Map) {
      throw const FormatException('No road geometry was returned.');
    }
    final geometry = feature['geometry'] as Map;
    final coordinates = geometry['coordinates'];
    final Object? raw = geometry['type'] == 'LineString'
        ? [coordinates]
        : geometry['type'] == 'MultiLineString'
        ? coordinates
        : null;
    if (raw is! List) throw const FormatException('Unsupported road geometry.');
    return RoadRoute(
      raw.map((line) {
        if (line is! List) {
          throw const FormatException('Invalid road geometry.');
        }
        return line.map((point) {
          if (point is! List ||
              point.length < 2 ||
              point[0] is! num ||
              point[1] is! num) {
            throw const FormatException('Invalid road coordinates.');
          }
          return LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          );
        }).toList();
      }).toList(),
    );
  }
  final List<List<LatLng>> lines;
  RouteProjection project(LatLng point) {
    RouteProjection? nearest;
    final scale = math.cos(point.latitude * math.pi / 180) * 111195;
    for (var l = 0; l < lines.length; l++) {
      final line = lines[l];
      for (var i = 0; i < line.length - 1; i++) {
        final a = line[i], b = line[i + 1];
        final ax = (a.longitude - point.longitude) * scale,
            ay = (a.latitude - point.latitude) * 111195;
        final bx = (b.longitude - point.longitude) * scale,
            by = (b.latitude - point.latitude) * 111195;
        final dx = bx - ax, dy = by - ay, len = dx * dx + dy * dy;
        final t = len == 0 ? 0.0 : (-(ax * dx + ay * dy) / len).clamp(0.0, 1.0);
        final distance = math.sqrt(
          math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2),
        );
        if (nearest == null || distance < nearest.distance) {
          nearest = RouteProjection(
            distance,
            LatLng(
              a.latitude + t * (b.latitude - a.latitude),
              a.longitude + t * (b.longitude - a.longitude),
            ),
            l,
            i,
          );
        }
      }
    }
    return nearest!;
  }

  RoadRoute trim(RouteProjection p) => RoadRoute([
    [p.point, ...lines[p.leg].skip(p.segment + 1)],
    ...lines.skip(p.leg + 1),
  ]);
}
