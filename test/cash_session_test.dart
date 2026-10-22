import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/cash/presentation/cash_page.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cash_support.dart';
import 'support/test_auth_repository.dart';

RiderAccount rider({String id = '5', bool approved = true}) => RiderAccount(
  id: id,
  name: 'Software Test Rider',
  email: 'rider@example.test',
  status: approved ? 'active' : 'pending_approval',
  kycStatus: approved ? 'approved' : 'pending',
  approved: approved,
  emailVerified: true,
  operationsApiVersion: 1,
);
void main() {
  for (final change in ['logout', 'account', 'approval', 'api']) {
    testWidgets('cash route removes owned facts and draft on $change change', (
      tester,
    ) async {
      final h = CashHarness();
      final work = WorkspaceController(h.repository);
      addTearDown(work.dispose);
      final auth = TestAuthRepository()..account = rider();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          appConfigProvider.overrideWithValue(
            const AppConfig('https://example.test/api/v1'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () =>
                      openCash(context, work, accountId: h.account.id),
                  child: const Text('Open owned cash'),
                ),
              ),
            ),
          ),
        ),
      );
      // Initialize the same account provider watched by the actual route.
      container.read(authControllerProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open owned cash'));
      await tester.pumpAndSettle();
      expect(work.cash.detail, isNotNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('cash-offer-evidence')),
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('cash-offer-evidence')),
        'PRIVATE-SESSION-DRAFT',
      );
      await tester.pumpAndSettle();
      if (change == 'logout') {
        await container.read(authControllerProvider.notifier).logout();
      } else if (change == 'api') {
        container.updateOverrides([
          authRepositoryProvider.overrideWithValue(auth),
          appConfigProvider.overrideWithValue(
            const AppConfig('https://other.test/api/v1'),
          ),
        ]);
      } else {
        auth.account = rider(
          id: change == 'account' ? '6' : '5',
          approved: change != 'approval',
        );
        await container.read(authControllerProvider.notifier).refresh();
      }
      await tester.pumpAndSettle();
      expect(find.byType(CashPageView), findsNothing);
      expect(find.text('PRIVATE-SESSION-DRAFT'), findsNothing);
      expect(work.cash.page, isNull);
      expect(work.cash.detail, isNull);
      expect(work.cash.canOffer, false);
      expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
      work.setForeground(false);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
