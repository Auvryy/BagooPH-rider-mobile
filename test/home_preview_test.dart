import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/development/home_preview_page.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';

Future<TestAuthRepository> openApp(
  WidgetTester tester, {
  bool preview = true,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  final repository = TestAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: BagooRiderApp(enableHomePreview: preview),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
  });

  testWidgets('preview is opt-in and has no default navigation route', (
    tester,
  ) async {
    await openApp(tester, preview: false);
    expect(find.byKey(const ValueKey('demo-login')), findsNothing);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.routes!.containsKey('/home-preview'), isFalse);
  });

  testWidgets('demo entry, filters and exit never authenticate an account', (
    tester,
  ) async {
    final repository = await openApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'never-sent');
    await tap(tester, 'demo-login');
    expect(find.text('Demo mode · sample data'), findsOneWidget);
    expect(find.text('DEMO-P1001'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePreviewPage)),
    );
    expect(container.read(authControllerProvider).user, isNull);
    await tap(tester, 'preview-queue-pickups');
    expect(find.text('DEMO-P1003'), findsOneWidget);
    expect(find.text('DEMO-P1001'), findsNothing);
    await tap(tester, 'preview-queue-deliveries');
    expect(find.text('DEMO-D2001'), findsOneWidget);
    expect(find.text('DEMO-P1003'), findsNothing);
    await tap(tester, 'exit-home-preview');
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(repository.account, isNull);
    expect(repository.loginCalls, 0);
    expect(repository.logoutCalls, 0);
    expect(repository.registrationCalls, 0);
    final password = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(password.controller!.text, isEmpty);
    await tap(tester, 'demo-login');
    expect(find.text('DEMO-P1001'), findsOneWidget);
    expect(find.text('DEMO-D2001'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal sign-in still opens the actual account scaffold', (
    tester,
  ) async {
    final repository = await openApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'rider@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tap(tester, 'sign-in-button');
    expect(find.text('Welcome, Test Rider.'), findsOneWidget);
    expect(find.byType(HomePreviewPage), findsNothing);
    expect(repository.loginCalls, 1);
    await tap(tester, 'logout-button');
    expect(repository.logoutCalls, 1);
    expect(find.text('Welcome back.'), findsOneWidget);
  });

  for (final size in [(320.0, 2.0), (1440.0, 1.0)]) {
    testWidgets('demo controls fit ${size.$1} width at ${size.$2}x text', (
      tester,
    ) async {
      await openApp(tester, width: size.$1, scale: size.$2);
      await tap(tester, 'demo-login');
      await tap(tester, 'preview-queue-pickups');
      await tap(tester, 'preview-queue-deliveries');
      await tap(tester, 'exit-home-preview');
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
