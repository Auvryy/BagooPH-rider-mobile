import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:latlong2/latlong.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_dashboard.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_task_panel.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;

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
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .camera;
      expect(camera.zoom, greaterThan(12));
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-selected-details')),
      );
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
    'task row selection, panel controls, search and queue changes keep the same stop',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final h = await openDashboard(tester);
      final expand = find.byKey(const ValueKey('home-expand-panel'));
      await tester.tap(expand);
      await tester.pumpAndSettle();
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
            .widget<FlutterMap>(find.byType(FlutterMap))
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
      await tester.tap(find.byKey(const ValueKey('home-expand-panel')));
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
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(h.controller.taskSearch, h.task.tracking);
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
      await tester.tap(find.byKey(const ValueKey('home-expand-panel')));
      await tester.pumpAndSettle();
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
  test(
    'unfamiliar stage codes remain unknown rather than granting a task state',
    () {
      expect(taskStageLabel('future_state'), 'Unknown work stage');
      expect(taskStageLabel('picked_up'), 'Bring to origin hub');
      expect(stopKindLabel('destination_hub'), 'Destination hub');
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
  json['stop']['latitude'] = coordinates ? 14.6 : null;
  json['stop']['longitude'] = coordinates ? 120.986 : null;
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
  final geo = GeoapifyClient('');
  final nav = NavigationController(
    routes: geo,
    authorize: (_) async => task,
    vehicleType: () async => null,
    manual: true,
  );
  _disposeDashboard = () async {
    await tester.pumpWidget(const SizedBox.shrink());
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
      ],
      child: MaterialApp(
        theme: buildRiderTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: HomeDashboard(account: account, controller: controller),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (controller: controller, task: task, navigation: nav, api: api);
}

Future<void> Function()? _disposeDashboard;
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
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
