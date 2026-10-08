import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/platform/rider_website.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/development/workspace_preview_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_shell.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/test_auth_repository.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty && key.startsWith('conversation-')) {
    final list = find.byKey(const PageStorageKey('conversation-list'));
    if (list.evaluate().isNotEmpty) {
      final scrollable = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final ancestor = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (ancestor.evaluate().isNotEmpty) {
    final visible = tester
        .getRect(target)
        .intersect(tester.getRect(ancestor.first));
    expect(visible.isEmpty, isFalse);
    await tester.tapAt(visible.center);
  } else {
    await tester.tap(target);
  }
  await tester.pumpAndSettle();
}

Future<void> tapFinder(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class RecordingLauncher implements WebsiteLauncher {
  final urls = <Uri>[];
  bool result = true;
  @override
  Future<bool> open(Uri uri) async {
    urls.add(uri);
    return result;
  }
}

class RecordingPreviewRepository extends PreviewWorkspaceRepository {
  final reads = <String>[];
  @override
  Future<void> acknowledge(
    String id,
    String phase,
    String latestMessageId,
  ) async {
    reads.add('$id:$phase:$latestMessageId');
  }
}

Future<TestAuthRepository> preview(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final auth = TestAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: BagooRiderApp(enableWorkspacePreview: enabled),
    ),
  );
  await tester.pumpAndSettle();
  if (enabled) await tap(tester, 'workspace-preview-entry');
  return auth;
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'BagooPH Rider',
      packageName: 'example.test.rider',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: 'test',
    ),
  );
  testWidgets(
    'workspace examples require opt-in and never authenticate a user',
    (tester) async {
      await preview(tester, enabled: false);
      expect(
        find.byKey(const ValueKey('workspace-preview-entry')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final auth = await preview(tester);
      expect(find.text('Demo · sample data'), findsOneWidget);
      for (final tab in ['trips', 'messages', 'profile', 'tasks']) {
        await tap(tester, 'nav-$tab');
      }
      await tap(tester, 'logout-button');
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(auth.account, isNull);
      expect(auth.loginCalls, 0);
      expect(auth.logoutCalls, 0);
      expect(auth.registrationCalls, 0);
    },
  );
  testWidgets(
    'authenticated pages show unavailable services instead of sample or empty live queues',
    (tester) async {
      final auth = TestAuthRepository()..account = TestAuthRepository.approved;
      final launcher = RecordingLauncher();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            appConfigProvider.overrideWithValue(
              const AppConfig(
                'https://bagoo.example.test/api/v1',
                riderWebsite: 'https://courier.bagoo.example.test',
              ),
            ),
            websiteLauncherProvider.overrideWithValue(launcher),
          ],
          child: const BagooRiderApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tasks are not connected yet'), findsOneWidget);
      expect(find.text('DEMO-P1001'), findsNothing);
      await tapFinder(
        tester,
        find.widgetWithText(OutlinedButton, 'Open Rider website'),
      );
      await tester.pumpAndSettle();
      expect(
        launcher.urls.single.toString(),
        'https://courier.bagoo.example.test/deliveries',
      );
      await tap(tester, 'nav-trips');
      expect(find.text('Trips are not connected yet'), findsOneWidget);
      await tap(tester, 'nav-messages');
      expect(find.text('Messages are not connected yet'), findsOneWidget);
      await tap(tester, 'nav-profile');
      expect(find.text('rider@example.com'), findsOneWidget);
      await tap(tester, 'open-settings');
      await tap(tester, 'open-security');
      await tapFinder(
        tester,
        find.widgetWithText(OutlinedButton, 'Manage account on the website'),
      );
      await tester.pumpAndSettle();
      expect(launcher.urls.last.path, '/profile');
      expect(
        launcher.urls.every((uri) => uri.query.isEmpty && uri.userInfo.isEmpty),
        isTrue,
      );
      launcher.result = false;
      await tapFinder(
        tester,
        find.widgetWithText(OutlinedButton, 'Forgot password'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Could not open the Rider website. Try again.'),
        findsOneWidget,
      );
      await tap(tester, 'settings-back');
      await tap(tester, 'settings-logout');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.logoutCalls, 0);
      await tap(tester, 'settings-logout');
      await tap(tester, 'confirm-logout');
      expect(auth.logoutCalls, 1);
      expect(find.text('Welcome back.'), findsOneWidget);
    },
  );
  testWidgets(
    'trip search, payment filters, pagination and recorded detail work in the explicit preview',
    (tester) async {
      await preview(tester);
      await tap(tester, 'nav-trips');
      expect(find.text('Showing 1–10 of 14 matching records'), findsOneWidget);
      await tap(tester, 'trips-next');
      expect(find.text('Showing 11–14 of 14 matching records'), findsOneWidget);
      await tap(tester, 'trip-payment-cod');
      expect(find.text('Showing 1–7 of 7 matching records'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('trip-search')),
        'DEMO-T3001',
      );
      await tester.pumpAndSettle();
      expect(find.text('Showing 1–1 of 1 matching records'), findsOneWidget);
      await tap(tester, 'trip-preview-trip-0');
      expect(find.text('Recorded journey'), findsOneWidget);
      expect(find.text('Assigned by destination hub'), findsOneWidget);
      expect(
        find.text(
          'Sample history only. No proof, buyer receipt, remittance or payout is confirmed by this preview.',
        ),
        findsOneWidget,
      );
      await tapFinder(tester, find.text('Back to trips'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'messages preserve per-thread drafts, preview send and read-only assignments',
    (tester) async {
      final auth = await preview(tester);
      await tap(tester, 'nav-messages');
      await tap(tester, 'conversation-preview-pickup');
      await tester.enterText(
        find.byKey(const ValueKey('message-draft')),
        'Pickup draft',
      );
      await tester.pumpAndSettle();
      await tap(tester, 'conversation-back');
      await tap(tester, 'conversation-preview-delivery');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('message-draft')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('message-draft')),
        'Delivery draft',
      );
      await tap(tester, 'conversation-back');
      await tap(tester, 'conversation-preview-pickup');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('message-draft')))
            .controller!
            .text,
        'Pickup draft',
      );
      await tap(tester, 'send-message');
      expect(find.text('Preview · not sent'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('message-draft')))
            .controller!
            .text,
        isEmpty,
      );
      await tap(tester, 'conversation-back');
      await tap(tester, 'conversation-preview-ended');
      expect(find.byKey(const ValueKey('message-draft')), findsNothing);
      expect(
        find.text(
          'This assignment is read only. New messages are unavailable.',
        ),
        findsOneWidget,
      );
      expect(auth.loginCalls, 0);
      expect(auth.logoutCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'offstage and background conversations never acknowledge messages',
    (tester) async {
      final repo = RecordingPreviewRepository();
      final auth = TestAuthRepository();
      const account = RiderAccount(
        id: 'test-preview',
        name: 'Sample Rider',
        email: 'rider@example.test',
        status: 'active',
        kycStatus: 'approved',
        approved: true,
        emailVerified: true,
      );
      final container = ProviderContainer(
        overrides: [
          workspaceRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: const RiderWorkspaceShell(account: account, preview: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = container.read(
        workspaceControllerProvider(
          const WorkspaceIdentity('test-preview', preview: true),
        ),
      );
      controller.selectConversation('preview-pickup');
      await tester.pumpAndSettle();
      expect(repo.reads, isEmpty);
      await tap(tester, 'nav-messages');
      expect(repo.reads, ['preview-pickup:pickup:preview-m2']);
      await tap(tester, 'nav-trips');
      controller.selectConversation('preview-delivery');
      await tester.pumpAndSettle();
      expect(repo.reads.length, 1);
    },
  );
  testWidgets(
    'loss of approval closes a private parcel sheet and returns to holding',
    (tester) async {
      final auth = TestAuthRepository()..account = TestAuthRepository.approved;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            workspaceRepositoryProvider.overrideWithValue(
              PreviewWorkspaceRepository(),
            ),
          ],
          child: const BagooRiderApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tapFinder(
        tester,
        find.widgetWithText(OutlinedButton, 'View parcel').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Parcel details'), findsOneWidget);
      auth.account = const RiderAccount(
        id: '7',
        name: 'Test Rider',
        email: 'rider@example.test',
        status: 'pending_approval',
        kycStatus: 'rejected',
        approved: false,
        emailVerified: true,
        feedback: 'Replace the test document.',
      );
      final element = tester.element(find.byType(BagooRiderApp));
      await ProviderScope.containerOf(element)
          .read(authControllerProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();
      expect(find.text('Application needs correction'), findsOneWidget);
      expect(find.text('Parcel details'), findsNothing);
      expect(find.byKey(const ValueKey('rider-workspace')), findsNothing);
    },
  );
  for (final setting in [
    (320.0, 1.0),
    (320.0, 2.0),
    (430.0, 2.0),
    (960.0, 1.0),
    (1440.0, 1.0),
  ]) {
    testWidgets(
      'all workspace destinations fit ${setting.$1} pixels at ${setting.$2}x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(setting.$1, 800);
        tester.platformDispatcher.textScaleFactorTestValue = setting.$2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await preview(tester);
        for (final tab in ['tasks', 'trips', 'messages', 'profile']) {
          await tap(tester, 'nav-$tab');
          expect(tester.takeException(), isNull);
        }
        await tap(tester, 'open-settings');
        await tap(tester, 'open-about');
        expect(find.text('Version 0.1.0 · Build 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'compact message composer stays reachable above a keyboard at large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await preview(tester);
      await tap(tester, 'nav-messages');
      await tap(tester, 'conversation-preview-pickup');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(
        find.byKey(const ValueKey('message-draft')),
        'Keyboard draft',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('send-message')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-trips')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
