import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/settings/presentation/settings_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';
import 'support/test_settings_repository.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.descendant(
  of: find.byKey(ValueKey('settings-$label')),
  matching: find.byType(TextFormField),
);
Future<void> nativeSettings(
  WidgetTester tester,
  TestSettingsRepository repo,
) async {
  final auth = TestAuthRepository()..account = TestAuthRepository.approved;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWith((ref, id) => repo),
      ],
      child: const BagooRiderApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tap(tester, 'nav-profile');
  await tap(tester, 'open-settings');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'contact rejects preserve typed input and confirmed save shows actual value',
    (tester) async {
      final repo = TestSettingsRepository();
      await nativeSettings(tester, repo);
      await tap(tester, 'settings-contact');
      await tester.enterText(field('Mobile number'), 'letters');
      repo.mutationFailure = const AccountFailure(
        'Check phone',
        status: 422,
        fields: {'phone': 'Invalid number'},
      );
      await tap(tester, 'save-contact');
      expect(find.text('Invalid number'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('Mobile number')).controller!.text,
        'letters',
      );
      expect(find.text('Contact details saved.'), findsNothing);
      repo.mutationFailure = null;
      await tester.enterText(field('Mobile number'), '09171234567');
      await tap(tester, 'save-contact');
      expect(find.text('Contact details saved.'), findsOneWidget);
    },
  );
  testWidgets(
    'confirmed password update closes private forms and returns a clean login',
    (tester) async {
      final repo = TestSettingsRepository();
      await nativeSettings(tester, repo);
      await tap(tester, 'open-security');
      await tap(tester, 'open-password');
      for (final label in [
        'Current password',
        'New password',
        'Confirm new password',
      ]) {
        expect(
          tester
              .widget<EditableText>(
                find.descendant(
                  of: field(label),
                  matching: find.byType(EditableText),
                ),
              )
              .obscureText,
          isTrue,
        );
      }
      await tester.enterText(field('Current password'), 'current-secret');
      await tester.enterText(field('New password'), 'new-secret-1234');
      await tester.enterText(field('Confirm new password'), 'mismatch');
      await tap(tester, 'save-password');
      expect(repo.passwordCalls, 0);
      await tester.enterText(field('Confirm new password'), 'new-secret-1234');
      await tap(tester, 'save-password');
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(
        find.text('Password updated. Sign in with your new password.'),
        findsOneWidget,
      );
      expect(find.text('new-secret-1234'), findsNothing);
    },
  );
  testWidgets(
    'paused password form clears secrets and user can discard draft',
    (tester) async {
      await nativeSettings(tester, TestSettingsRepository());
      await tap(tester, 'open-security');
      await tap(tester, 'open-password');
      await tester.enterText(field('Current password'), 'current-secret');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(field('Current password'))
            .controller!
            .text,
        isEmpty,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.enterText(field('New password'), 'draft-secret-1234');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy and security'), findsWidgets);
    },
  );
  testWidgets(
    'preview settings email actions never authenticate a real account',
    (tester) async {
      final auth = TestAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: const BagooRiderApp(enableWorkspacePreview: true),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
      await tap(tester, 'workspace-preview-entry');
      await tap(tester, 'nav-profile');
      await tap(tester, 'open-settings');
      await tap(tester, 'settings-emails');
      await tester.enterText(field('Current password'), 'sample-secret');
      await tester.enterText(field('Additional email'), 'contact@example.test');
      await tap(tester, 'email-submit');
      expect(field('Verification code'), findsOneWidget);
      await tester.enterText(field('Verification code'), '123456');
      await tap(tester, 'email-submit');
      expect(find.text('contact@example.test'), findsOneWidget);
      expect(auth.loginCalls, 0);
      expect(auth.registrationCalls, 0);
      expect(auth.logoutCalls, 0);
    },
  );
  for (final size in [const Size(320, 720), const Size(1440, 900)]) {
    testWidgets(
      'settings forms fit ${size.width} at large text and keyboard inset',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await nativeSettings(tester, TestSettingsRepository());
        await tap(tester, 'open-security');
        await tap(tester, 'open-password');
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('save-password')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
