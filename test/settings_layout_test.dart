import 'support/onboarding_support.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_models.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/test_auth_repository.dart';
import 'support/test_settings_repository.dart';

class LayoutSettingsRepository extends TestSettingsRepository {
  @override
  Future<SettingsSnapshot> read() async {
    final wire = settingsWire(phone: '+639171234567');
    (wire['data'] as Map)['managed_details'] = {
      'available': true,
      'company': 'Example logistics',
      'hub': 'Example Bayan Hub',
      'hub_code': 'HUB_CODE_01',
      'barangay': 'Example district',
      'vehicle_type': 'motorcycle',
      'vehicle_model': 'Example model',
      'plate_number': 'PLATE_01',
      'fleet_status': 'active',
      'license_number': 'LICENSE_01',
      'registration_status': 'verified',
    };
    return decodeSettings(wire);
  }
}

class FullEmailsRepository extends TestSettingsRepository {
  @override
  Future<SettingsSnapshot> read() async {
    final wire = settingsWire();
    final emails = (wire['data'] as Map)['emails'] as List;
    for (var i = 2; i <= 6; i++) {
      emails.add({
        'id': '$i',
        'email': 'contact$i@example.test',
        'is_original': false,
        'verified': true,
        'preferred': false,
      });
    }
    return decodeSettings(wire);
  }
}

Future<void> openApp(
  WidgetTester tester, {
  TestSettingsRepository? repository,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
  addTearDown(tester.view.reset);
  PackageInfo.setMockInitialValues(
    appName: 'BagooPH Rider',
    packageName: 'example.test',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: 'test',
  );
  final auth = TestAuthRepository()..account = TestAuthRepository.approved;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWith(
          (ref, id) => repository ?? LayoutSettingsRepository(),
        ),
      ],
      child: const RepaintBoundary(
        key: ValueKey('settings-capture'),
        child: BagooRiderApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (find.byKey(const ValueKey('onboarding-sign-in')).evaluate().isNotEmpty) {
    await tap(tester, 'onboarding-sign-in');
  }
  await tap(tester, 'nav-profile');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void visibleControl(WidgetTester tester, String key, Rect viewport) {
  final rect = tester.getRect(find.byKey(ValueKey(key)));
  expect(rect.height, greaterThanOrEqualTo(48), reason: '$key touch height');
  expect(
    viewport.contains(rect.topLeft + const Offset(1, 1)),
    isTrue,
    reason: '$key top visible',
  );
  expect(
    viewport.contains(rect.bottomRight - const Offset(1, 1)),
    isTrue,
    reason: '$key bottom visible',
  );
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('settings-capture')),
    );
    final img = await boundary.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/settings-ui')..createSync(recursive: true);
    await File('${dir.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    img.dispose();
  });
}

void layoutTest(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    final previous = debugDefaultTargetPlatformOverride;
    final shadows = debugDisableShadows;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = previous;
      debugDisableShadows = shadows;
    }
  });
}

void main() {
  setUp(completedIntroductionFixture);
  setUp(() {
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
    if (Platform.isLinux) {
      try {
        final match = await Process.run('fc-match', [
          '-f',
          '%{file}',
          'sans-serif',
        ]);
        final file = File((match.stdout as String).trim());
        if (match.exitCode == 0 && file.existsSync()) {
          final native = FontLoader('sans-serif')
            ..addFont(
              Future.value(ByteData.sublistView(await file.readAsBytes())),
            );
          await native.load();
        }
      } on ProcessException {
        // Headless hosts keep the bundled fallback loaded above.
      }
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  layoutTest(
    'short Settings stays still during a drag while the pointer is down',
    (tester) async {
      await openApp(tester);
      await tap(tester, 'open-settings');
      final page = find.byKey(const PageStorageKey('profile-settings'));
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: page, matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, 0);
      final title = find.descendant(of: page, matching: find.text('Account'));
      final before = tester.getRect(title);
      final gesture = await tester.startGesture(before.center);
      await gesture.moveBy(const Offset(0, -70));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.position.pixels, 0);
      expect(tester.getRect(title), before);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  layoutTest(
    'read-only Settings values do not scroll internally and remain selectable',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await openApp(tester);
      await tap(tester, 'open-assignment');
      final value = find.text('Example logistics');
      final before = tester.getRect(value);
      final gesture = await tester.startGesture(before.center);
      await gesture.moveBy(const Offset(-65, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(value), before);
      final inner = tester.state<ScrollableState>(
        find.descendant(of: value, matching: find.byType(Scrollable)),
      );
      expect(inner.position.pixels, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.longPressAt(before.topLeft + const Offset(12, 12));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  layoutTest('overflowing Settings remains scrollable with enlarged text', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, 'open-settings');
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final page = find.byKey(const PageStorageKey('profile-settings'));
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: page, matching: find.byType(Scrollable)),
    );
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(page, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    await tester.ensureVisible(find.byKey(const ValueKey('settings-logout')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-logout')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    for (final label in ['Tasks', 'Trips', 'Messages', 'Profile']) {
      final button = find.byKey(ValueKey('nav-${label.toLowerCase()}'));
      final caption = find.descendant(of: button, matching: find.text(label));
      expect(caption, findsNothing);
      expect(find.byTooltip(label), findsOneWidget);
      expect(tester.getRect(button).height, greaterThanOrEqualTo(48));
      expect(button.hitTestable(), findsOneWidget);
    }
    final caption = find.byKey(const ValueKey('navigation-selected-label'));
    expect(tester.widget<Text>(caption).data, 'Profile');
    expect(
      tester
          .renderObject<RenderParagraph>(caption)
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 7),
          ),
      hasLength(1),
    );
    await capture(tester, 'settings-large-text');
  });
  layoutTest(
    'Profile and Settings primary controls fit the first phone viewport',
    (tester) async {
      await openApp(tester);
      final profileViewport = tester.getRect(
        find.byKey(const PageStorageKey('profile-profile')),
      );
      for (final key in [
        'open-account',
        'open-settings',
        'open-assignment',
        'open-vehicle',
      ]) {
        visibleControl(tester, key, profileViewport);
      }
      expect(find.text('Account reference'), findsNothing);
      expect(find.text('LICENSE_01'), findsNothing);
      expect(find.byKey(const ValueKey('logout-button')), findsNothing);
      await capture(tester, 'profile');
      await tap(tester, 'open-settings');
      final viewport = tester.getRect(
        find.byKey(const PageStorageKey('profile-settings')),
      );
      for (final key in [
        'settings-contact',
        'settings-emails',
        'open-password',
        'open-help',
        'open-about',
        'settings-logout',
      ]) {
        visibleControl(tester, key, viewport);
      }
      await capture(tester, 'settings');
      await tap(tester, 'settings-contact');
      final saveRect = tester.getRect(
        find.byKey(const ValueKey('save-contact')),
      );
      expect(saveRect.bottom, lessThan(810));
      expect(find.text('Reviewed name'), findsNothing);
      expect(find.text('Saved mobile number'), findsNothing);
      expect(
        find.text('Request identity correction on the website'),
        findsNothing,
      );
      await capture(tester, 'contact');
      await tap(tester, 'identity-correction-info');
      expect(
        find.text('Request identity correction on the website'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  layoutTest(
    'the navigation rail keeps full labels reachable in a short large-text window',
    (tester) async {
      await openApp(tester);
      tester.view.physicalSize = const Size(840, 480);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      for (final label in ['Tasks', 'Trips', 'Messages', 'Profile']) {
        final button = find.byKey(ValueKey('nav-${label.toLowerCase()}'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final caption = find.descendant(of: button, matching: find.text(label));
        expect(
          tester
              .renderObject<RenderParagraph>(caption)
              .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: label.length),
              ),
          hasLength(1),
        );
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.getRect(button).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }
      await capture(tester, 'settings-rail-large-text');
    },
  );

  layoutTest(
    'details preserve server values and system Back follows the hierarchy',
    (tester) async {
      await openApp(tester);
      await tap(tester, 'open-assignment');
      expect(find.text('HUB_CODE_01'), findsOneWidget);
      expect(find.text('Example logistics'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-settings')), findsOneWidget);
      await tap(tester, 'open-vehicle');
      expect(find.text('PLATE_01'), findsOneWidget);
      expect(find.text('LICENSE_01'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'open-account');
      expect(find.text('Account reference'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'open-settings');
      await tap(tester, 'open-help');
      expect(find.textContaining('Claim an eligible pickup'), findsNothing);
      await tester.tap(find.text('Seller pickup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Claim an eligible pickup'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-password')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  layoutTest(
    'email overview reveals credentials only when choosing an operation',
    (tester) async {
      await openApp(tester);
      await tap(tester, 'open-settings');
      await tap(tester, 'settings-emails');
      expect(
        find.byKey(const ValueKey('settings-Current password')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings-Additional email')),
        findsNothing,
      );
      await capture(tester, 'emails');
      await tap(tester, 'manage-email-1');
      expect(
        find.text('Your sign-in email cannot be removed.'),
        findsOneWidget,
      );
      expect(find.text('Remove email'), findsNothing);
      expect(
        find.byKey(const ValueKey('settings-Current password')),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tap(tester, 'add-email');
      expect(
        find.byKey(const ValueKey('settings-Current password')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-Additional email')),
        findsOneWidget,
      );
      await capture(tester, 'add-email');
      expect(tester.takeException(), isNull);
    },
  );
  layoutTest(
    'six saved emails remain readable and management actions stay separate',
    (tester) async {
      await openApp(tester, repository: FullEmailsRepository());
      await tap(tester, 'open-settings');
      await tap(tester, 'settings-emails');
      expect(find.byKey(const ValueKey('add-email')), findsNothing);
      expect(
        find.byKey(const ValueKey('settings-Current password')),
        findsNothing,
      );
      await tap(tester, 'manage-email-6');
      expect(
        find.byKey(const ValueKey('settings-Current password')),
        findsOneWidget,
      );
      expect(find.text('Use for contact'), findsOneWidget);
      expect(find.text('Remove email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  layoutTest(
    'settings details and add-email forms support 320 width and 200 percent text',
    (tester) async {
      await openApp(tester);
      tester.view.physicalSize = const Size(320, 720);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      for (final key in ['open-account', 'open-assignment', 'open-vehicle']) {
        await tap(tester, key);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      await tap(tester, 'open-settings');
      await tap(tester, 'settings-emails');
      await tap(tester, 'add-email');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('email-submit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  layoutTest(
    'modern shared styling renders existing workspace and entry screens',
    (tester) async {
      await openApp(tester);
      for (final tab in ['tasks', 'trips', 'messages']) {
        await tap(tester, 'nav-$tab');
        await capture(tester, 'modern-$tab');
        expect(tester.takeException(), isNull);
      }
      await tap(tester, 'logout-button');
      await tap(tester, 'confirm-logout');
      await capture(tester, 'modern-login');
      await tap(tester, 'open-register');
      await capture(tester, 'modern-register');
      expect(tester.takeException(), isNull);
    },
  );
}
