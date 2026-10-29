import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:latlong2/latlong.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_dashboard.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_source.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/philippines_map_region.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/home_location_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/navigation_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_workspace_binding.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;
import 'support/delivery_map.dart';

import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';

class MemoryTiles extends GeoapifyClient {
  MemoryTiles() : super('synthetic-map-key');
  final calls = <({int z, int x, int y, CancelToken? cancel})>[];
  final tokens = <CancelToken>[];
  final bytes = <String, Uint8List>{};
  final sources = <MapTileSource>[];
  @override
  Future<Uint8List> tile(
    int z,
    int x,
    int y, {
    CancelToken? cancel,
    MapTileSource source = const MapTileSource(),
  }) async {
    if (cancel != null) tokens.add(cancel);
    final key = source.path(z, x, y);
    if (bytes.containsKey(key)) return bytes[key]!;
    calls.add((z: z, x: x, y: y, cancel: cancel));
    sources.add(source);
    return bytes[key] = TileProvider.transparentImage;
  }

  void showFailure() {
    failure = 'Synthetic map connection failure';
    notifyListeners();
  }

  @override
  Future<RoadRoute> route(
    LatLng origin,
    LatLng target,
    NavigationProfile profile,
    CancelToken cancel,
  ) async => RoadRoute([
    [origin, target],
  ]);
}

const account = RiderAccount(
  id: '5',
  name: 'Example Rider',
  email: 'rider@example.test',
  status: 'active',
  kycStatus: 'approved',
  approved: true,
  emailVerified: true,
  operationsApiVersion: 1,
);
void main() {
  managedDashboardTest(
    'work loads first and the optional sample never starts routing',
    (tester) async {
      final geo = MemoryTiles();
      final h = await openDashboard(tester, geoClient: geo);
      expect(find.byType(LeafletDeliveryMap), findsNothing);
      await tapHome(tester, find.byKey(const ValueKey('home-sample-toggle')));
      expect(find.byType(LeafletDeliveryMap), findsOneWidget);
      expect(find.text('Sample rider → Sample delivery point'), findsOneWidget);
      expect(
        find.textContaining('not a live rider or an assigned parcel'),
        findsOneWidget,
      );
      expect(find.byType(FlutterMap), findsNothing);
      expect(geo.calls, isEmpty);
      expect(h.navigation.active, isFalse);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );
  managedDashboardTest(
    'task cards still load the owned parcel and open its protected detail',
    (tester) async {
      final h = await openDashboard(tester);
      await tapHome(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
      expect(h.controller.selectedTask?.id, h.task.id);
      final map = tester.widget<LeafletDeliveryMap>(
        find.byType(LeafletDeliveryMap),
      );
      expect(map.stop?.latitude, h.task.stop.latitude);
      expect(map.stop?.longitude, h.task.stop.longitude);
      expect(find.text('Current stop'), findsOneWidget);
      expect(h.navigation.active, isFalse);
      await tapHome(
        tester,
        find.byKey(const ValueKey('home-selected-details')),
      );
      expect(find.byType(LeafletDeliveryMap), findsNothing);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );
  managedDashboardTest(
    'missing coordinates retain task addresses while the illustration remains labelled',
    (tester) async {
      final h = await openDashboard(tester, coordinates: false);
      await tapHome(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
      expect(h.controller.selectedTask?.stop.address, isNotEmpty);
      expect(h.controller.selectedTask?.stop.latitude, isNull);
      expect(find.byType(LeafletDeliveryMap), findsNothing);
      expect(find.textContaining('No location pin is saved'), findsOneWidget);
      await tapHome(tester, find.byKey(const ValueKey('home-sample-toggle')));
      await revealHome(tester, find.textContaining('Sample rider'));
      expect(find.textContaining('Sample rider'), findsOneWidget);
      expect(h.navigation.active, isFalse);
    },
  );
  managedDashboardTest(
    'off-duty riders retain their own task list and the sample is not a claim',
    (tester) async {
      final h = await openDashboard(tester, onDuty: false);
      await revealHome(
        tester,
        find.byKey(const ValueKey('task-queue-delivery')),
      );
      expect(find.byKey(const ValueKey('task-queue-delivery')), findsOneWidget);
      expect(h.controller.homeData.data?.onDuty, isFalse);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );
  for (final (size, scale) in [
    (const Size(320, 640), 2.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(1440, 900), 1.0),
  ]) {
    managedDashboardTest(
      'Leaflet sample and task controls reflow at $size and ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final h = await openDashboard(tester, textScale: scale);
        await revealHome(
          tester,
          find.byKey(const ValueKey('task-queue-delivery')),
        );
        expect(
          find.byKey(const ValueKey('task-queue-delivery')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(h.navigation.active, isFalse);
        await tapHome(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
        await revealHome(tester, find.byType(LeafletDeliveryMap));
        expect(
          tester
              .widget<LeafletDeliveryMap>(find.byType(LeafletDeliveryMap))
              .stop
              ?.latitude,
          h.task.stop.latitude,
        );
        expect(tester.takeException(), isNull);
        expect(h.navigation.active, isFalse);
      },
    );
  }
  managedDashboardTest(
    'hidden Home destroys the renderer without starting an operation',
    (tester) async {
      final visibility = ValueNotifier(true);
      addTearDown(visibility.dispose);
      final h = await openDashboard(tester, visibility: visibility);
      await tapHome(tester, find.byKey(const ValueKey('home-sample-toggle')));
      expect(find.byType(LeafletDeliveryMap), findsOneWidget);
      visibility.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(LeafletDeliveryMap), findsNothing);
      visibility.value = true;
      await tester.pumpAndSettle();
      await revealHome(tester, find.byType(LeafletDeliveryMap));
      expect(find.byType(LeafletDeliveryMap), findsOneWidget);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
    },
  );
}

Future<
  ({
    WorkspaceController controller,
    OperationTask task,
    NavigationController navigation,
    support.Session api,
  })
>
openDashboard(
  WidgetTester tester, {
  double textScale = 1,
  bool onDuty = true,
  bool coordinates = true,
  bool hidden = false,
  GeoapifyClient? geoClient,
  ValueListenable<bool>? visibility,
  LatLng stopPoint = const LatLng(14.6, 120.986),
  HomeLocationController? mapLocation,
  bool manual = true,
  NavigationLocation? navigationLocation,
  bool reducedMotion = false,
  DeliveryMapFactory? mapFactory,
}) async {
  final api = support.Session(), journal = support.Journal();
  final home = support.fixture('home');
  home['data']['on_duty'] = onDuty;
  home['data']['eligibility']['can_claim'] = onDuty;
  home['data']['eligibility']['claim_denial'] = onDuty ? null : 'OFF_DUTY';
  home['data']['counts'] = {'available': 0, 'pickup': 0, 'final_mile': 1};
  final json =
      support.fixture('final-mile-task')['data'] as Map<String, dynamic>;
  json['stop']['kind'] = 'buyer';
  json['operational_stage'] = 'out_for_delivery';
  json['stop']['latitude'] = coordinates ? stopPoint.latitude : null;
  json['stop']['longitude'] = coordinates ? stopPoint.longitude : null;
  final task = OperationTask.fromJson(json);
  api.respond = (path, method, data, headers) async {
    if (path == 'rider/home') return home;
    if (path.startsWith('rider/tasks/')) return {'data': json};
    return {
      'data': {
        'items': path.contains('phase=final_mile') ? [json] : [],
        'pagination': {
          'page': 1,
          'per_page': 20,
          'total': path.contains('phase=final_mile') ? 1 : 0,
          'last_page': 1,
        },
      },
    };
  };
  final controller = WorkspaceController(
    OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: false,
      isCurrent: () => true,
    ),
  );
  controller.selectQueue(TaskQueue.delivery);
  final geo = geoClient ?? GeoapifyClient('');
  final nav = NavigationController(
    routes: geo,
    authorize: (_) async => task,
    vehicleType: () async => null,
    manual: manual,
    location: navigationLocation,
    beforeStart: mapLocation?.suspend,
  );
  final binding = NavigationWorkspaceBinding(controller, nav);
  final region = _testMapRegion ??= PhilippinesMapRegion.decode(
    File('assets/maps/philippines-display.geojson').readAsStringSync(),
  );
  _disposeDashboard = () async {
    await tester.pumpWidget(const SizedBox.shrink());
    binding.dispose();
    controller.dispose();
    nav.dispose();
    mapLocation?.dispose();
    geo.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  };
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deliveryMapFactoryProvider.overrideWithValue(
          mapFactory ?? FakeDeliveryMapSession.new,
        ),
        deliveryMapDocumentProvider.overrideWithValue(
          () async => '<title>Sample delivery route</title><script>window.riderDeliverySample={};</script>',
        ),
        roadRoutingProvider.overrideWithValue(geo),
        navigationProvider.overrideWithValue(nav),
        if (mapLocation != null)
          homeLocationProvider.overrideWithValue(mapLocation),
        philippinesMapRegionProvider.overrideWithValue(AsyncData(region)),
      ],
      child: MaterialApp(
        theme: buildRiderTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize / tester.view.devicePixelRatio,
            devicePixelRatio: tester.view.devicePixelRatio,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
            accessibleNavigation: reducedMotion,
          ),
          child: RepaintBoundary(
            key: const ValueKey('home-dashboard-render'),
            child: Scaffold(
              body: hidden
                  ? IndexedStack(
                      index: 1,
                      children: [
                        HomeDashboard(
                          account: account,
                          controller: controller,
                          active: false,
                        ),
                        const Text('Another screen'),
                      ],
                    )
                  : visibility == null
                  ? HomeDashboard(account: account, controller: controller)
                  : ValueListenableBuilder<bool>(
                      valueListenable: visibility,
                      builder: (context, active, _) => HomeDashboard(
                        account: account,
                        controller: controller,
                        active: active,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (controller: controller, task: task, navigation: nav, api: api);
}

Future<void> Function()? _disposeDashboard;
PhilippinesMapRegion? _testMapRegion;
void managedDashboardTest(
  String name,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      final close = _disposeDashboard;
      _disposeDashboard = null;
      await close?.call();
    }
  });
}

Future<void> tapHome(WidgetTester tester, Finder target) async {
  await revealHome(tester, target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> revealHome(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final page = find.byKey(const ValueKey('home-page-scroll'));
    if (page.evaluate().isNotEmpty) {
      final scrollable = find
          .descendant(of: page, matching: find.byType(Scrollable))
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(0);
      await tester.pump();
      for (var n = 0; target.evaluate().isEmpty && n < 40; n++) {
        position.jumpTo(
          (position.pixels + 160).clamp(0, position.maxScrollExtent),
        );
        await tester.pump();
      }
    }
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
