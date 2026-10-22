import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_mode_page.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/notifications/presentation/notifications_entry.dart';
import 'package:bagoo_rider_mobile/features/notifications/presentation/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/notifications_support.dart';
import 'support/cash_support.dart';
import 'support/test_auth_repository.dart';
import 'operations_contract_test.dart' as ops;

final capture = GlobalKey();
const account = RiderAccount(
  id: '5',
  name: 'Example rider',
  email: 'rider@example.test',
  status: 'active',
  kycStatus: 'approved',
  approved: true,
  emailVerified: true,
  operationsApiVersion: 1,
);
Widget app(
  NotificationsHarness h, {
  double scale = 1,
  bool entry = false,
  TestAuthRepository? auth,
  NavigationController? navigation,
}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      auth ?? (TestAuthRepository()..account = account),
    ),
    if (navigation != null) navigationProvider.overrideWithValue(navigation),
  ],
  child: MaterialApp(
    theme: buildRiderTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: RepaintBoundary(key: capture, child: child!),
    ),
    home: entry
        ? Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: NotificationsEntry(work: h.work!, active: true),
              ),
            ),
          )
        : NotificationsPage(work: h.work!),
  ),
);
Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> render(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(capture),
  );
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  repaint(boundary);
  await tester.pump();
  await tester.runAsync(() async {
    final picture = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/notifications-verification/ui');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    final previous = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = previous);
  });
  for (final (size, scale) in [
    (const Size(320, 740), 2.0),
    (const Size(375, 812), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(900, 600), 2.0),
    (const Size(1200, 850), 1.0),
  ]) {
    testWidgets(
      'inbox and detail remain readable at $size with ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = NotificationsHarness(workspace: true);
        addTearDown(h.dispose);
        h.rows = [
          notificationJson(
            3,
            title: 'Your pickup assignment was updated',
            body: 'Review this parcel’s current stop and custody before continuing. Your notification stays available after you leave this screen.',
          ),
          notificationJson(2),
          notificationJson(1),
        ];
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(app(h, scale: scale));
          await tester.pumpAndSettle();
          expect(find.text('3 unread notifications'), findsOneWidget);
          expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
          await render(tester, 'inbox-${size.width.toInt()}-${scale}x');
          await tap(tester, 'notification-${noticeId(3)}');
          expect(find.text('Your update'), findsOneWidget);
          final read = find.byKey(const ValueKey('read-one-notification'));
          await tester.ensureVisible(read);
          await tester.pumpAndSettle();
          expect(tester.getSize(read).height, greaterThanOrEqualTo(48));
          expect(
            tester.getSemantics(read),
            matchesSemantics(
              isButton: true,
              isEnabled: true,
              hasEnabledState: true,
              isFocusable: true,
              label: 'Mark as read',
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
          await render(tester, 'detail-${size.width.toInt()}-${scale}x');
          if (size.width == 375) {
            Focus.of(tester.element(find.text('Mark as read'))).requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
            expect(h.controller.selected!.unread, isFalse);
          } else {
            await tap(tester, 'read-one-notification');
            expect(h.controller.selected!.unread, isFalse);
          }
          await tester.tap(find.byTooltip('Back to notifications'));
          await tester.pumpAndSettle();
          expect(find.text('2 unread notifications'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets(
    'bulk action includes actual viewport items and excludes cached offscreen cards and new arrivals',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      h.rows = List.generate(20, (i) => notificationJson(20 - i));
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      final readVisible = find.byKey(
        const ValueKey('read-visible-notifications'),
      );
      await tester.ensureVisible(readVisible);
      await tester.pumpAndSettle();
      final visible = Set<String>.of(h.controller.displayedUnreadIds);
      expect(visible, isNotEmpty);
      expect(visible.length, lessThan(20));
      h.rows.insert(0, notificationJson(21));
      await tester.tap(readVisible);
      await tester.pumpAndSettle();
      final post = h.api.calls.singleWhere((c) => c.method == 'POST');
      final ids = post.path.endsWith('/read-through')
          ? (post.data as Map)['displayed_ids'] as List
          : [post.path.split('/')[2]];
      expect(ids.toSet(), visible);
      expect(ids, isNot(contains(noticeId(21))));
      expect(h.rows.first['read_at'], isNull);
      expect(h.controller.unreadCount, 21 - visible.length);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Home badge uses all-owned unread count and its native button opens by keyboard',
    (tester) async {
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      h.rows = List.generate(105, (i) => notificationJson(105 - i));
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(app(h, entry: true));
        await tester.pumpAndSettle();
        expect(find.text('105 unread'), findsOneWidget);
        expect(find.text('99+'), findsOneWidget);
        expect(h.controller.inbox.data, hasLength(20));
        final button = find.byKey(const ValueKey('open-notifications'));
        final node = tester.getSemantics(button).getSemanticsData();
        expect(node.label, contains('105 unread'));
        expect(node.hasAction(ui.SemanticsAction.tap), isTrue);
        Focus.of(tester.element(find.text('Notifications'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsPage), findsOneWidget);
        expect(find.text('105 unread notifications'), findsOneWidget);
        expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'covering inbox stops reads, background clears private copy, resume fetches again',
    (tester) async {
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      final navigator = Navigator.of(tester.element(find.text('Inbox')));
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Another screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(h.controller.inboxActive, isFalse);
      final posts = h.api.calls.where((c) => c.method == 'POST').length;
      await h.controller.acknowledgeDisplayed([
        noticeId(3),
      ], h.controller.revision);
      expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(posts));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(h.controller.inboxActive, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(h.controller.inbox.data, isNull);
      expect(find.text('Your parcel update 3'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(find.text('Your parcel update 3'), findsNothing);
      expect(h.controller.inbox.data, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.controller.inbox.data, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'unknown and denied destinations keep the notice readable and do not acknowledge on open',
    (tester) async {
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      await tap(tester, 'notification-${noticeId(2)}');
      expect(
        find.text(
          'No current in-app destination is available for this update.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back to notifications'));
      await tester.pumpAndSettle();
      await tap(tester, 'notification-${noticeId(3)}');
      h.api.respond = (path, method, body, headers) async {
        if (path.startsWith('rider/tasks/')) {
          throw const AccountFailure('No longer owned', status: 404);
        }
        return h.respond(path, method, body, headers);
      };
      await tap(tester, 'open-notification-target');
      expect(
        find.text(
          'This linked item is no longer available. The notification remains here.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your parcel update 3'), findsOneWidget);
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'account replacement closes the inbox route and clears its private data',
    (tester) async {
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      final auth = TestAuthRepository()..account = account;
      await tester.pumpWidget(app(h, entry: true, auth: auth));
      await tester.pumpAndSettle();
      await tap(tester, 'open-notifications');
      final context = tester.element(find.byType(NotificationsPage));
      final container = ProviderScope.containerOf(context);
      await container.read(authControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPage), findsNothing);
      expect(h.controller.inbox.data, isNull);
      expect(h.controller.unreadCount, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'an owned task link enters existing Stop Mode and rechecks detail without reading the notice',
    (tester) async {
      final h = NotificationsHarness(workspace: true, realWork: true);
      addTearDown(h.dispose);
      h.api.respond = (path, method, body, headers) async {
        if (path.startsWith('rider/tasks?') ||
            path.startsWith('rider/pickup-jobs?')) {
          return {
            'data': {
              'items': path.startsWith('rider/tasks?')
                  ? [ops.fixture('final-mile-task')['data']]
                  : [],
              'pagination': {
                'page': 1,
                'per_page': 20,
                'total': 1,
                'last_page': 1,
              },
            },
          };
        }
        if (path.startsWith('rider/trips')) {
          throw const AccountFailure('Trips unavailable', status: 503);
        }
        return h.respond(path, method, body, headers);
      };
      final routes = GeoapifyClient('');
      addTearDown(routes.dispose);
      final nav = NavigationController(
        routes: routes,
        authorize: h.operations.detail,
        vehicleType: () async => 'motorcycle',
        manual: true,
      );
      addTearDown(nav.dispose);
      await tester.pumpWidget(app(h, navigation: nav));
      await tester.pumpAndSettle();
      await tap(tester, 'notification-${noticeId(3)}');
      await tap(tester, 'open-notification-target');
      expect(find.byType(StopModePage), findsOneWidget);
      expect(h.work!.selectedTask!.id, 'final_mile-1');
      expect(
        h.api.calls.where((c) => c.path == 'rider/tasks/final_mile-1').length,
        greaterThanOrEqualTo(2),
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(nav.active, isFalse);
      expect(tester.takeException(), isNull);
      h.work!.setForeground(false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'linked cash opens the gated journal, clears on inactive and reauthorizes after resume',
    (tester) async {
      final h = NotificationsHarness(workspace: true, realWork: true);
      addTearDown(h.dispose);
      h.rows = [
        notificationJson(
          1,
          target: {'kind': 'cash', 'id': '7', 'href': '/api/v1/rider/cash/7'},
        ),
      ];
      var held = '900719925474099312345';
      h.api.respond = (path, method, body, headers) async {
        if (path == 'rider/home') {
          final result = await h.respond(path, method, body, headers);
          result['data']['capabilities']['cash'] = true;
          return result;
        }
        if (path.startsWith('rider/cash?')) {
          final result = cashPageFixture(
            items: [cashFixture(id: '7', detail: false)],
          );
          result['summary']['own_held_cents'] = held;
          return {'data': result};
        }
        if (path == 'rider/cash/7') {
          final result = cashFixture(id: '7');
          result['tracking_number'] = 'BGO-TEST-CASH';
          result['own_held_cents'] = held;
          return {'data': result};
        }
        return h.respond(path, method, body, headers);
      };
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      await tap(tester, 'notification-${noticeId(1)}');
      await tap(tester, 'open-notification-target');
      expect(find.text('Cash & remittance'), findsOneWidget);
      expect(find.text('₱9,007,199,254,740,993,123.45'), findsWidgets);
      expect(h.api.calls.where((c) => c.method != 'GET'), isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('BGO-TEST-CASH'), findsNothing);
      expect(h.controller.inbox.data, isNull);
      held = '123';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('₱1.23'), findsWidgets);
      expect(h.api.calls.where((c) => c.path == 'rider/cash/7'), hasLength(3));
      expect(h.api.calls.where((c) => c.method != 'GET'), isEmpty);
      expect(tester.takeException(), isNull);
      await render(tester, 'linked-cash');
      h.work!.setForeground(false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'missing notification capability has no invented empty-success count and can recover',
    (tester) async {
      final h = NotificationsHarness(workspace: true);
      addTearDown(h.dispose);
      h.available = false;
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      expect(find.text('Notifications unavailable'), findsOneWidget);
      expect(find.text('0 unread notifications'), findsNothing);
      expect(h.controller.unreadCount, isNull);
      h.available = true;
      await tester.tap(find.byTooltip('Refresh notifications'));
      await tester.pumpAndSettle();
      expect(find.text('3 unread notifications'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
