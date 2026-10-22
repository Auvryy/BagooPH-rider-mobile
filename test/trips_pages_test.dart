import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/ui/private_image.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/trips/presentation/trip_detail_page.dart';
import 'package:bagoo_rider_mobile/features/trips/presentation/trips_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';
import 'support/trip_support.dart';

const _capture = ValueKey('trip-capture');
Future<void> _render(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RIDER_WORK_RENDER')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/operations-delivery-verification/screens');
    await dir.create(recursive: true);
    await File('${dir.path}/$name.png').writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
}

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: buildRiderTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: RepaintBoundary(key: _capture, child: child!),
  ),
  home: home,
);
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
  for (final (size, scale) in [
    (const Size(320, 800), 2.0),
    (const Size(375, 812), 1.0),
    (const Size(900, 480), 2.0),
  ]) {
    testWidgets(
      'retained Trips and original detail scroll at $size with ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = TripHarness();
        addTearDown(h.dispose);
        await tester.runAsync(h.boot);
        await tester.pumpWidget(
          _app(
            ListenableBuilder(
              listenable: h.work,
              builder: (_, _) =>
                  Scaffold(body: TripsPage(controller: h.work, preview: false)),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Your retained assignments'), findsOneWidget);
        expect(find.text('Manila assignment dates'), findsOneWidget);
        await _render(tester, 'trips-${size.width.toInt()}-${scale}x');
        final card = find.byKey(const ValueKey('trip-trip-41'));
        final scroll = find.byType(Scrollable).first;
        final payment = find.byKey(const ValueKey('trip-payment-cod'));
        await tester.scrollUntilVisible(payment, 180, scrollable: scroll);
        expect(tester.getSize(payment).height, greaterThanOrEqualTo(48));
        await tester.scrollUntilVisible(card, 200, scrollable: scroll);
        await tester.pumpAndSettle();
        expect(find.text('Recorded collection: ₱125.00'), findsOneWidget);
        await tester.pumpWidget(
          _app(
            TripDetailPage(work: h.work, id: 'trip-41'),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Your original assignment'), findsOneWidget);
        await _render(tester, 'trip-detail-${size.width.toInt()}-${scale}x');
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        h.dispose();
      },
    );
  }
  testWidgets(
    'private proof is cleared on background and requires fresh deliberate opening after resume',
    (tester) async {
      final h = TripHarness();
      addTearDown(h.dispose);
      await tester.runAsync(h.boot);
      await tester.pumpWidget(
        _app(TripDetailPage(work: h.work, id: 'trip-41')),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('View private proof'));
      expect(find.byType(PrivateImage), findsOneWidget);
      await _render(tester, 'trip-private-proof');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.byType(PrivateImage), findsNothing);
      expect(
        find.textContaining('Return to Rider to revalidate'),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(PrivateImage), findsNothing);
      expect(h.api.downloads.length, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Your original assignment'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  testWidgets(
    'retained wallet history shows only returned recipient and cash facts',
    (tester) async {
      final h = TripHarness();
      addTearDown(h.dispose);
      h.rows = [
        retainedTripJson(recipient: null, cents: null)
          ..['payment_method'] = 'wallet',
      ];
      await tester.runAsync(h.boot);
      await tester.pumpWidget(
        _app(TripDetailPage(work: h.work, id: 'trip-41')),
      );
      await tester.pumpAndSettle();
      final payment = find.text('Payment: Bagoo Wallet');
      await tester.ensureVisible(payment);
      await tester.pumpAndSettle();
      expect(payment, findsOneWidget);
      expect(
        find.text('Recipient details are unavailable for this assignment.'),
        findsOneWidget,
      );
      expect(
        find.text('No cash collection is recorded for this assignment.'),
        findsOneWidget,
      );
      expect(find.textContaining('Recorded collection: ₱0'), findsNothing);
      expect(find.textContaining('Recorded recipient:'), findsNothing);
      expect(tester.takeException(), isNull);
      await _render(tester, 'prepaid-retained-trip');
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
  testWidgets(
    'logout removes the original detail and any proof route above it',
    (tester) async {
      final h = TripHarness();
      addTearDown(h.dispose);
      await tester.runAsync(h.boot);
      final auth = TestAuthRepository()..account = TestAuthRepository.approved;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(
            ListenableBuilder(
              listenable: h.work,
              builder: (_, _) =>
                  Scaffold(body: TripsPage(controller: h.work, preview: false)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('trip-trip-41'));
      await tester.scrollUntilVisible(
        card,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(tester, card);
      await _tap(tester, find.text('View private proof'));
      expect(find.byType(PrivateImage), findsOneWidget);
      await container.read(authControllerProvider.notifier).logout();
      await tester.pump();
      expect(find.byType(PrivateImage), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(TripDetailPage), findsNothing);
      expect(find.byType(PrivateImage), findsNothing);
      expect(find.byType(TripsPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      h.dispose();
    },
  );
}
