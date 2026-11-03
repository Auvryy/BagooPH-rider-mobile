import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/main.dart' as app;
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/development/workspace_preview_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/test_auth_repository.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty && key.startsWith('conversation-')) {
    final list = find.byKey(const PageStorageKey('conversation-list'));
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('workspace-capture')),
  );
  final rendered = await boundary.toImage(pixelRatio: 1);
  final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('The rendered page could not be captured.');
  }
  final file = File('build/native-checks/workspace-$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
  rendered.dispose();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('WORKSPACE_RENDER_CHECK');
  testWidgets('native Linux preview navigation and rendered page review', (
    tester,
  ) async {
    await binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        // Exiting the synthetic workspace must not restore a live session.
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        ],
        child: RepaintBoundary(
          key: const ValueKey('workspace-capture'),
          child: MaterialApp(
            theme: buildRiderTheme(),
            // IntegrationTest's native view retains the X11 window metrics
            // when setSurfaceSize changes only the render surface.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(size: const Size(430, 900), devicePixelRatio: 1),
              child: child!,
            ),
            initialRoute: '/test-workspace',
            routes: {
              '/': (_) => const app.AccountGate(),
              '/test-workspace': (_) => const WorkspacePreviewPage(),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.sizeOf(tester.element(find.byType(WorkspacePreviewPage))),
      const Size(430, 900),
    );
    await capture(tester, 'tasks');
    await tap(tester, 'nav-trips');
    await capture(tester, 'trips');
    await tap(tester, 'nav-messages');
    await capture(tester, 'messages');
    await tap(tester, 'conversation-pickup-1-101-3');
    await capture(tester, 'thread');
    await tap(tester, 'nav-profile');
    await tap(tester, 'open-settings');
    await capture(tester, 'settings');
    await tap(tester, 'settings-contact');
    await capture(tester, 'contact-settings');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'settings-emails');
    await capture(tester, 'email-settings');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'open-password');
    await capture(tester, 'password-settings');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'settings-logout');
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !enabled);
}
