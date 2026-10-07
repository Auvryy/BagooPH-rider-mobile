import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_auth_repository.dart';

void resumeApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  testWidgets(
    'resume refreshes holding feedback and removes a restricted session',
    (tester) async {
      final repository = TestAuthRepository()
        ..account = TestAuthRepository.approved;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
          child: const BagooRiderApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rider account approved'), findsOneWidget);
      repository.account = const RiderAccount(
        id: '7',
        name: 'Test Rider',
        email: 'rider@example.test',
        status: 'pending_approval',
        kycStatus: 'rejected',
        approved: false,
        emailVerified: true,
        feedback: 'Replace the test document.',
      );
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(repository.refreshCalls, 1);
      expect(find.text('Application needs correction'), findsOneWidget);
      expect(find.text('Replace the test document.'), findsOneWidget);
      repository.refreshFailure = const AccountFailure(
        'Account restricted.',
        status: 403,
      );
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(repository.refreshCalls, 2);
      expect(repository.logoutCalls, 1);
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Application needs correction'), findsNothing);
      expect(tester.takeException(), isNull);
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(repository.refreshCalls, 2);
    },
  );
}
