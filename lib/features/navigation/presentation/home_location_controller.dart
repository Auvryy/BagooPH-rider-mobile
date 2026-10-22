import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/foreground_map_location.dart';
import '../data/philippines_map_region.dart';
import '../data/route_geometry.dart';

final homeLocationProvider = Provider<HomeLocationController>((ref) {
  // Recreate and dispose private in-memory location with the authenticated scope.
  final identity = ref.watch(
    authControllerProvider.select(
      (s) => (s.user?.id, s.user?.approved, s.user?.operationsApiVersion),
    ),
  );
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final controller = HomeLocationController(
    manual: !kIsWeb && defaultTargetPlatform == TargetPlatform.linux,
    source: android && identity.$1 != null && identity.$2 == true
        ? AndroidForegroundMapLocation()
        : null,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [authControllerProvider]);

/// A location snapshot for Home, never an ongoing navigation session. One
/// accepted sample stops acquisition; hiding Home cancels it and clears GPS data.
class HomeLocationController extends ChangeNotifier {
  HomeLocationController({
    this.source,
    this.manual = false,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final ForegroundMapLocation? source;
  final bool manual;
  final DateTime Function() now;
  LocationFix? fix;
  bool locating = false;
  String? message;
  bool _visible = false, _disposed = false, _prompted = false;
  int _generation = 0;
  StreamSubscription<LocationFix>? _subscription;
  Future<void> _cancellation = Future.value();
  Timer? _timeout;

  bool get supported => source != null;

  void setVisible(bool visible, {bool notify = true}) {
    if (_disposed || visible == _visible) return;
    _visible = visible;
    if (!visible) {
      _generation++;
      _timeout?.cancel();
      unawaited(_cancelSubscription());
      locating = false;
      if (!manual) fix = null;
      if (notify) _changed();
    } else if (supported) {
      unawaited(locate(requestPermission: !_prompted));
    }
  }

  /// Geolocator shares its position stream on Android. Finish cancellation
  /// before navigation subscribes, so it gets its own foreground-service settings.
  Future<void> suspend() async {
    setVisible(false);
    await _cancelSubscription();
  }

  Future<void> _cancelSubscription() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      _cancellation = Future.wait<void>([_cancellation, subscription.cancel()])
          .then<void>((_) {}, onError: (Object _, StackTrace _) {});
    }
    return _cancellation;
  }

  Future<void> locate({bool requestPermission = true}) async {
    if (_disposed || !_visible || !supported || locating) return;
    final generation = ++_generation;
    locating = true;
    message = null;
    _prompted = _prompted || requestPermission;
    _changed();
    bool current() => !_disposed && _visible && generation == _generation;
    try {
      await _cancelSubscription();
      if (!current()) return;
      final access = await source!.access(requestPermission: requestPermission);
      if (!current()) return;
      if (access != MapLocationAccess.granted) {
        _finish(switch (access) {
          MapLocationAccess.servicesOff =>
            'Turn on location services to find your area.',
          MapLocationAccess.deniedForever =>
            'Allow location in Android app settings, then tap Recenter.',
          _ => 'Allow location to center the map. You can still browse tasks.',
        });
        return;
      }
      _timeout = Timer(const Duration(seconds: 15), () {
        if (current()) {
          _finish(
            'No precise location yet. Move into the open and tap Recenter.',
          );
        }
      });
      _subscription = source!.fixes().listen(
        (value) {
          if (!current() || !value.goodAt(now())) return;
          if (!PhilippinesMapRegion.inCameraArea(value.point)) {
            _finish(
              'Your location is outside this Philippines map. Task addresses remain available.',
            );
            return;
          }
          fix = value;
          _finish(null);
        },
        onError: (Object _) {
          if (current()) {
            _finish('Location is unavailable. Tap Recenter to try again.');
          }
        },
        onDone: () {
          if (current() && locating) {
            _finish('No location was returned. Tap Recenter to try again.');
          }
        },
      );
    } catch (_) {
      if (current()) {
        _finish('Location is unavailable. Tap Recenter to try again.');
      }
    }
  }

  void setManualOrigin(LatLng point) {
    if (_disposed || !manual || !PhilippinesMapRegion.inCameraArea(point)) {
      return;
    }
    fix = LocationFix(point, now(), 0);
    message = null;
    _changed();
  }

  void _finish(String? reason) {
    _generation++;
    locating = false;
    message = reason;
    if (reason != null) fix = null;
    _timeout?.cancel();
    unawaited(_cancelSubscription());
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timeout?.cancel();
    unawaited(_cancelSubscription());
    fix = null;
    super.dispose();
  }
}
