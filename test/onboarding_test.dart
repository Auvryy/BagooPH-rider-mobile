import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/ui/argon_widgets.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
  });

  testWidgets(
    'first app launch greets unauthenticated rider with Bagoo Argon onboarding',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          ],
          child: const BagooRiderApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify pure white canvas, 6 curated die-cut stickers, 72x72 LiquidGlassOrb,
      // AnimatedStrikeText editorial core, and pill CTA button.
      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('rider-onboarding-page')),
      );
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));

      expect(RiderOnboardingPage.buildStickers().length, 6);
      expect(find.byType(DieCutStickerWidget), findsAtLeastNWidgets(6));
      expect(find.text("Let's roll."), findsOneWidget);
      expect(find.text('Every stop clear!'), findsOneWidget);

      final orbFinder = find.byKey(const ValueKey('onboarding-liquid-orb'));
      expect(orbFinder, findsOneWidget);
      expect(tester.getSize(orbFinder), const Size(72, 72));
      expect(
        find.descendant(of: orbFinder, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: orbFinder, matching: find.byType(ClipOval)),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('onboarding-editorial-text')),
        findsOneWidget,
      );
      expect(find.text('Go beyond the'), findsOneWidget);
      expect(find.text('ordinary'), findsOneWidget);
      expect(find.text('every route'), findsOneWidget);
      expect(find.text('to deliver every parcel right'), findsOneWidget);

      final ctaFinder = find.byKey(const ValueKey('onboarding-cta'));
      expect(ctaFinder, findsOneWidget);
      expect(tester.getSize(ctaFinder).height, 56);

      // Tapping the pill CTA transitions cleanly to LoginPage
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '4-stage choreography, 2D magnetic touch parallax, and orb scatter spring physics work',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: const RiderOnboardingPage(ambientTimeOverride: 0.0),
          ),
        ),
      );

      // Stage 1 (t = 100ms): splash orb is still morphing upward toward center
      await tester.pump(const Duration(milliseconds: 100));
      final earlyOrbCenter = tester.getCenter(
        find.byKey(const ValueKey('onboarding-liquid-orb')),
      );

      // Advance past Stage 1, 2, 4 (1300ms total)
      await tester.pumpAndSettle();
      final settledOrbCenter = tester.getCenter(
        find.byKey(const ValueKey('onboarding-liquid-orb')),
      );
      expect(settledOrbCenter.dy, lessThan(earlyOrbCenter.dy));

      // Record sticker position before interactive drag parallax
      final stickerFinder = find.byKey(const ValueKey('sticker-speech-roll'));
      final beforeDrag = tester.getCenter(stickerFinder);

      // Drag across the sticker vortex to apply 2D magnetic parallax offset
      final vortex = find.byKey(const ValueKey('onboarding-sticker-vortex'));
      final gesture = await tester.startGesture(tester.getCenter(vortex));
      await gesture.moveBy(const Offset(40, -25));
      await tester.pump();
      final duringDrag = tester.getCenter(stickerFinder);
      expect(duringDrag, isNot(equals(beforeDrag)));

      // Release finger: SpringSimulation returns sticker to settled coordinate
      await gesture.up();
      await tester.pumpAndSettle();
      final afterDragSpring = tester.getCenter(stickerFinder);
      expect(afterDragSpring.dx, closeTo(beforeDrag.dx, 0.5));
      expect(afterDragSpring.dy, closeTo(beforeDrag.dy, 0.5));

      // Tap the central 72x72 LiquidGlassOrb: scatters stickers outward then springs back
      await tester.tap(find.byKey(const ValueKey('onboarding-liquid-orb')));
      await tester.pump(const Duration(milliseconds: 16));
      final scatteredCenter = tester.getCenter(stickerFinder);
      expect(scatteredCenter, isNot(equals(beforeDrag)));

      await tester.pumpAndSettle();
      final recoveredCenter = tester.getCenter(stickerFinder);
      expect(recoveredCenter.dx, closeTo(beforeDrag.dx, 0.5));
      expect(recoveredCenter.dy, closeTo(beforeDrag.dy, 0.5));

      // Stage 3 sinusoidal ambient drift changes vertical position when phase advances
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: const RiderOnboardingPage(ambientTimeOverride: 0.85),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final driftedCenter = tester.getCenter(stickerFinder);
      expect(driftedCenter.dy, isNot(closeTo(beforeDrag.dy, 0.1)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'onboarding respects reduced motion and supports direct registration link',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var openedApply = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: RiderOnboardingPage(onApply: () => openedApply = true),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('every route'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-apply-link')));
      await tester.pump();
      expect(openedApply, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'app open always pops up Argon onboarding even when a rider session is already saved',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = TestAuthRepository()
        ..account = TestAuthRepository.approved;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
          child: const BagooRiderApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Onboarding always appears first on app launch even when logged in
      expect(
        find.byKey(const ValueKey('rider-onboarding-page')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('rider-workspace')), findsNothing);

      // Tapping Enter Rider Workspace opens the authenticated RiderWorkspaceShell
      await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rider-workspace')), findsOneWidget);
      expect(find.text('Welcome, Test Rider.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
