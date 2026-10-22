import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';

enum MapLocationAccess { granted, denied, deniedForever, servicesOff }

abstract interface class ForegroundMapLocation {
  Future<MapLocationAccess> access({required bool requestPermission});
  Stream<LocationFix> fixes();
}

/// A short-lived foreground sample. No notification configuration, wake lock,
/// background permission or location foreground service is requested here.
class AndroidForegroundMapLocation implements ForegroundMapLocation {
  bool get _visible =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  Future<MapLocationAccess> access({required bool requestPermission}) async {
    if (!_visible) return MapLocationAccess.denied;
    if (!await Geolocator.isLocationServiceEnabled()) {
      return MapLocationAccess.servicesOff;
    }
    var permission = await Geolocator.checkPermission();
    if (_visible &&
        requestPermission &&
        permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => MapLocationAccess.granted,
      LocationPermission.deniedForever => MapLocationAccess.deniedForever,
      _ => MapLocationAccess.denied,
    };
  }

  @override
  Stream<LocationFix> fixes() =>
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 2),
        ),
      ).map(
        (p) => LocationFix(
          LatLng(p.latitude, p.longitude),
          p.timestamp,
          p.accuracy,
        ),
      );
}
