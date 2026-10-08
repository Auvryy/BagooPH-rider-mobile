import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  await File('build/native-checks/workspace-$name.png')
      .writeAsBytes(bytes.buffer.asUint8List());
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
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      const ProviderScope(
        child: RepaintBoundary(
          key: ValueKey('workspace-capture'),
          child: app.BagooRiderApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'workspace-preview-entry');
    await capture(tester, 'tasks');
    await tap(tester, 'nav-trips');
    await capture(tester, 'trips');
    await tap(tester, 'nav-messages');
    await capture(tester, 'messages');
    await tap(tester, 'conversation-preview-pickup');
    await capture(tester, 'thread');
    await tap(tester, 'nav-profile');
    await tap(tester, 'open-settings');
    await capture(tester, 'settings');
    await tap(tester, 'logout-button');
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !enabled);
}
