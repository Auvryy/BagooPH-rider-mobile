import 'dart:async';

import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_preview_test.dart' as support;
import 'support/onboarding_support.dart';
import 'support/test_auth_repository.dart';

class _PendingLogin extends TestAuthRepository {
  final response = Completer<RiderAccount>();

  @override
  Future<RiderAccount> login(String email, String password) {
    loginCalls++;
    return response.future;
  }
}

void main() {
  setUp(completedIntroductionFixture);

  testWidgets(
    'login exposes server field feedback and clears corrected errors',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final repository = TestAuthRepository()
          ..loginFailure = const AccountFailure(
            'Check your sign-in details and try again.',
            status: 422,
            fields: {
              'email': 'Use the email address linked to your rider account.',
              'password': 'Check the password for this rider account.',
            },
          );
        await support.openApp(tester, repository: repository);
        await tester.enterText(
          support.field('Email address'),
          'rider@example.test',
        );
        await tester.enterText(support.field('Password'), 'Example123!');
        await support.tapVisible(
          tester,
          find.byKey(const ValueKey('sign-in-button')),
        );
        expect(
          find.text('Use the email address linked to your rider account.'),
          findsOneWidget,
        );
        expect(
          find.text('Check the password for this rider account.'),
          findsOneWidget,
        );
        expect(
          tester
              .getSemantics(
                find.text('Check your sign-in details and try again.'),
              )
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.enterText(
          support.field('Email address'),
          'correct@example.test',
        );
        await tester.pump();
        expect(
          find.text('Check your sign-in details and try again.'),
          findsNothing,
        );
        expect(
          find.text('Use the email address linked to your rider account.'),
          findsNothing,
        );
        expect(
          tester
              .widget<TextFormField>(support.field('Password'))
              .controller!
              .text,
          'Example123!',
        );
        expect(repository.loginCalls, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'pending login disables submissions and announces retry failure',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final repository = _PendingLogin();
        await support.openApp(tester, repository: repository);
        await tester.enterText(
          support.field('Email address'),
          'rider@example.test',
        );
        await tester.enterText(support.field('Password'), 'Example123!');
        await tester.ensureVisible(
          find.byKey(const ValueKey('sign-in-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('sign-in-button')));
        await tester.pump();
        expect(find.text('Signing in…'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('sign-in-button')),
              )
              .onPressed,
          isNull,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(repository.loginCalls, 1);
        repository.response.completeError(
          const AccountFailure(
            'No connection. Check your network and try again.',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sign in'), findsOneWidget);
        expect(
          tester
              .getSemantics(
                find.text('No connection. Check your network and try again.'),
              )
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        expect(repository.loginCalls, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('registration announces the missing-details recovery step', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final repository = TestAuthRepository();
      await support.openApp(tester, route: '/register', repository: repository);
      await support.tapVisible(
        tester,
        find.byKey(const ValueKey('registration-step-2')),
      );
      await tester.enterText(support.field('Create password'), 'Example123!');
      await tester.enterText(support.field('Confirm password'), 'Example123!');
      await support.tapVisible(
        tester,
        find.byKey(const ValueKey('registration-next')),
      );
      final recovery = find.text(
        'Complete your rider and contact details before applying.',
      );
      expect(recovery, findsOneWidget);
      await tester.ensureVisible(recovery);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(recovery)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(repository.registrationCalls, 0);
      expect(find.text('Let’s get to know you.'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
