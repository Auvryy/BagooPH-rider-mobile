import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';

class ProviderFailure implements Exception {
  const ProviderFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class RoadRoutingClient {
  bool get configured;
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel,
  );
}

/// The current map illustrates a sample delivery; it does not calculate roads.
class UnavailableRoadRouting implements RoadRoutingClient {
  @override
  bool get configured => false;
  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel,
  ) async {
    throw const ProviderFailure(
      'In-app road directions are unavailable. Use external directions for your current stop.',
    );
  }
}
