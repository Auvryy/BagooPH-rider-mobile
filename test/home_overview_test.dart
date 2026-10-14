import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_dashboard.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_mode_page.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/philippines_map_region.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_dashboard_test.dart' as dashboard;
import 'operations_contract_test.dart' as support;
import 'support/test_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
  });
  setUp(() {
    final old = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = old);
  });

  testWidgets(
    'overview uses returned placement, capacity, counts and PHT observation',
    (tester) async {
      final h = await _open(tester);
      expect(find.text('Example logistics company'), findsOneWidget);
      expect(find.text('Example assigned hub'), findsOneWidget);
      expect(find.text('Pickup slots: 3 of 17 in use'), findsOneWidget);
      expect(find.text('14 slots remaining'), findsOneWidget);
      expect(
        find.text('Home checked Oct 14, 2026 · 12:05 AM PHT'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('home-refresh-tasks')), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('task-queue-available')));
      for (final entry in {
        'available': '8',
        'pickups': '42',
        'delivery': '2',
      }.entries) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('task-queue-${entry.key}')),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      }
      expect(
        h.controller.taskData.data,
        hasLength(1),
        reason: 'Counts must not come from the loaded page.',
      );
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );

  testWidgets('missing placement names differ from absent assignments', (
    tester,
  ) async {
    final h = await _open(tester);
    h.home['data']['placement']['company_name'] = null;
    h.home['data']['placement']['hub_name'] = ' ';
    await h.controller.refreshAll();
    await tester.pumpAndSettle();
    expect(find.text('Company name unavailable'), findsOneWidget);
    expect(find.text('Hub name unavailable'), findsOneWidget);
    expect(find.text('Hub not assigned'), findsNothing);
    h.home['data']['placement']['company_id'] = null;
    h.home['data']['placement']['hub_id'] = null;
    h.home['data']['placement']['barangay'] = null;
    h.home['data']['eligibility']['operational'] = false;
    h.home['data']['eligibility']['can_claim'] = false;
    h.home['data']['eligibility']['claim_denial'] = 'PLACEMENT_UNAVAILABLE';
    await h.controller.refreshAll();
    await tester.pumpAndSettle();
    expect(find.text('Company not assigned'), findsOneWidget);
    expect(find.text('Hub not assigned'), findsOneWidget);
    expect(find.text('Coverage not assigned'), findsOneWidget);
    expect(
      find.text('Your company or hub assignment needs attention.'),
      findsOneWidget,
    );
    expect(h.controller.canWrite, isFalse);
  });

  testWidgets(
    'refresh retains observed values, blocks repeat refresh and keeps explicit queue',
    (tester) async {
      final h = await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('task-queue-pickups')));
      expect(h.controller.queue, TaskQueue.pickups);
      final gate = Completer<Map<String, dynamic>>();
      h.homeGate = gate;
      final reads = h.homeReads;
      await _tap(
        tester,
        find.byKey(const ValueKey('home-refresh-tasks')),
        settle: false,
      );
      expect(h.homeReads, reads + 1);
      expect(
        find.text('Refreshing work · showing last checked data.'),
        findsOneWidget,
      );
      expect(
        find.text('Queue counts are from the last Home check.'),
        findsOneWidget,
      );
      expect(
        find.text('Home checked Oct 14, 2026 · 12:05 AM PHT'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('home-refresh-tasks')),
            )
            .onPressed,
        isNull,
      );
      await h.controller.refreshAll();
      expect(h.homeReads, reads + 1);
      h.home['data']['observed_at'] = '2026-10-14T02:12:00.000Z';
      h.home['data']['counts'] = {'available': 3, 'pickup': 2, 'final_mile': 1};
      h.homeGate = null;
      gate.complete(h.home);
      await tester.pumpAndSettle();
      expect(h.controller.queue, TaskQueue.pickups);
      expect(
        find.text('Home checked Oct 14, 2026 · 10:12 AM PHT'),
        findsOneWidget,
      );
      expect(
        find.text('Queue counts are from the last Home check.'),
        findsNothing,
      );
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'failed refresh keeps last checked counts and recovers from the single refresh',
    (tester) async {
      final h = await _open(tester);
      h.homeError = const AccountFailure(
        'Home connection interrupted.',
        status: 503,
      );
      await _tap(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(
        find.text('Refresh failed · showing last checked data.'),
        findsOneWidget,
      );
      expect(find.text('Home connection interrupted.'), findsOneWidget);
      expect(find.text('Pickup slots: 3 of 17 in use'), findsOneWidget);
      expect(
        find.text('Home checked Oct 14, 2026 · 12:05 AM PHT'),
        findsOneWidget,
      );
      expect(h.controller.canWrite, isFalse);
      h.homeError = null;
      await _tap(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(find.text('Home connection interrupted.'), findsNothing);
      expect(
        find.text('Refresh failed · showing last checked data.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'loading and failed first reads have unknown counts; returned zeros and full capacity are real',
    (tester) async {
      final gate = Completer<Map<String, dynamic>>();
      final h = await _open(tester, firstHomeGate: gate, settle: false);
      await tester.pump();
      expect(find.text('Checking work availability…'), findsOneWidget);
      expect(find.text('Pickup capacity unavailable.'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('task-queue-available')));
      expect(find.text('—'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('home-checked-time')), findsNothing);
      h.homeGate = null;
      h.homeError = const AccountFailure(
        'First Home read failed.',
        status: 503,
      );
      gate.completeError(h.homeError!);
      await tester.pumpAndSettle();
      await _reveal(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(find.text('Could not check work availability.'), findsOneWidget);
      expect(find.text('First Home read failed.'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
      h.homeError = null;
      h.home['data']['counts'] = {'available': 0, 'pickup': 0, 'final_mile': 0};
      h.home['data']['capacity'] = {
        'active_pickups': 17,
        'pickup_limit': 17,
        'remaining_pickups': 0,
      };
      h.home['data']['eligibility']['can_claim'] = false;
      h.home['data']['eligibility']['claim_denial'] = 'PICKUP_CAPACITY';
      h.empty = true;
      await _tap(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(find.text('—'), findsNothing);
      expect(find.text('Pickup slots: 17 of 17 in use'), findsOneWidget);
      expect(find.text('0 slots remaining'), findsOneWidget);
      expect(find.text('Your pickup capacity is full.'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('task-queue-available')));
      expect(find.text('0'), findsNWidgets(3));
      await _reveal(tester, find.text('No tasks in this queue'));
      expect(find.text('No tasks in this queue'), findsOneWidget);
    },
  );

  testWidgets(
    'denied access drops stale overview quantities and selected detail',
    (tester) async {
      final h = await _open(tester);
      await h.controller.openTask(OperationsRepository.asRiderTask(h.task));
      await tester.pumpAndSettle();
      h.homeError = const AccountFailure(
        'Rider access no longer available.',
        status: 403,
      );
      await _tap(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(h.controller.homeData.status, FeatureStatus.unavailable);
      await _reveal(tester, find.byKey(const ValueKey('home-refresh-tasks')));
      expect(find.text('Work availability unavailable.'), findsOneWidget);
      expect(find.text('Pickup capacity unavailable.'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-checked-time')), findsNothing);
      expect(find.text('—'), findsNWidgets(3));
      expect(h.controller.selectedTask, isNull);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('home-refresh-tasks')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  for (final stage in ['out_for_delivery', 'future_stage']) {
    testWidgets('rows, selected stop and detail share safe labels for $stage', (
      tester,
    ) async {
      final h = await _open(tester, stage: stage);
      final label = stage == 'out_for_delivery'
          ? 'On delivery'
          : 'Unknown work stage';
      await _reveal(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
      expect(find.text(label), findsOneWidget);
      expect(find.text(stage), findsNothing);
      await _tap(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
      await _reveal(tester, find.byKey(const ValueKey('home-selected-stage')));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-selected-stage')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const ValueKey('home-selected-reference')),
            )
            .data,
        h.task.tracking,
      );
      expect(h.controller.selectedTask!.stage, stage);
      await _tap(tester, find.byKey(const ValueKey('home-selected-details')));
      expect(
        find.descendant(
          of: find.byType(StopModePage),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
      expect(find.text(stage), findsNothing);
      expect(
        find.descendant(
          of: find.byType(StopModePage),
          matching: find.text(h.task.tracking),
        ),
        findsOneWidget,
      );
      expect(h.controller.selectedTask!.stage, stage);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    });
  }

  for (final width in [320.0, 390.0, 430.0, 840.0, 1000.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'real workspace controls remain reachable at $width and ${scale * 100}% text, with keyboard',
        (tester) async {
          final h = await _open(
            tester,
            width: width,
            textScale: scale,
            shell: true,
            longText: true,
          );
          expect(find.byType(DraggableScrollableSheet), findsNothing);
          expect(
            find.byKey(const ValueKey('home-refresh-tasks')),
            findsOneWidget,
          );
          expect(find.byType(Switch), findsOneWidget);
          if (width < 840) {
            expect(
              find.byKey(const ValueKey('home-page-scroll')),
              findsOneWidget,
            );
            expect(
              find.byKey(const PageStorageKey('home-task-panel-scroll')),
              findsNothing,
            );
            expect(
              tester
                  .widget<Scaffold>(
                    find.byKey(const ValueKey('rider-workspace')),
                  )
                  .extendBody,
              isFalse,
            );
          }
          expect(
            find.text(
              'Existing pickups and assigned deliveries remain your responsibility.',
            ),
            findsOneWidget,
          );
          for (final queue in TaskQueue.values) {
            final control = find.byKey(ValueKey('task-queue-${queue.name}'));
            await _tap(tester, control);
            expect(h.controller.queue, queue);
            expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
          }
          await _tap(tester, find.byKey(ValueKey('home-task-${h.task.id}')));
          await _reveal(
            tester,
            find.byKey(const ValueKey('home-selected-reference')),
          );
          expect(
            tester
                .widget<SelectableText>(
                  find.byKey(const ValueKey('home-selected-reference')),
                )
                .data,
            h.task.tracking,
          );
          await _tap(
            tester,
            find.byKey(const ValueKey('home-selected-details')),
          );
          await _tap(tester, find.byKey(const ValueKey('stop-back')));
          if (width == 390 && scale == 1) {
            await _capture(tester, 'phone-selected-stop');
          }
          await _tap(tester, find.byTooltip('Search tasks'));
          h.keyboard.value = 300;
          await tester.pumpAndSettle();
          await _tap(tester, find.byKey(const ValueKey('task-search')));
          await tester.enterText(
            find.byKey(const ValueKey('task-search')),
            h.task.tracking,
          );
          await tester.pumpAndSettle();
          expect(h.controller.visibleTasks, hasLength(1));
          await _tap(
            tester,
            find.byKey(const ValueKey('home-selected-details')),
          );
          await _tap(tester, find.byKey(const ValueKey('stop-back')));
          h.keyboard.value = 0;
          await tester.pumpAndSettle();
          await _tap(tester, find.byKey(const ValueKey('home-refresh-tasks')));
          expect(h.controller.queue, TaskQueue.delivery);
          expect(h.controller.homeData.data!.onDuty, isFalse);
          if (width == 390 || width == 1440) {
            await _capture(
              tester,
              'overview-w${width.toInt()}-text${scale.toInt()}',
            );
          }
          expect(tester.takeException(), isNull);
          expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
        },
      );
    }
  }
}

class _Harness {
  final home = support.fixture('home');
  final finalMile =
      support.fixture('final-mile-task')['data'] as Map<String, dynamic>;
  final pickup = support.fixture('pickup-task')['data'] as Map<String, dynamic>;
  final api = support.Session();
  final keyboard = ValueNotifier(0.0);
  Completer<Map<String, dynamic>>? homeGate;
  AccountFailure? homeError;
  bool empty = false;
  int homeReads = 0;
  late final WorkspaceController controller;
  OperationTask get task => OperationTask.fromJson(finalMile);
}

PhilippinesMapRegion? _region;
Future<_Harness> _open(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  bool shell = false,
  bool longText = false,
  String stage = 'out_for_delivery',
  Completer<Map<String, dynamic>>? firstHomeGate,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  final h = _Harness()..homeGate = firstHomeGate;
  // Additive discovery in the API owner's current handover work must not
  // replace the known overview or trigger unfinished handover actions.
  h.home['data']['handover_api_version'] = 1;
  h.home['data']['capabilities']['handover_issues'] = true;
  h.home['data']['capabilities']['handover_reporting'] = true;
  h.home['data']['observed_at'] = '2026-10-13T16:05:00.000Z';
  h.home['data']['placement']['company_name'] = longText
      ? 'Example regional logistics company with a long registered company name'
      : 'Example logistics company';
  h.home['data']['placement']['hub_name'] = longText
      ? 'Example assigned destination Bayan hub with a long facility name'
      : 'Example assigned hub';
  h.home['data']['counts'] = {'available': 8, 'pickup': 42, 'final_mile': 2};
  h.home['data']['capacity'] = {
    'active_pickups': 3,
    'pickup_limit': 17,
    'remaining_pickups': 14,
  };
  h.home['data']['on_duty'] = false;
  h.home['data']['eligibility']['can_claim'] = false;
  h.home['data']['eligibility']['claim_denial'] = 'OFF_DUTY';
  h.finalMile['operational_stage'] = stage;
  h.finalMile['tracking_number'] = longText
      ? 'BGO-EXAMPLE-FULL-IDENTIFIER-012345678901234567890123456789'
      : 'BGO-EXAMPLE-FULL-IDENTIFIER-123456789';
  h.finalMile['stop']['address'] = longText
      ? 'Unit 123, Example building with a long name, Example road and neighbourhood, Example city, Philippines'
      : 'Example road, Example city';
  h.api.respond = (path, method, data, headers) async {
    if (path == 'rider/home') {
      h.homeReads++;
      if (h.homeGate != null) return h.homeGate!.future;
      if (h.homeError != null) throw h.homeError!;
      return h.home;
    }
    if (path.startsWith('rider/tasks/final_mile-')) {
      return {'data': h.finalMile};
    }
    if (path.startsWith('rider/tasks/pickup-')) return {'data': h.pickup};
    final items = h.empty || path.startsWith('rider/pickup-jobs')
        ? <Map<String, dynamic>>[]
        : [path.contains('phase=pickup') ? h.pickup : h.finalMile];
    return {
      'data': {
        'items': items,
        'pagination': {
          'page': 1,
          'per_page': 20,
          'total': items.length,
          'last_page': 1,
        },
      },
    };
  };
  final repository = OperationsRepository(
    h.api,
    accountId: '5',
    journal: support.Journal(),
    writesVerified: false,
    isCurrent: () => true,
  );
  h.controller = WorkspaceController(repository);
  final geo = GeoapifyClient('');
  final nav = NavigationController(
    routes: geo,
    authorize: (_) async => h.task,
    vehicleType: () async => null,
    manual: true,
  );
  _region ??= PhilippinesMapRegion.decode(
    File('assets/maps/philippines-display.geojson').readAsStringSync(),
  );
  // Render the bundled fallback instead of the widget runner's Ahem system font.
  // Native system-font/device acceptance remains a separate check.
  final theme = buildRiderTheme();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (h.homeGate != null && !h.homeGate!.isCompleted) {
      h.homeGate!.complete(h.home);
    }
    nav.dispose();
    geo.dispose();
    h.keyboard.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          TestAuthRepository()..account = dashboard.account,
        ),
        workspaceRepositoryProvider.overrideWithValue(repository),
        workspaceControllerProvider.overrideWith((ref, identity) {
          ref.onDispose(h.controller.dispose);
          return h.controller;
        }),
        geoapifyProvider.overrideWithValue(geo),
        navigationProvider.overrideWithValue(nav),
        philippinesMapRegionProvider.overrideWithValue(AsyncData(_region!)),
      ],
      child: MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Plus Jakarta Sans'),
          primaryTextTheme: theme.primaryTextTheme.apply(
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(
              workspaceControllerProvider(
                WorkspaceIdentity(dashboard.account.id),
              ),
            );
            return ValueListenableBuilder<double>(
              valueListenable: h.keyboard,
              builder: (context, inset, _) => MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(textScale),
                  viewInsets: EdgeInsets.only(bottom: inset),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('overview-render'),
                  child: shell
                      ? RiderWorkspaceShell(account: dashboard.account)
                      : Scaffold(
                          body: HomeDashboard(
                            account: dashboard.account,
                            controller: h.controller,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return h;
}

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await _reveal(tester, finder);
  await tester.pumpAndSettle();
  final ancestors = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  final visible = ancestors.evaluate().isEmpty
      ? tester.getRect(finder)
      : tester.getRect(finder).intersect(tester.getRect(ancestors.first));
  expect(
    visible.isEmpty,
    isFalse,
    reason: 'The control must have visible touch space.',
  );
  await tester.tapAt(visible.center);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (name.startsWith('overview-')) {
    final page = find.byKey(const ValueKey('home-page-scroll'));
    final scrollables = page.evaluate().isNotEmpty
        ? find.descendant(of: page, matching: find.byType(Scrollable))
        : find.ancestor(
            of: find.byKey(const ValueKey('home-refresh-tasks')),
            matching: find.byType(Scrollable),
          );
    if (scrollables.evaluate().isNotEmpty) {
      tester.state<ScrollableState>(scrollables.first).position.jumpTo(0);
      await tester.pumpAndSettle();
    }
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('overview-render')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/home-overview-verification/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final page = find.byKey(const ValueKey('home-page-scroll'));
    final panel = find.byKey(const PageStorageKey('home-task-panel-scroll'));
    final scrollables = find.descendant(
      of: page.evaluate().isNotEmpty ? page : panel,
      matching: find.byType(Scrollable),
    );
    if (scrollables.evaluate().isNotEmpty) {
      final position = tester
          .state<ScrollableState>(scrollables.first)
          .position;
      position.jumpTo(0);
      await tester.pump(const Duration(milliseconds: 100));
      for (var n = 0; finder.evaluate().isEmpty && n < 40; n++) {
        position.jumpTo(
          (position.pixels + 160).clamp(0, position.maxScrollExtent),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
}
