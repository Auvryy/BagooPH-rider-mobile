import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/platform/rider_website.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/login_page.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_auth_repository.dart';
import 'support/test_settings_repository.dart';

class _Launcher implements WebsiteLauncher {
  final opened = <Uri>[];
  bool succeeds = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}

Future<void> _show(WidgetTester tester, _Launcher launcher, Widget home) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            'https://bagoo.example.test/api/v1',
            riderWebsite: 'https://courier.bagoo.example.test',
          ),
        ),
        authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        settingsRepositoryProvider.overrideWith(
          (ref, id) => TestSettingsRepository(),
        ),
        websiteLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        theme: buildRiderTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Widget _settings(ProfileSection section) => ProfileSettingsPage(
  account: TestAuthRepository.approved,
  section: section,
  onSection: (_) {},
  onLogout: () {},
  onRefresh: () {},
  preview: false,
);

void main() {
  testWidgets(
    'signed-out password and custody recovery open fixed first-party pages',
    (tester) async {
      final launcher = _Launcher();
      await _show(tester, launcher, const LoginPage());
      await _tap(tester, 'login-password-recovery');
      await _tap(tester, 'login-custody-recovery');
      expect(launcher.opened.map((u) => u.path), [
        '/forgot-password',
        '/custody-recovery',
      ]);
      for (final uri in launcher.opened) {
        expect(uri.origin, 'https://courier.bagoo.example.test');
        expect(uri.userInfo, isEmpty);
        expect(uri.hasQuery, isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native Settings opens session controls and Help opens restricted recovery',
    (tester) async {
      final launcher = _Launcher();
      await _show(tester, launcher, _settings(ProfileSection.settings));
      await _tap(tester, 'settings-security-website');
      expect(launcher.opened.single.path, '/account/security');
      await _show(tester, launcher, _settings(ProfileSection.help));
      await _tap(tester, 'help-custody-recovery');
      expect(launcher.opened.last.path, '/custody-recovery');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed recovery launch keeps the native page and gives retry feedback',
    (tester) async {
      final launcher = _Launcher()..succeeds = false;
      await _show(tester, launcher, const LoginPage());
      await _tap(tester, 'login-password-recovery');
      expect(
        find.text('Could not open the Rider website. Try again.'),
        findsOneWidget,
      );
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
