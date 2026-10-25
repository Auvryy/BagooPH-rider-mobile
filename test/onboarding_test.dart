import 'dart:async';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/login_page.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/register_page.dart';
import 'package:bagoo_rider_mobile/features/onboarding/data/onboarding_preferences.dart';
import 'package:bagoo_rider_mobile/features/onboarding/presentation/onboarding_art.dart';
import 'package:bagoo_rider_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_auth_repository.dart';

class MemoryIntroPreferences implements OnboardingPreferences {
  MemoryIntroPreferences({this.seen = false, this.pending});
  bool seen;
  Completer<bool>? pending;
  @override
  Future<bool> readSeen() async =>
      pending == null ? seen : await pending!.future;
  @override
  Future<void> writeSeen(bool value) async {
    seen = value;
  }
}

Widget introApp(MemoryIntroPreferences preferences) => ProviderScope(
  overrides: [
    onboardingPreferencesProvider.overrideWithValue(preferences),
    authRepositoryProvider.overrideWithValue(TestAuthRepository()),
  ],
  child: const BagooRiderApp(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  testWidgets(
    'a new installation has three introduction pages and opens rider registration',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final preferences = MemoryIntroPreferences();
      await tester.pumpWidget(introApp(preferences));
      await tester.pumpAndSettle();
      expect(find.text('Every parcel starts with you.'), findsOneWidget);
      expect(find.byType(OnboardingArt), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('onboarding-dot-0'))).width,
        28,
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
      await tester.pumpAndSettle();
      expect(find.text('Clear details for every stop.'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('onboarding-dot-1'))).width,
        28,
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
      await tester.pumpAndSettle();
      expect(find.text('Small updates. Clear progress.'), findsOneWidget);
      expect(find.text('Apply as a rider'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
      await tester.pumpAndSettle();
      expect(preferences.seen, isTrue);
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'sign in completes the introduction and a later launch goes directly to login',
    (tester) async {
      final preferences = MemoryIntroPreferences();
      await tester.pumpWidget(introApp(preferences));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding-sign-in')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-sign-in')));
      await tester.pumpAndSettle();
      expect(preferences.seen, isTrue);
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(introApp(preferences));
      await tester.pumpAndSettle();
      expect(find.byType(RiderOnboardingPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('skip opens the rider application and records completion', (
    tester,
  ) async {
    final preferences = MemoryIntroPreferences();
    await tester.pumpWidget(introApp(preferences));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(preferences.seen, isTrue);
    expect(tester.takeException(), isNull);
  });
  for (final scenario in [
    (const Size(320, 568), 2.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 2.0),
    (const Size(1280, 720), 1.0),
  ]) {
    testWidgets(
      'all introduction pages remain scrollable at ${scenario.$1} and text ${scenario.$2}',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var applied = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingPreferencesProvider.overrideWithValue(
                MemoryIntroPreferences(),
              ),
            ],
            child: MaterialApp(
              theme: buildRiderTheme(),
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scenario.$2),
                  disableAnimations: true,
                ),
                child: RiderOnboardingPage(onApply: () => applied = true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var page = 0; page < 3; page++) {
          expect(find.byKey(ValueKey('onboarding-art-$page')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('onboarding-cta')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
          await tester.pumpAndSettle();
        }
        expect(applied, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('a late preference read cannot undo a completed introduction', () async {
    final pending = Completer<bool>(),
        preferences = MemoryIntroPreferences(pending: Completer<bool>());
    preferences.pending = pending;
    final container = ProviderContainer(
      overrides: [onboardingPreferencesProvider.overrideWithValue(preferences)],
    );
    container.read(onboardingSeenProvider);
    await Future<void>.delayed(Duration.zero);
    await container.read(onboardingSeenProvider.notifier).markSeen();
    pending.complete(false);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(onboardingSeenProvider).seen, isTrue);
    container.dispose();
  });
  testWidgets(
    'an unresponsive preference store cannot hold the app on its opening screen',
    (tester) async {
      final preferences = MemoryIntroPreferences(pending: Completer<bool>());
      await tester.pumpWidget(introApp(preferences));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(RiderOnboardingPage), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding-sign-in')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding-sign-in')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('completion is stored separately from sign-in credentials', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalOnboardingPreferences().writeSeen(true);
    expect(await LocalOnboardingPreferences().readSeen(), isTrue);
  });
}
