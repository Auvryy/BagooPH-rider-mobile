import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/rider_map_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

OperationTask _mockTask({String kind = 'buyer', String name = 'Test Buyer Destination'}) {
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

final _mockGeometry = {
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
  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel, {
    bool prioritizeHighways = true,
  }) async {
    return RoadRoute.geoJson(_mockGeometry);
  }
}

class FakeMapSession implements DeliveryMapSession {
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

void main() {
  testWidgets('RiderMapPage displays stop details, controls and highway toggle in bottom cockpit', (tester) async {
    final routes = _MockRoutes();
    final task = _mockTask(kind: 'seller', name: 'Laguna Central Hub');
    final nav = NavigationController(
      routes: routes,
      authorize: (id) async => task,
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    addTearDown(() async {
      await nav.stop();
      nav.dispose();
      routes.dispose();
    });

    await nav.start(task, manualOrigin: const LatLng(14.55, 121.02));
    nav.road = RoadRoute.geoJson(_mockGeometry);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryMapFactoryProvider.overrideWithValue(FakeMapSession.new),
          navigationProvider.overrideWithValue(nav),
        ],
        child: MaterialApp(
          theme: buildRiderTheme(),
          home: RiderMapPage(initialTask: task),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Top bar minimal badge
    expect(find.text('PICKUP · SELLER STORE'), findsOneWidget);
    expect(find.byKey(const ValueKey('rider-map-back-button')), findsOneWidget);

    // 2. Bottom cockpit details
    expect(find.text('Laguna Central Hub'), findsOneWidget);
    expect(find.text('123 Bonifacio St, Metro Manila'), findsOneWidget);
    expect(find.text('Highway: ON'), findsOneWidget);

    // 3. Highway toggle interaction
    await tester.tap(find.byKey(const ValueKey('rider-map-highway-toggle')));
    await tester.pumpAndSettle();
    expect(nav.prioritizeHighways, isFalse);
    expect(find.text('Highway: OFF'), findsOneWidget);

    // 4. Recenter and refresh buttons exist
    expect(find.byKey(const ValueKey('rider-map-recenter-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('rider-map-refresh-button')), findsOneWidget);

    // 5. Active navigation stop button exists
    expect(find.byKey(const ValueKey('rider-map-stop-nav-button')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await nav.stop();
  });
}
