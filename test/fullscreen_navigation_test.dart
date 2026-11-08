import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/navigation_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/saved_delivery_stop.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/fullscreen_navigation_page.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

OperationTask _task({String kind = 'buyer', String name = 'Test Buyer Destination'}) {
  final j =
      (jsonDecode(
            File('test/fixtures/operations/final-mile-task.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
  j['stop']['kind'] = kind;
  j['stop']['name'] = name;
  j['stop']['address'] = '123 Bonifacio St, Metro Manila';
  j['stop']['latitude'] = 14.5547;
  j['stop']['longitude'] = 121.0244;
  return OperationTask.fromJson(j);
}

final _geometry = {
  'type': 'FeatureCollection',
  'features': [
    {
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [121.02, 14.55],
          [121.0244, 14.5547],
        ],
      },
      'properties': {
        'legs': [
          {
            'steps': [{}],
          },
        ],
      },
    },
  ],
};

class _MockRoutes extends GeoapifyClient {
  _MockRoutes() : super('test-key');
  final calls = <({LatLng origin, LatLng target, NavigationProfile profile, bool prioritizeHighways})>[];
  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel, {
    bool prioritizeHighways = true,
  }) async {
    calls.add((
      origin: origin,
      target: target,
      profile: profile,
      prioritizeHighways: prioritizeHighways,
    ));
    return RoadRoute.geoJson(_geometry);
  }
}

class _StubLocation implements NavigationLocation {
  final stream = StreamController<LocationFix>.broadcast();
  @override
  Stream<LocationFix> fixes() => stream.stream;
  @override
  Future<void> prepare() async {}
  @override
  Future<bool> permitted() async => true;
}

void main() {
  testWidgets('FullscreenNavigationPage displays stop guidance, highway toggle, and handlebar controls', (tester) async {
    final routes = _MockRoutes();
    final nav = NavigationController(
      routes: routes,
      authorize: (id) async => _task(kind: 'seller', name: 'Aling Nena Store'),
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    addTearDown(() async {
      await nav.stop();
      nav.dispose();
      routes.dispose();
    });

    final currentTask = _task(kind: 'seller', name: 'Aling Nena Store');
    await nav.start(currentTask, manualOrigin: const LatLng(14.55, 121.02));
    nav.road = RoadRoute.geoJson(_geometry);
    final stop = SavedDeliveryStop.fromTask(currentTask)!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryMapFactoryProvider.overrideWithValue(FakeDeliveryMapSession.new),
        ],
        child: MaterialApp(
          theme: buildRiderTheme(),
          home: FullscreenNavigationPage(
            navigation: nav,
            task: currentTask,
            stop: stop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Pickup badge
    expect(find.text('PICKUP · SELLER STORE'), findsOneWidget);
    expect(find.text('Aling Nena Store'), findsOneWidget);
    expect(find.text('123 Bonifacio St, Metro Manila'), findsOneWidget);

    // 2. Highway toggle
    expect(find.text('Highway: ON'), findsOneWidget);
    expect(nav.prioritizeHighways, isTrue);

    await tester.tap(find.byKey(const ValueKey('handlebar-highways-toggle')));
    await tester.pumpAndSettle();
    expect(nav.prioritizeHighways, isFalse);
    expect(find.text('Highway: OFF'), findsOneWidget);

    // 3. Recenter button
    nav.pan();
    expect(nav.following, isFalse);
    await tester.tap(find.byKey(const ValueKey('handlebar-recenter')));
    await tester.pumpAndSettle();
    expect(nav.following, isTrue);

    // 4. Handlebar controls exist
    expect(find.byKey(const ValueKey('handlebar-exit-fullscreen')), findsOneWidget);
    expect(find.byKey(const ValueKey('handlebar-stop-navigation')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await nav.stop();
  });

  testWidgets('FullscreenNavigationPage displays delivery stop guidance for buyer destination', (tester) async {
    final routes = _MockRoutes();
    final nav = NavigationController(
      routes: routes,
      authorize: (id) async => _task(kind: 'buyer', name: 'Maria Santos'),
      vehicleType: () async => 'scooter',
      manual: true,
    );
    addTearDown(() async {
      await nav.stop();
      nav.dispose();
      routes.dispose();
    });

    final currentTask = _task(kind: 'buyer', name: 'Maria Santos');
    await nav.start(currentTask, manualOrigin: const LatLng(14.55, 121.02));
    nav.road = RoadRoute.geoJson(_geometry);
    final stop = SavedDeliveryStop.fromTask(currentTask)!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryMapFactoryProvider.overrideWithValue(FakeDeliveryMapSession.new),
        ],
        child: MaterialApp(
          theme: buildRiderTheme(),
          home: FullscreenNavigationPage(
            navigation: nav,
            task: currentTask,
            stop: stop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DELIVERY · BUYER DESTINATION'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await nav.stop();
  });
}

class FakeDeliveryMapSession implements DeliveryMapSession {
  @override
  Widget get view => const SizedBox.expand(
        key: ValueKey('fake-map-view'),
      );
  @override
  Future<void> load(String document, void Function(String) onEvent) async {
    onEvent(jsonEncode({'type': 'ready'}));
  }
  @override
  Future<void> updateRoute(RoadRoute? road) async {}
  @override
  Future<void> close() async {}
}
