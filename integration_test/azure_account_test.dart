import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/rider_website.dart';

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 75));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        'The native account check did not reach its expected screen.',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const enabled = bool.fromEnvironment('LIVE_AZURE_CHECK');
  testWidgets(
    'Azure native account login, secure restore and current-token logout',
    (tester) async {
      final config = AppConfig.environment();
      if (config.origin.scheme != 'https' ||
          config.origin.host != 'bagooph.shop') {
        throw StateError(
          'Use the reviewed Azure HTTPS configuration for this check.',
        );
      }
      final store = SecureTokenStore(apiOrigin: config.origin);
      // Keep this check from replacing a session the user has already established.
      if (await store.read() != null) {
        throw StateError(
          'An existing device session is present; sign out privately first.',
        );
      }
      final repo = ApiAuthRepository(config, store);
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(config),
              authRepositoryProvider.overrideWithValue(repo),
            ],
            child: const BagooRiderApp(enableHomePreview: false),
          ),
        );
        await waitFor(
          tester,
          () => find.byType(TextFormField).evaluate().length == 2,
        );
        // The existing buyer seed must not establish a Rider session.
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'buyer@bagoo.test',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Password1234',
        );
        final signIn = find.byKey(const ValueKey('sign-in-button'));
        await tester.ensureVisible(signIn);
        await tester.pumpAndSettle();
        await tester.tap(signIn);
        await waitFor(
          tester,
          () => find
              .text('This account cannot access the rider application.')
              .evaluate()
              .isNotEmpty,
        );
        expect(await store.read(), isNull);
        expect(find.byKey(const ValueKey('logout-button')), findsNothing);

        // Public, existing website seed credentials, never a private user's password.
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'rider@bagoo.test',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Password1234',
        );
        await tester.ensureVisible(signIn);
        await tester.pumpAndSettle();
        await tester.tap(signIn);
        await waitFor(
          tester,
          () =>
              find.byKey(const ValueKey('logout-button')).evaluate().isNotEmpty,
        );
        final current = await repo.refresh();
        expect(current.approved, isTrue);
        expect(find.text('Rider account approved'), findsOneWidget);
        expect(await store.read() != null, isTrue);
        final restoredRepo = ApiAuthRepository(
          config,
          SecureTokenStore(apiOrigin: config.origin),
        );
        final restored = await restoredRepo.restore();
        expect(restored?.id == current.id, isTrue);
        final otherEnvironment = SecureTokenStore(
          apiOrigin: Uri.parse('https://another.example.test/api/v1'),
        );
        expect(await otherEnvironment.read() == null, isTrue);

        final logout = find.byKey(const ValueKey('logout-button'));
        await tester.ensureVisible(logout);
        await tester.pumpAndSettle();
        await tester.tap(logout);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-logout')));
        await waitFor(
          tester,
          () => find.text('Welcome back.').evaluate().isNotEmpty,
        );
        expect(await store.read() == null, isTrue);
        var revoked = false;
        try {
          await restoredRepo.refresh();
        } on AccountFailure catch (error) {
          revoked = error.status == 401;
        }
        expect(revoked, isTrue);
        expect(await restoredRepo.restore() == null, isTrue);
        debugPrint(
          'AZURE_NATIVE_LOGIN_SECURE_RESTORE_WRONG_ROLE_AND_LOGOUT_PASSED',
        );
        expect(
          await confirmRiderWebsiteAccount(
            config.origin,
            current,
            'Password1234',
            report: debugPrint,
          ),
          isTrue,
          reason: 'The Rider website must match the native account and redirect over HTTPS.',
        );
      } finally {
        await repo.logout();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
    skip: !enabled,
  );
}
