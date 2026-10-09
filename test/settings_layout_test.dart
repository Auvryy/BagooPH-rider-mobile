import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_models.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
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

void main() {
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets(
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

  testWidgets(
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

  testWidgets(
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
  testWidgets(
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

  testWidgets(
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
  testWidgets(
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
