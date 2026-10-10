import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'route_geometry.dart';

abstract interface class NavigationLocation {
  Future<void> prepare();
  Future<bool> permitted();
  Stream<LocationFix> fixes();
}

class AndroidNavigationLocation implements NavigationLocation {
  static const _channel = MethodChannel('bagoo/navigation_permissions');
  @override
  Future<void> prepare() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      throw StateError('Start navigation while the app is visible.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Enable location services to navigate.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was denied. You can still browse tasks.',
      );
    }
    if (await Geolocator.getLocationAccuracy() !=
        LocationAccuracyStatus.precise) {
      throw StateError('Precise location is required for road navigation.');
    }
    if (await _channel.invokeMethod<bool>('requestNotifications') != true) {
      throw StateError(
        'Allow navigation notifications to use background navigation.',
      );
    }
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      throw StateError('Return to the app before starting navigation.');
    }
  }

  @override
  Future<bool> permitted() async {
    final permission = await Geolocator.checkPermission();
    return (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) &&
        await Geolocator.isLocationServiceEnabled() &&
        await Geolocator.getLocationAccuracy() ==
            LocationAccuracyStatus.precise &&
        await _channel.invokeMethod<bool>('notificationsAllowed') == true;
  }

  @override
  Stream<LocationFix> fixes() =>
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'BagooPH route navigation',
            notificationText: 'Location is updating for your selected stop. Open the app to stop navigation.',
            notificationIcon: AndroidResource(
              name: 'ic_navigation',
              defType: 'drawable',
            ),
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      ).map(
        (p) => LocationFix(
          LatLng(p.latitude, p.longitude),
          p.timestamp,
          p.accuracy,
        ),
      );
}
