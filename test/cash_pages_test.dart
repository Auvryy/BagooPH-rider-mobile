import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/cash/presentation/cash_controller.dart';
import 'package:bagoo_rider_mobile/features/cash/presentation/cash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cash_support.dart';

const renderKey = ValueKey('cash-render');
Future<void> render(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RIDER_WORK_RENDER')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(renderKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/cash-verification/screens');
    await dir.create(recursive: true);
    await File('${dir.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> mount(
  WidgetTester tester,
  CashController c, {
  String? id,
  double scale = 2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildRiderTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: renderKey, child: child!),
      ),
      home: CashPageView(controller: c, initialAccountId: id),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder f) async {
  // Long journal content is built lazily; scroll until a target is mounted.
  await tester.scrollUntilVisible(
    f,
    220,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 100,
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await reveal(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('RIDER_WORK_RENDER')) return;
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [320.0, 840.0]) {
    testWidgets(
      'cash journal and offer review at width $width with 200 percent text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = CashHarness(), c = CashController(null);
        c.dispose();
        final controller = CashController(h.repository);
        addTearDown(controller.dispose);
        await mount(tester, controller);
        expect(find.text('Your cash responsibility'), findsOneWidget);
        expect(controller.page, isNotNull);
        await render(tester, 'cash-dashboard-${width.toInt()}');
        await tap(tester, find.byKey(ValueKey('cash-account-${h.account.id}')));
        expect(controller.detail, isNotNull);
        await reveal(tester, find.byKey(const ValueKey('cash-offer-amount')));
        await tester.enterText(
          find.byKey(const ValueKey('cash-offer-amount')),
          '125.00',
        );
        await tester.pumpAndSettle();
        await tap(tester, find.text('Test Hub Recipient'));
        await reveal(tester, find.byKey(const ValueKey('cash-offer-evidence')));
        await tester.enterText(
          find.byKey(const ValueKey('cash-offer-evidence')),
          'TEST-HANDOVER-01',
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('cash-review-offer')));
        await reveal(tester, find.byKey(const ValueKey('cash-confirm-offer')));
        await render(tester, 'cash-review-${width.toInt()}');
        expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
        await tester.tap(find.byKey(const ValueKey('cash-confirm-offer')));
        await tester.pumpAndSettle();
        expect(h.api.calls.where((r) => r.method == 'POST').length, 1);
        expect(h.journal.value, isNull);
        expect(controller.detail!.held.toString(), '12500');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'ordinary phone dashboard and offer review remain readable at normal text size',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = CashHarness();
      h.api.respond = (p, m, b, headers) async {
        if (p.startsWith('rider/cash?')) {
          final page = cashPageFixture();
          page['summary']['own_held_cents'] = '12500';
          return {'data': page};
        }
        return h.respond(p, m, b, headers);
      };
      final c = CashController(h.repository);
      addTearDown(c.dispose);
      await mount(tester, c, scale: 1);
      await render(tester, 'cash-dashboard-390-normal');
      await tap(tester, find.byKey(ValueKey('cash-account-${h.account.id}')));
      await reveal(tester, find.byKey(const ValueKey('cash-offer-amount')));
      await tester.enterText(
        find.byKey(const ValueKey('cash-offer-amount')),
        '125.00',
      );
      await tap(tester, find.text('Test Hub Recipient'));
      await reveal(tester, find.byKey(const ValueKey('cash-offer-evidence')));
      await tester.enterText(
        find.byKey(const ValueKey('cash-offer-evidence')),
        'TEST-HANDOVER-01',
      );
      await tap(tester, find.byKey(const ValueKey('cash-review-offer')));
      await reveal(tester, find.text('Review cash offer'));
      await render(tester, 'cash-review-390-normal');
      expect(tester.takeException(), isNull);
      expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'cash journal uses labelled Manila time across UTC day boundary',
    (tester) async {
      final h = CashHarness();
      h.json['recorded_at'] = '2026-10-22T20:15:00.000Z';
      h.json['history'][0]['recorded_at'] = '2026-10-22T20:15:00.000Z';
      final c = CashController(h.repository);
      addTearDown(c.dispose);
      await mount(tester, c, id: h.account.id, scale: 1);
      final label = find.text('Oct 23, 2026 · 4:15 AM (Manila)');
      await reveal(tester, label);
      expect(label, findsOneWidget);
      expect(find.textContaining('2026-10-22 20:15'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('cash gate-off page has real balances and no active offer form', (
    tester,
  ) async {
    final h = CashHarness();
    final c = CashController(h.restart(enabled: false));
    addTearDown(c.dispose);
    await mount(tester, c, id: h.account.id);
    expect(c.detail, isNotNull);
    await reveal(tester, find.text('Cash offers unavailable'));
    expect(find.byKey(const ValueKey('cash-review-offer')), findsNothing);
    expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'background drops private cash values and draft; resume requires fresh read',
    (tester) async {
      final h = CashHarness();
      final controller = CashController(h.repository);
      addTearDown(controller.dispose);
      await mount(tester, controller, id: h.account.id);
      await reveal(tester, find.byKey(const ValueKey('cash-offer-evidence')));
      await tester.enterText(
        find.byKey(const ValueKey('cash-offer-evidence')),
        'PRIVATE-DRAFT-TEST',
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(controller.detail, isNull);
      expect(find.text('PRIVATE-DRAFT-TEST'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(controller.detail, isNotNull);
      await reveal(tester, find.byKey(const ValueKey('cash-offer-evidence')));
      expect(find.text('PRIVATE-DRAFT-TEST'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
