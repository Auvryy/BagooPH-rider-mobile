import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_failure.dart';
import '../../home/data/operations_models.dart';
import '../data/geoapify_client.dart';
import '../data/navigation_location.dart';
import '../data/route_geometry.dart';

class NavigationController extends ChangeNotifier {
  NavigationController({
    required this.routes,
    required this.authorize,
    required this.vehicleType,
    this.location,
    this.manual = false,
    DateTime Function()? now,
    this.onAccessDenied,
  }) : now = now ?? DateTime.now;
  final GeoapifyClient routes;
  final Future<OperationTask> Function(String id) authorize;
  final Future<String?> Function() vehicleType;
  final NavigationLocation? location;
  final bool manual;
  final DateTime Function() now;
  final Future<void> Function(String message)? onAccessDenied;
  OperationTask? task;
  NavigationProfile? profile;
  LocationFix? fix;
  RoadRoute? road;
  bool active = false,
      starting = false,
      following = true,
      calculating = false,
      paused = false;
  String? message;
  StreamSubscription<LocationFix>? _positions;
  Timer? _authorizationTimer,
      _permissionTimer,
      _authorizationExpiry,
      _routeFixExpiry;
  CancelToken? _routeCancel;
  DateTime? _lastRouteAt, _lastAuthorizedAt;
  int _generation = 0, _offRouteFixes = 0;
  DateTime? _lastFixAt;
  bool _disposed = false;
  int? _checkingGeneration;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  LatLng? get target =>
      task?.stop.latitude == null || task?.stop.longitude == null
      ? null
      : LatLng(task!.stop.latitude!, task!.stop.longitude!);
  Future<void> start(
    OperationTask selection, {
    NavigationProfile? chosenProfile,
    LatLng? manualOrigin,
  }) async {
    await stop();
    final generation = ++_generation;
    starting = true;
    message = null;
    paused = false;
    _changed();
    try {
      if (selection.preview) {
        throw StateError('Claim this pickup before navigating.');
      }
      if (!routes.configured) {
        throw StateError('Road navigation needs a Geoapify client key.');
      }
      final owned = await authorize(selection.id);
      if (_disposed || generation != _generation) return;
      if (owned.preview ||
          owned.stop.latitude == null ||
          owned.stop.longitude == null) {
        throw StateError(
          'This stop has no valid coordinates. Use its address for directions.',
        );
      }
      final registered = await vehicleType();
      if (_disposed || generation != _generation) return;
      profile = NavigationProfile.forVehicle(registered) ?? chosenProfile;
      if (profile == null) {
        throw StateError(
          'Choose a navigation profile for the unrecognized vehicle type.',
        );
      }
      if (manual && (manualOrigin == null || !validPoint(manualOrigin))) {
        throw StateError('Enter a valid manual preview origin.');
      }
      if (!manual) await location!.prepare();
      if (_disposed || generation != _generation) return;
      task = owned;
      active = true;
      following = true;
      starting = false;
      _lastAuthorizedAt = now();
      _scheduleAuthorizationExpiry();
      _authorizationTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(checkAuthorization()),
      );
      if (manual) {
        await updateFix(LocationFix(manualOrigin!, now(), 0));
      } else {
        message = 'Waiting for a fresh precise location…';
        _positions = location!.fixes().listen(
          (v) {
            if (!_disposed && generation == _generation) {
              unawaited(updateFix(v));
            }
          },
          onError: (Object _) {
            if (_disposed || generation != _generation) return;
            unawaited(
              stop(
                reason: 'Location updates stopped. Check permissions and start again.',
              ),
            );
          },
        );
        _permissionTimer = Timer.periodic(
          const Duration(seconds: 15),
          (_) => unawaited(checkPermissions()),
        );
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        final denied =
            error is AccountFailure && [401, 403, 404].contains(error.status);
        await stop(
          reason: error is ProviderFailure
              ? error.message
              : error is AccountFailure
              ? error.message
              : error is StateError
              ? error.message
              : 'Navigation could not start. Refresh the task and try again.',
        );
        if (!_disposed && denied && error.status != 404) {
          await onAccessDenied?.call(error.message);
        }
      }
    } finally {
      if (!_disposed && generation == _generation) {
        starting = false;
        _changed();
      }
    }
  }

  Future<void> updateFix(LocationFix value) async {
    if (!active ||
        _disposed ||
        !value.goodAt(now()) ||
        (_lastFixAt != null && !value.recordedAt.isAfter(_lastFixAt!))) {
      return;
    }
    _lastFixAt = value.recordedAt;
    fix = value;
    _changed();
    if (road == null) {
      await refreshRoute();
      return;
    }
    final projection = road!.project(value.point);
    if (projection.distance > 75) {
      _offRouteFixes++;
      if (_offRouteFixes >= 2) await refreshRoute();
    } else {
      _offRouteFixes = 0;
      road = road!.trim(projection);
      _changed();
    }
  }

  Future<void> refreshRoute() async {
    if (_disposed ||
        !active ||
        calculating ||
        fix == null ||
        target == null ||
        profile == null) {
      return;
    }
    if (manual) fix = LocationFix(fix!.point, now(), 0);
    if (!fix!.goodAt(now())) {
      message =
          'Waiting for a fresh accurate location before calculating a route.';
      _changed();
      return;
    }
    if (_lastRouteAt != null &&
        now().difference(_lastRouteAt!) < const Duration(seconds: 30)) {
      message = 'Route refresh is available after the 30-second cooldown.';
      _changed();
      return;
    }
    _lastRouteAt = now();
    calculating = true;
    _routeCancel?.cancel();
    _routeCancel = CancelToken();
    final generation = _generation;
    final cancel = _routeCancel!;
    _routeFixExpiry?.cancel();
    if (!manual) {
      final remaining =
          const Duration(seconds: 30) - now().difference(fix!.recordedAt);
      _routeFixExpiry = Timer(remaining, () {
        if (!_disposed && generation == _generation && calculating) {
          message = 'Waiting for a fresh accurate location before calculating a route.';
          cancel.cancel();
          _changed();
        }
      });
    }
    _changed();
    try {
      final result = await routes.route(fix!.point, target!, profile!, cancel);
      if (_disposed || generation != _generation || cancel.isCancelled) return;
      road = result;
      _offRouteFixes = 0;
      message = manual ? 'Manual preview origin · no GPS tracking' : null;
    } catch (error) {
      if (!_disposed && generation == _generation && !cancel.isCancelled) {
        // A failed recalculation removes stale geometry; no straight substitute.
        road = null;
        message = error is ProviderFailure
            ? error.message
            : 'Could not calculate a road route. Use the stop address.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _routeFixExpiry?.cancel();
        calculating = false;
        _changed();
      }
    }
  }

  void pan() {
    following = false;
    _changed();
  }

  void recenter() {
    following = true;
    _changed();
  }

  void _scheduleAuthorizationExpiry() {
    _authorizationExpiry?.cancel();
    _authorizationExpiry = Timer(const Duration(minutes: 2), () {
      if (active && !_disposed) {
        unawaited(
          stop(
            reason: 'Navigation paused. Revalidate this task to resume.',
            pause: true,
          ),
        );
      }
    });
  }

  Future<void> checkPermissions() async {
    if (!active || manual || _disposed) return;
    final generation = _generation;
    bool allowed = false;
    try {
      allowed = await location!.permitted();
    } catch (_) {}
    if (!_disposed && generation == _generation && !allowed) {
      await stop(
        reason: 'Navigation stopped because location or notification permission changed.',
      );
    }
  }

  Future<void> checkAuthorization() async {
    if (_disposed ||
        !active ||
        task == null ||
        _checkingGeneration == _generation) {
      return;
    }
    final generation = _generation;
    _checkingGeneration = generation;
    final selected = task!;
    try {
      final fresh = await authorize(selected.id);
      if (_disposed || generation != _generation) return;
      if (fresh.preview ||
          fresh.assignmentReference != selected.assignmentReference ||
          fresh.stop.kind != selected.stop.kind ||
          fresh.stop.address != selected.stop.address ||
          fresh.stop.latitude != selected.stop.latitude ||
          fresh.stop.longitude != selected.stop.longitude) {
        await stop(
          reason: 'This assignment or destination changed. Refresh it before navigating again.',
        );
        return;
      }
      task = fresh;
      _lastAuthorizedAt = now();
      _scheduleAuthorizationExpiry();
    } catch (error) {
      if (_disposed || generation != _generation) return;
      if (error is AccountFailure && [401, 403, 404].contains(error.status)) {
        await stop(
          reason:
              'Navigation stopped because this task is no longer authorized.',
        );
        if (!_disposed && error.status != 404) {
          await onAccessDenied?.call(error.message);
        }
      } else if (_lastAuthorizedAt == null ||
          now().difference(_lastAuthorizedAt!) >= const Duration(minutes: 2)) {
        await stop(
          reason: 'Navigation paused. Revalidate this task to resume.',
          pause: true,
        );
      } else {
        message = 'Task authorization could not refresh. Rechecking shortly.';
        _changed();
      }
    } finally {
      if (_checkingGeneration == generation) _checkingGeneration = null;
    }
  }

  Future<void> stop({String? reason, bool pause = false}) async {
    ++_generation;
    _routeCancel?.cancel();
    _routeCancel = null;
    _authorizationTimer?.cancel();
    _permissionTimer?.cancel();
    _authorizationExpiry?.cancel();
    _routeFixExpiry?.cancel();
    _checkingGeneration = null;
    final stream = _positions;
    _positions = null;
    active = false;
    starting = false;
    calculating = false;
    paused = pause;
    task = null;
    fix = null;
    road = null;
    _offRouteFixes = 0;
    _lastFixAt = null;
    message = reason;
    following = true;
    _changed();
    await stream?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    super.dispose();
  }
}
