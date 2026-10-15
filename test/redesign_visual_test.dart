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
    }
  }, skip: !_enabled);
}
