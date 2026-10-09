import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/navigation_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

OperationTask task({String id = '1', double latitude = 14.01}) {
  final j =
      (jsonDecode(
            File('test/fixtures/operations/final-mile-task.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  j['id'] = 'final_mile-$id';
  j['delivery_id'] = id;
  j['stop']['kind'] = 'buyer';
  j['stop']['latitude'] = latitude;
  j['stop']['longitude'] = 121.0;
  return OperationTask.fromJson(j);
}

final geometry = {
  'type': 'FeatureCollection',
  'features': [
    {
      'geometry': {
        'type': 'MultiLineString',
        'coordinates': [
          [
            [121.0, 14.0],
            [121.0, 14.01],
          ],
          [
            [121.0, 14.01],
            [121.01, 14.01],
          ],
        ],
      },
    },
  ],
};

class Routes extends GeoapifyClient {
  Routes() : super('synthetic-provider-key');
  final calls =
      <
        ({
          LatLng origin,
          LatLng target,
          NavigationProfile profile,
          CancelToken cancel,
        })
      >[];
  Future<RoadRoute> Function()? response;
  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel,
  ) {
    calls.add((
      origin: origin,
      target: target,
      profile: profile,
      cancel: cancel,
    ));
    return response?.call() ?? Future.value(RoadRoute.geoJson(geometry));
  }
}

class Location implements NavigationLocation {
  final stream = StreamController<LocationFix>.broadcast();
  int prepared = 0, listened = 0;
  bool allowed = true;
  @override
  Future<void> prepare() async {
    prepared++;
    if (!allowed) throw StateError('Permission denied');
  }

  @override
  Future<bool> permitted() async => allowed;
  @override
  Stream<LocationFix> fixes() {
    listened++;
    return stream.stream;
  }
}

void main() {
  test(
    'GeoJSON swaps longitude/latitude and preserves separate road lines',
    () {
      final route = RoadRoute.geoJson(geometry);
      expect(route.lines.first.first, const LatLng(14, 121));
      expect(route.lines.length, 2);
      final p = route.project(const LatLng(14.005, 121));
      expect(p.distance, lessThan(1));
      final trimmed = route.trim(p);
      expect(trimmed.lines.first.first.latitude, closeTo(14.005, .000001));
      expect(trimmed.lines.last, route.lines.last);
      expect(
        () => RoadRoute.geoJson({'type': 'FeatureCollection', 'features': []}),
        throwsFormatException,
      );
    },
  );
  test('bad accuracy, stale/future timestamps and out-of-range fixes cannot calculate', () {
    final now = DateTime.utc(2026, 10, 9);
    expect(LocationFix(const LatLng(14, 121), now, 50).goodAt(now), true);
    for (final fix in [
      LocationFix(const LatLng(14, 121), now, 50.1),
      LocationFix(
        const LatLng(14, 121),
        now.subtract(const Duration(seconds: 31)),
        5,
      ),
      LocationFix(
        const LatLng(14, 121),
        now.add(const Duration(seconds: 1)),
        5,
      ),
      LocationFix(const LatLng(100, 121), now, 5),
    ]) {
      expect(fix.goodAt(now), false);
    }
    expect(
      NavigationProfile.forVehicle('motorcycle'),
      NavigationProfile.motorcycle,
    );
    expect(NavigationProfile.forVehicle('scooter'), NavigationProfile.scooter);
    expect(NavigationProfile.forVehicle('van'), NavigationProfile.drive);
    expect(NavigationProfile.forVehicle('bicycle'), isNull);
  });
  test(
    'navigation stays idle until explicit Navigate; denial leaves it stopped',
    () async {
      final routes = Routes(), location = Location();
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async => task(),
        vehicleType: () async => 'motorcycle',
        location: location,
      );
      expect(location.prepared, 0);
      expect(location.listened, 0);
      expect(nav.active, false);
      location.allowed = false;
      await nav.start(task());
      expect(nav.active, false);
      expect(routes.calls, isEmpty);
      expect(location.listened, 0);
      nav.dispose();
      routes.dispose();
      await location.stream.close();
    },
  );
  test('unknown vehicle needs choice; manual origin is explicit and creates road geometry', () async {
    final routes = Routes();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => task(),
      vehicleType: () async => null,
      manual: true,
    );
    await nav.start(task(), manualOrigin: const LatLng(14, 121));
    expect(nav.active, false);
    expect(routes.calls, isEmpty);
    await nav.start(
      task(),
      chosenProfile: NavigationProfile.scooter,
      manualOrigin: const LatLng(14, 121),
    );
    expect(nav.active, true);
    expect(routes.calls.single.profile, NavigationProfile.scooter);
    expect(nav.message, contains('Manual preview origin'));
    nav.pan();
    expect(nav.following, false);
    nav.recenter();
    expect(nav.following, true);
    await nav.stop();
    expect(nav.fix, isNull);
    expect(nav.road, isNull);
    expect(nav.active, false);
    nav.dispose();
    routes.dispose();
  });
  test('two good fixes over 75m reroute, within 30s stays bounded and bad fixes do not count', () async {
    final routes = Routes(), location = Location();
    var now = DateTime.utc(2026, 10, 9);
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => task(),
      vehicleType: () async => 'sedan',
      location: location,
      now: () => now,
    );
    await nav.start(task());
    await nav.updateFix(LocationFix(const LatLng(14, 121), now, 10));
    expect(routes.calls.length, 1);
    now = now.add(const Duration(seconds: 10));
    await nav.updateFix(LocationFix(const LatLng(14, 121.002), now, 10));
    now = now.add(const Duration(seconds: 1));
    await nav.updateFix(LocationFix(const LatLng(14, 121.002), now, 100));
    expect(routes.calls.length, 1);
    now = now.add(const Duration(seconds: 1));
    await nav.updateFix(LocationFix(const LatLng(14, 121.002), now, 10));
    expect(routes.calls.length, 1);
    now = now.add(const Duration(seconds: 19));
    await nav.updateFix(LocationFix(const LatLng(14, 121.002), now, 10));
    expect(routes.calls.length, 2);
    await nav.refreshRoute();
    expect(routes.calls.length, 2);
    nav.dispose();
    routes.dispose();
    await location.stream.close();
  });
  test('Stop and selecting another target cancel old requests; late result cannot overwrite', () async {
    final routes = Routes();
    final old = Completer<RoadRoute>();
    routes.response = () => old.future;
    var selected = task();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => selected,
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    final running = nav.start(selected, manualOrigin: const LatLng(14, 121));
    await Future<void>.delayed(Duration.zero);
    expect(routes.calls.length, 1);
    await nav.stop();
    expect(routes.calls.single.cancel.isCancelled, true);
    selected = task(id: '2', latitude: 14.02);
    await nav.start(selected, manualOrigin: const LatLng(14, 121));
    old.complete(RoadRoute.geoJson(geometry));
    await running;
    expect(nav.task!.id, 'final_mile-2');
    expect(nav.road, isNull);
    nav.dispose();
    routes.dispose();
  });
  test('route failure never invents straight line; authorization failure pauses after 2min', () async {
    final routes = Routes();
    routes.response = () async =>
        throw const ProviderFailure('quota exhausted');
    var now = DateTime.utc(2026, 10, 9);
    bool network = true;
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async {
        if (!network) throw const AccountFailure('offline');
        return task();
      },
      vehicleType: () async => 'van',
      manual: true,
      now: () => now,
    );
    await nav.start(task(), manualOrigin: const LatLng(14, 121));
    expect(nav.road, isNull);
    expect(nav.message, 'quota exhausted');
    network = false;
    now = now.add(const Duration(minutes: 1));
    await nav.checkAuthorization();
    expect(nav.active, true);
    now = now.add(const Duration(minutes: 1));
    await nav.checkAuthorization();
    expect(nav.active, false);
    expect(nav.paused, true);
    nav.dispose();
    routes.dispose();
  });
  test('changed destination and explicit access denial stop navigation immediately', () async {
    final routes = Routes();
    var selected = task();
    bool denied = false;
    int ended = 0;
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async {
        if (denied) throw const AccountFailure('denied', status: 403);
        return selected;
      },
      vehicleType: () async => 'motorcycle',
      manual: true,
      onAccessDenied: (_) async {
        ended++;
      },
    );
    await nav.start(task(), manualOrigin: const LatLng(14, 121));
    selected = task(latitude: 14.03);
    await nav.checkAuthorization();
    expect(nav.active, false);
    await nav.start(selected, manualOrigin: const LatLng(14, 121));
    denied = true;
    await nav.checkAuthorization();
    expect(nav.active, false);
    expect(ended, 1);
    nav.dispose();
    routes.dispose();
  });
  test('permission removal stops stream; controller disposal ignores account-change replies', () async {
    final routes = Routes(), location = Location();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => task(),
      vehicleType: () async => 'motorcycle',
      location: location,
    );
    await nav.start(task());
    expect(location.stream.hasListener, true);
    location.allowed = false;
    await nav.checkPermissions();
    expect(nav.active, false);
    expect(location.stream.hasListener, false);
    nav.dispose();
    routes.dispose();
    await location.stream.close();
  });
  testWidgets(
    'independent deadline pauses navigation while authorization refresh hangs',
    (tester) async {
      final routes = Routes();
      final blocked = Completer<OperationTask>();
      var reads = 0;
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async {
          if (++reads > 1) return blocked.future;
          return task();
        },
        vehicleType: () async => 'motorcycle',
        manual: true,
        now: tester.binding.clock.now,
      );
      await nav.start(task(), manualOrigin: const LatLng(14, 121));
      await tester.pump(const Duration(minutes: 1));
      expect(nav.active, true);
      await tester.pump(const Duration(minutes: 1));
      expect(nav.active, false);
      expect(nav.paused, true);
      blocked.complete(task());
      await tester.pump();
      expect(nav.task, isNull);
      nav.dispose();
      routes.dispose();
    },
  );
  test('account disposal ignores a late detail authorization result', () async {
    final routes = Routes(), detail = Completer<OperationTask>();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) => detail.future,
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    final pending = nav.start(task(), manualOrigin: const LatLng(14, 121));
    await Future<void>.delayed(Duration.zero);
    nav.dispose();
    detail.complete(task());
    await pending;
    expect(nav.active, false);
    expect(nav.task, isNull);
    expect(routes.calls, isEmpty);
    routes.dispose();
  });
  testWidgets(
    'a queued calculation is cancelled when its origin fix becomes stale',
    (tester) async {
      final routes = Routes(),
          location = Location(),
          result = Completer<RoadRoute>();
      routes.response = () => result.future;
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async => task(),
        vehicleType: () async => 'motorcycle',
        location: location,
        now: tester.binding.clock.now,
      );
      await nav.start(task());
      final calculation = nav.updateFix(
        LocationFix(const LatLng(14, 121), tester.binding.clock.now(), 10),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(routes.calls.single.cancel.isCancelled, true);
      result.complete(RoadRoute.geoJson(geometry));
      await calculation;
      expect(nav.road, isNull);
      nav.dispose();
      routes.dispose();
      await location.stream.close();
    },
  );
}
