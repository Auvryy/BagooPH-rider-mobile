import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/company/presentation/company_controller.dart';
import 'package:bagoo_rider_mobile/features/company/presentation/company_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/company_support.dart';
import 'support/test_auth_repository.dart';

const owner = RiderAccount(
  id: '7',
  name: 'Software Test Rider',
  email: 'rider@example.test',
  status: 'active',
  kycStatus: 'approved',
  approved: true,
  emailVerified: true,
  companyApiVersion: 1,
);

Future<ProviderContainer> mountCompany(
  WidgetTester tester,
  RiderCompanyController controller, {
  double scale = 1,
  String requestedAccountId = '7',
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = TestAuthRepository()..account = owner;
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      riderCompanyControllerProvider('7').overrideWith((ref) => controller),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildRiderTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(authControllerProvider);
            return Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        RiderCompanyPage(accountId: requestedAccountId),
                  ),
                ),
                child: const Text('Open companies'),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open companies'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapCompany(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
  });
  testWidgets(
    'a changed account cannot construct a protected company controller while a link opens',
    (tester) async {
      final s = companySetup();
      final c = RiderCompanyController(s.repository);
      await mountCompany(tester, c, requestedAccountId: '8');
      expect(find.text('Company requests'), findsNothing);
      expect(find.text('Open companies'), findsOneWidget);
      expect(s.api.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'company application requires explicit profile sharing at 320px/$scale text',
      (tester) async {
        final s = companySetup();
        final c = RiderCompanyController(s.repository);
        await mountCompany(tester, c, scale: scale);
        await tapCompany(tester, find.text('Request to join'));
        expect(find.text('Work email'), findsOneWidget);
        expect(find.text('contract-rider@bagoo.test'), findsOneWidget);
        final send = find.widgetWithText(FilledButton, 'Send request');
        expect(tester.widget<FilledButton>(send).onPressed, isNull);
        await tapCompany(tester, find.byType(CheckboxListTile));
        await tapCompany(tester, send);
        expect(s.api.writes, 1);
        expect(s.api.membership['on_duty'], isFalse);
        expect(
          find.textContaining('The company will review it.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'exact assignment review requires consent and never starts duty',
    (tester) async {
      final s = companySetup();
      s.api.requests = [s.api.detail];
      (s.api.membership['actions'] as Map<String, dynamic>)['apply'] = false;
      final c = RiderCompanyController(s.repository);
      await mountCompany(tester, c);
      await tapCompany(
        tester,
        find.widgetWithText(ListTile, 'Bagoo Company Network'),
      );
      await tapCompany(tester, find.text('Accept assignment'));
      final accept = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Accept assignment'),
      );
      expect(tester.widget<FilledButton>(accept).onPressed, isNull);
      expect(
        find.text(
          'Report to the recorded Bayan Hub and arrange your daily schedule.',
        ),
        findsNWidgets(2),
      );
      await tapCompany(tester, find.byType(CheckboxListTile));
      await tapCompany(tester, accept);
      expect(s.api.membership['on_duty'], isFalse);
      expect(find.textContaining('Go on duty from Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('logout removes the private company view and its history', (
    tester,
  ) async {
    final s = companySetup();
    final c = RiderCompanyController(s.repository);
    final container = await mountCompany(tester, c);
    expect(find.text('Company requests'), findsOneWidget);
    await container
        .read(authControllerProvider.notifier)
        .discardSession('Signed out.');
    await tester.pumpAndSettle();
    expect(find.text('Company requests'), findsNothing);
    expect(find.text('Open companies'), findsOneWidget);
    expect(find.text('Bagoo Company Network'), findsNothing);
  });
  testWidgets(
    'logout also clears an open profile-sharing review before its route closes',
    (tester) async {
      final s = companySetup();
      final c = RiderCompanyController(s.repository);
      final container = await mountCompany(tester, c);
      await tapCompany(tester, find.text('Request to join'));
      expect(find.text('contract-rider@bagoo.test'), findsOneWidget);
      await container
          .read(authControllerProvider.notifier)
          .discardSession('Signed out.');
      await tester.pump();
      expect(find.text('contract-rider@bagoo.test'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Company requests'), findsNothing);
      expect(s.api.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
