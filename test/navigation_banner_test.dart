import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controls.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navigation_test.dart' as support;

void main() {
  testWidgets(
    'paused reason and explicit task revalidation remain available outside Home at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final routes = support.Routes(), location = support.Location();
      var reviewed = false;
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async => support.task(),
        vehicleType: () async => 'motorcycle',
        location: location,
      );
      addTearDown(() async {
        nav.dispose();
        routes.dispose();
        await location.stream.close();
      });
      nav.paused = true;
      nav.pausedTaskId = support.task().id;
      nav.message = 'Task authorization could not refresh. Revalidate this task to resume.';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [navigationProvider.overrideWithValue(nav)],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 480),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: Column(
                  children: [
                    NavigationBanner(onRevalidated: (_) => reviewed = true),
                    const Expanded(child: Text('Profile')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Navigation paused'), findsOneWidget);
      expect(
        find.textContaining('Task authorization could not refresh'),
        findsOneWidget,
      );
      final action = find.byKey(const ValueKey('navigation-revalidate'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(reviewed, isTrue);
      expect(nav.active, isFalse);
      expect(location.prepared, 0);
      expect(location.listened, 0);
      expect(find.textContaining('press Navigate to resume'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
