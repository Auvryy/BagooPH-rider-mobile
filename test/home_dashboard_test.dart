import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:latlong2/latlong.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_dashboard.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_task_panel.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_source.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/philippines_map_region.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_workspace_binding.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;

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
  setUp(() {
    final previous = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previous);
  });
  testWidgets(
    'pins and cards select the same fresh owned task; missing coordinates keep address',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      final api = support.Session(), journal = support.Journal();
      final j =
          support.fixture('final-mile-task')['data'] as Map<String, dynamic>;
      j['stop']['latitude'] = 14.0;
      j['stop']['longitude'] = 121.0;
      final owned = OperationTask.fromJson(j);
      api.respond = (path, method, data, headers) async {
        if (path == 'rider/home') return support.fixture('home');
        if (path.startsWith('rider/tasks/')) return {'data': j};
        return {
          'data': {
            'items': [j],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 1,
              'last_page': 1,
            },
          },
        };
      };
      final repo = OperationsRepository(
        api,
        accountId: '5',
        journal: journal,
        writesVerified: false,
        isCurrent: () => true,
      );
      final controller = WorkspaceController(repo);
      controller.selectQueue(TaskQueue.delivery);
      final geo = GeoapifyClient('');
      final nav = NavigationController(
        routes: geo,
        authorize: (_) async => owned,
        vehicleType: () async => null,
        manual: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geoapifyProvider.overrideWithValue(geo),
            navigationProvider.overrideWithValue(nav),
            philippinesMapRegionProvider.overrideWithValue(
              AsyncData(
                _testMapRegion ??= PhilippinesMapRegion.decode(
                  File('assets/maps/philippines-display.geojson')
                      .readAsStringSync(),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: HomeDashboard(account: account, controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Manual preview origin'), findsOneWidget);
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      await tester.tap(find.byTooltip('Select ${owned.tracking}'));
      await tester.pumpAndSettle();
      expect(controller.selectedTask?.id, owned.id);
      expect(
        find.byKey(const ValueKey('home-selected-details')),
        findsOneWidget,
      );
      final camera = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera;
      expect(camera.zoom, greaterThan(12));
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-selected-details')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-selected-details')));
      await tester.pumpAndSettle();
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Origin latitude'), findsOneWidget);
      await tester.ensureVisible(find.text('Back to tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to tasks'));
      await tester.pumpAndSettle();
      expect(controller.selectedTask?.id, owned.id);
      await controller.openTask(OperationsRepository.asRiderTask(owned));
      expect(controller.selectedTask?.id, owned.id);
      j['stop']['latitude'] = null;
      j['stop']['longitude'] = null;
      await controller.openTask(OperationsRepository.asRiderTask(owned));
      expect(controller.selectedTask?.stop.latitude, isNull);
      expect(controller.selectedTask?.stop.address, isNotNull);
      await tester.pumpAndSettle();
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers, isEmpty);
      expect(find.text('Address only · no saved map pin'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      nav.dispose();
      geo.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('map dashboard stays usable at $size and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final controller = WorkspaceController(
        const UnavailableWorkspaceRepository(),
      );
      final geo = GeoapifyClient('');
      final nav = NavigationController(
        routes: geo,
        authorize: (_) async => throw StateError('unavailable'),
        vehicleType: () async => null,
        manual: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geoapifyProvider.overrideWithValue(geo),
            navigationProvider.overrideWithValue(nav),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: HomeDashboard(account: account, controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await revealHome(tester, find.text('Powered by Geoapify'));
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      nav.dispose();
      geo.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  managedDashboardTest(
    'phone Home scrolls as one page and preserves task selection and search',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      await Scrollable.ensureVisible(
        tester.element(find.text('Your tasks', skipOffstage: false)),
        alignment: .8,
      );
      await tester.pumpAndSettle();
      final mapBefore = tester.getRect(
        find.byType(FlutterMap, skipOffstage: false),
      );
      final titleBefore = tester.getRect(find.text('Your tasks'));
      await tester.drag(find.text('Your tasks'), const Offset(0, -100));
      await tester.pumpAndSettle();
      final mapAfter = tester.getRect(
        find.byType(FlutterMap, skipOffstage: false),
      );
      final titleAfter = tester.getRect(find.text('Your tasks'));
      expect(mapAfter.top, lessThan(mapBefore.top));
      expect(mapAfter.size, mapBefore.size);
      expect(
        titleBefore.top - titleAfter.top,
        closeTo(mapBefore.top - mapAfter.top, 1),
      );
      final row = find.byKey(ValueKey('home-task-${h.task.id}'));
      await tapHome(tester, row);
      expect(h.controller.selectedTask?.id, h.task.id);
      expect(
        find.byKey(const ValueKey('home-selected-details')),
        findsOneWidget,
      );
      await tapHome(tester, find.text('Show stop'));
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
            .mapController!
            .camera
            .zoom,
        greaterThan(12),
      );
      final credits = tester.getRect(find.text('Powered by Geoapify'));
      final map = tester.getRect(find.byType(FlutterMap));
      expect(credits.top, greaterThanOrEqualTo(map.bottom));
      await tapHome(tester, find.byTooltip('Search tasks'));
      await tester.ensureVisible(find.byKey(const ValueKey('task-search')));
      await tester.enterText(
        find.byKey(const ValueKey('task-search')),
        'missing-parcel',
      );
      await tester.pumpAndSettle();
      expect(h.controller.visibleTasks, isEmpty);
      await tester.enterText(find.byKey(const ValueKey('task-search')), '');
      await tester.pumpAndSettle();
      await tapHome(tester, find.byKey(const ValueKey('task-queue-available')));
      expect(h.controller.selectedTask, isNull);
      expect(h.controller.taskSearch, isEmpty);
      expect(h.controller.queue, TaskQueue.available);
      expect(tester.takeException(), isNull);
    },
  );
  managedDashboardTest(
    'large text keeps full queue names and off-duty owned work reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester, textScale: 2, onDuty: false);
      await tester.ensureVisible(
        find.byType(HomeTaskPanel, skipOffstage: false),
      );
      await tester.pumpAndSettle();
      for (final queue in TaskQueue.values) {
        final choice = find.byKey(ValueKey('task-queue-${queue.name}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        expect(find.text(queue.label), findsOneWidget);
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('task-queue-pickups')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-queue-pickups')));
      await tester.pumpAndSettle();
      expect(h.controller.queue, TaskQueue.pickups);
      expect(h.controller.homeData.data!.onDuty, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  managedDashboardTest(
    'wide dashboard uses a side panel and supports a resize to phone',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester);
      await tapHome(tester, find.byTooltip('Search tasks'));
      await tester.enterText(
        find.byKey(const ValueKey('task-search')),
        h.task.tracking,
      );
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(
        tester.getRect(find.byType(HomeTaskPanel)).left,
        greaterThan(tester.getRect(find.byType(FlutterMap)).right),
      );
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(h.controller.taskSearch, h.task.tracking);
      await tester.ensureVisible(
        find.byKey(const ValueKey('task-search'), skipOffstage: false),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('task-search')))
            .controller!
            .text,
        h.task.tracking,
      );
      expect(tester.takeException(), isNull);
    },
  );
  managedDashboardTest(
    'missing coordinates preserve the stop address without creating a marker',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester, coordinates: false);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      final row = find.byKey(ValueKey('home-task-${h.task.id}'));
      await tapHome(tester, row);
      expect(find.text('Address only · no saved map pin'), findsOneWidget);
      expect(find.text(h.task.stop.address!), findsWidgets);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
    },
  );

  managedDashboardTest(
    'a fresh hidden task removes its cached pin and stops its route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester);
      h.navigation.task = h.task;
      h.navigation.active = true;
      h.navigation.road = RoadRoute([
        [const LatLng(14.6, 120.986), const LatLng(14.601, 120.987)],
      ]);
      h.navigation.recenter();
      await tester.pumpAndSettle();
      expect(find.byType(PolylineLayer), findsOneWidget);
      h.api.respond = (path, method, data, headers) async =>
          throw const AccountFailure('Task hidden', status: 404);
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await tester.pumpAndSettle();
      expect(h.controller.selectedTask, isNull);
      expect(h.controller.taskData.data, isEmpty);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      expect(h.navigation.active, false);
      expect(find.byType(PolylineLayer), findsNothing);
    },
  );
  managedDashboardTest('refresh controls recover after the server cooldown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final h = await openDashboard(tester);
    final response = h.api.respond;
    h.api.respond = (path, method, data, headers) {
      if (path == 'rider/home') {
        throw const AccountFailure(
          'Please wait before refreshing.',
          status: 429,
          retryAfterSeconds: 2,
        );
      }
      return response(path, method, data, headers);
    };
    await h.controller.refreshAll();
    await tester.pump();
    final button = find.byKey(const ValueKey('home-refresh-tasks'));
    await revealHome(tester, button);
    await tester.pump();
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    expect(h.controller.taskData.data, isNotEmpty);
    h.api.respond = response;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(h.controller.workFailure, isNull);
    await revealHome(tester, button);
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
  for (final mapless in [false, true]) {
    managedDashboardTest(
      'refresh invalidation stops navigation in a ${mapless ? 'mapless keyboard' : 'hidden Home'} view',
      (tester) async {
        tester.view.physicalSize = Size(390, mapless ? 320 : 844);
        tester.view.devicePixelRatio = 1;
        final h = await openDashboard(tester, hidden: !mapless);
        await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
        h.navigation.task = h.task;
        h.navigation.active = true;
        h.navigation.road = RoadRoute([
          [const LatLng(14.6, 120.986), const LatLng(14.601, 120.987)],
        ]);
        h.navigation.recenter();
        await tester.pumpAndSettle();
        if (mapless) {
          expect(find.byType(FlutterMap), findsNothing);
        } else {
          expect(find.text('Another screen'), findsOneWidget);
          expect(find.byType(HomeDashboard), findsNothing);
        }
        final response = h.api.respond;
        h.api.respond = (path, method, data, headers) {
          if (path.startsWith('rider/tasks/')) {
            throw const AccountFailure('Task hidden', status: 404);
          }
          return response(path, method, data, headers);
        };
        await h.controller.refreshTasks();
        // No frame or periodic authorization check is needed to stop.
        expect(h.navigation.active, isFalse);
        expect(h.navigation.road, isNull);
        expect(h.controller.selectedTask, isNull);
        expect(h.controller.visibleTasks, isEmpty);
        await tester.pumpAndSettle();
        final layers = find.byType(MarkerLayer, skipOffstage: false);
        if (layers.evaluate().isNotEmpty) {
          expect(tester.widget<MarkerLayer>(layers).markers, isEmpty);
        }
        expect(find.byType(PolylineLayer, skipOffstage: false), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  managedDashboardTest(
    'hidden Home cancels tile scopes, keeps navigation and restores the panned camera',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final visibility = ValueNotifier(true), geo = MemoryTiles();
      addTearDown(visibility.dispose);
      final h = await openDashboard(
        tester,
        visibility: visibility,
        geoClient: geo,
      );
      expect(geo.calls, isNotEmpty);
      expect(
        geo.calls.every((c) => c.z == 15),
        isTrue,
        reason: 'No discarded wide-overview tile requests',
      );
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await h.navigation.start(
        h.task,
        chosenProfile: NavigationProfile.motorcycle,
        manualOrigin: const LatLng(14.6, 120.986),
      );
      await tester.pumpAndSettle();
      final map = find.byType(FlutterMap, skipOffstage: false);
      await tester.dragFrom(
        tester.getTopLeft(map) + const Offset(30, 120),
        const Offset(70, 0),
      );
      await tester.pumpAndSettle();
      expect(h.navigation.following, isFalse);
      tester.widget<FlutterMap>(map).mapController!.rotate(20);
      await tester.pumpAndSettle();
      final before = tester
          .widget<FlutterMap>(map)
          .mapController!
          .camera
          .center;
      final requests = geo.calls.length;
      final oldTokens = geo.tokens.toList();
      visibility.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);
      expect(oldTokens.every((t) => t.isCancelled), isTrue);
      await h.navigation.updateFix(
        LocationFix(const LatLng(14.6001, 120.986), DateTime.now(), 0),
      );
      await tester.pumpAndSettle();
      expect(h.navigation.active, isTrue);
      expect(h.navigation.fix?.point.latitude, 14.6001);
      expect(geo.calls.length, requests);
      visibility.value = true;
      await tester.pumpAndSettle();
      final restored = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera
          .center;
      expect(restored.latitude, closeTo(before.latitude, .000001));
      expect(restored.longitude, closeTo(before.longitude, .000001));
      expect(h.navigation.following, isFalse);
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
            .mapController!
            .camera
            .rotation,
        closeTo(20, .001),
      );
      await tapHome(tester, find.byTooltip('Recenter'));
      await tester.pumpAndSettle();
      expect(h.navigation.following, isTrue);
      final recentered = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera;
      expect(
        recentered.visibleBounds.contains(h.navigation.fix!.point),
        isTrue,
      );
      expect(recentered.visibleBounds.contains(h.navigation.target!), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  managedDashboardTest(
    'keyboard-constrained Home suspends tiles and keeps map feedback and credits readable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final geo = MemoryTiles();
      await openDashboard(tester, geoClient: geo);
      final requests = geo.calls.length;
      geo.showFailure();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 320);
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);
      await revealHome(tester, find.text('Synthetic map connection failure'));
      expect(find.text('Synthetic map connection failure'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Powered by Geoapify'),
        80,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('home-page-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      expect(geo.calls.length, requests);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await revealHome(tester, find.byType(FlutterMap));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  managedDashboardTest(
    'explicit map retry reloads only tile scope and remains bounded',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final geo = MemoryTiles();
      await openDashboard(tester, geoClient: geo);
      final initial = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera
          .center;
      geo.showFailure();
      await tester.pumpAndSettle();
      final retry = find.byKey(const ValueKey('home-retry-map'));
      await revealHome(tester, retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(geo.tileRevision, 1);
      expect(tester.widget<TextButton>(retry).onPressed, isNull);
      final current = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera
          .center;
      expect(current, initial);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'unfamiliar stage codes remain unknown rather than granting a task state',
    () {
      expect(taskStageLabel('future_state'), 'Unknown work stage');
      expect(taskStageLabel('picked_up'), 'Bring to origin hub');
      expect(stopKindLabel('destination_hub'), 'Destination hub');
    },
  );
  managedDashboardTest(
    'filtering keeps the selected owned stop and its camera',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester);
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await tester.pumpAndSettle();
      final before = tester
          .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
          .mapController!
          .camera
          .center;
      h.controller.searchTasks('No matching parcel');
      await tester.pumpAndSettle();
      expect(h.controller.visibleTasks, isEmpty);
      expect(find.byKey(ValueKey('home-marker-${h.task.id}')), findsOneWidget);
      expect(h.controller.selectedTask?.id, h.task.id);
      await revealHome(
        tester,
        find.text(
          'Your selected stop stays on the map while you browse this list.',
        ),
      );
      expect(
        find.text(
          'Your selected stop stays on the map while you browse this list.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
            .mapController!
            .camera
            .center,
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );
  managedDashboardTest(
    'outside-outline coordinates keep their original address and fallback',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester, stopPoint: const LatLng(6, 116));
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await tester.pumpAndSettle();
      expect(h.controller.selectedTask?.stop.latitude, 6);
      expect(h.controller.selectedTask?.stop.longitude, 116);
      await revealHome(tester, find.textContaining('outside this PH outline'));
      expect(find.textContaining('outside this PH outline'), findsOneWidget);
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
            .mapController!
            .camera
            .center,
        isNot(const LatLng(6, 116)),
      );
      final details = find.byKey(
        const ValueKey('home-selected-details'),
        skipOffstage: false,
      );
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text(h.task.stop.address!), findsWidgets);
      Navigator.of(tester.element(find.text(h.task.stop.address!).first)).pop();
      await tester.pumpAndSettle();
      expect(h.navigation.active, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  managedDashboardTest(
    'sharper labels replace only tile work and preserve active navigation and pan',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final geo = MemoryTiles(),
          h = await openDashboard(tester, geoClient: geo);
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await h.navigation.start(
        h.task,
        chosenProfile: NavigationProfile.motorcycle,
        manualOrigin: const LatLng(14.6, 120.986),
      );
      await tester.pumpAndSettle();
      final map = find.byType(FlutterMap, skipOffstage: false);
      await tester.dragFrom(
        tester.getTopLeft(map) + const Offset(30, 120),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      final before = tester
          .widget<FlutterMap>(map)
          .mapController!
          .camera
          .center;
      final road = h.navigation.road, oldTokens = geo.tokens.toList();
      final toggle = find.byKey(const ValueKey('home-sharper-labels'));
      await revealHome(tester, toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(geo.sources.any((s) => s.retina), isTrue);
      expect(oldTokens.every((t) => t.isCancelled), isTrue);
      expect(
        tester.widget<FlutterMap>(map).mapController!.camera.center,
        before,
      );
      expect(h.navigation.road, same(road));
      expect(h.navigation.active, isTrue);
      expect(h.navigation.following, isFalse);
      expect(tester.takeException(), isNull);
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
    manual: true,
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
    geo.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  };
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        geoapifyProvider.overrideWithValue(geo),
        navigationProvider.overrideWithValue(nav),
        philippinesMapRegionProvider.overrideWithValue(AsyncData(region)),
      ],
      child: MaterialApp(
        theme: buildRiderTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize,
            textScaler: TextScaler.linear(textScale),
          ),
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
