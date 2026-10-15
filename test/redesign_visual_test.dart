// Explicit synthetic render review. Never loads a real account or provider key.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/development/workspace_preview_repository.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagoo_rider_mobile/features/auth/presentation/email_verification_dialog.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_controller.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_issues_page.dart';
import 'package:bagoo_rider_mobile/features/handover/presentation/handover_evidence_page.dart';

import 'support/handover_support.dart';

import 'support/test_auth_repository.dart';

const _captureKey = ValueKey('redesign-capture');
const _enabled = bool.fromEnvironment('RIDER_VISUAL_REVIEW');

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/branding/gooriders-icon.png'),
      tester.element(find.byType(MaterialApp).first),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: name);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final rendered = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/redesign-verification/screens');
    await folder.create(recursive: true);
    await File('${folder.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    rendered.dispose();
  });
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  testWidgets('render account entry and every registration stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(TestAuthRepository()),
          ],
          child: const BagooRiderApp(),
        ),
      ),
    );
    await capture(tester, 'login-390');
    final dialogContext = tester.element(find.byType(Scaffold).first);
    final verification = showDialog<void>(
      context: dialogContext,
      builder: (_) =>
          const EmailVerificationDialog(email: 'rider@example.test'),
    );
    await capture(tester, 'email-verification-390');
    Navigator.of(dialogContext).pop();
    await verification;
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('open-register')));
    await capture(tester, 'registration-details-390');
    await tap(tester, find.byKey(const ValueKey('registration-step-1')));
    await capture(tester, 'registration-vehicle-390');
    await tap(tester, find.byKey(const ValueKey('registration-step-2')));
    await capture(tester, 'registration-documents-390');
  }, skip: !_enabled);

  testWidgets('render account holding and workspace navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              TestAuthRepository()
                ..account = const RiderAccount(
                  id: 'test-pending',
                  name: 'Sample Rider',
                  email: 'rider@example.test',
                  status: 'pending_approval',
                  kycStatus: 'pending_approval',
                  approved: false,
                  emailVerified: true,
                ),
            ),
          ],
          child: const BagooRiderApp(),
        ),
      ),
    );
    await capture(tester, 'holding-390');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: ProviderScope(
          child: MaterialApp(
            theme: buildRiderTheme(),
            debugShowCheckedModeBanner: false,
            home: const WorkspacePreviewPage(),
          ),
        ),
      ),
    );
    await capture(tester, 'tasks-390');
    for (final name in ['trips', 'messages', 'profile']) {
      await tap(tester, find.byKey(ValueKey('nav-$name')));
      await capture(tester, '$name-390');
      if (name == 'trips') {
        await tap(tester, find.byKey(const ValueKey('trip-preview-trip-0')));
        await capture(tester, 'trip-detail-390');
        await tap(tester, find.text('Back to trips'));
      }
      if (name == 'messages') {
        await tap(
          tester,
          find.byKey(const ValueKey('conversation-preview-pickup')),
        );
        await capture(tester, 'conversation-390');
        await tap(tester, find.byKey(const ValueKey('conversation-back')));
        await tap(
          tester,
          find.byKey(const ValueKey('conversation-preview-ended')),
        );
        await capture(tester, 'conversation-restricted-390');
        await tap(tester, find.byKey(const ValueKey('conversation-back')));
      }
    }
    for (final section in ['account', 'assignment', 'vehicle']) {
      await tap(tester, find.byKey(ValueKey('open-$section')));
      await capture(tester, '$section-390');
      await tap(tester, find.byKey(const ValueKey('settings-back')));
    }
    await tap(tester, find.byKey(const ValueKey('open-settings')));
    await capture(tester, 'settings-390');
    for (final section in ['help', 'about']) {
      await tap(tester, find.byKey(ValueKey('open-$section')));
      await capture(tester, '$section-390');
      await tap(tester, find.byKey(const ValueKey('settings-back')));
    }
    for (final entry in [
      'settings-contact',
      'open-password',
      'settings-emails',
    ]) {
      await tap(tester, find.byKey(ValueKey(entry)));
      await capture(tester, '$entry-390');
      if (entry == 'settings-emails') {
        await tap(tester, find.byKey(const ValueKey('manage-email-1')));
        await capture(tester, 'manage-email-390');
        await tap(tester, find.byTooltip('Back'));
        await tap(tester, find.byKey(const ValueKey('add-email')));
        await capture(tester, 'add-email-390');
        await tap(tester, find.byTooltip('Back'));
      }
      await tap(tester, find.byTooltip('Back'));
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !_enabled);
  testWidgets('render handover list, report, recovery and evidence denial', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final repo = testHandoverRepository(api, journal);
    final controller = HandoverController(repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: MaterialApp(
          theme: buildRiderTheme(),
          debugShowCheckedModeBanner: false,
          home: HandoverIssuesView(controller: controller),
        ),
      ),
    );
    await capture(tester, 'handover-list-390');
    await tap(tester, find.byKey(const ValueKey('handover-new-report')));
    await capture(tester, 'handover-report-390');
    await tap(tester, find.byKey(const ValueKey('handover-submit-report')));
    await capture(tester, 'handover-report-evidence-390');
    await tap(tester, find.byKey(const ValueKey('handover-back')));
    await tap(tester, find.byKey(const ValueKey('handover-issue-1')));
    await capture(tester, 'handover-detail-390');
    final ack = find.byKey(const ValueKey('handover-acknowledge'));
    await tester.scrollUntilVisible(
      ack,
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('handover-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(ack);
    await capture(tester, 'handover-acknowledgement-390');
    api.downloadHandler = (_) async => throw const AccountFailure(
      'This evidence is no longer available to your account.',
      status: 403,
    );
    final detail = controller.selected!;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: MaterialApp(
          theme: buildRiderTheme(),
          debugShowCheckedModeBanner: false,
          home: HandoverEvidencePage(
            repository: repo,
            detail: detail,
            onFailure: (_) async {},
          ),
        ),
      ),
    );
    await capture(tester, 'private-evidence-denied-390');
    await tester.pumpWidget(const SizedBox());
  }, skip: !_enabled);
}
