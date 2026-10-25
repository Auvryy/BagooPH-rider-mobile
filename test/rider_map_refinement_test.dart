import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/home_location_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_dashboard_test.dart' as dashboard;
import 'support/map_location.dart';
import 'support/delivery_map.dart';

void main() {
  for (final (size, scale) in [
    (const Size(320, 640), 2.0),
    (const Size(375, 812), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(1200, 500), 1.0),
    (const Size(1200, 850), 1.0),
  ]) {
    dashboard.managedDashboardTest(
      'light Leaflet sample remains usable at $size and ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final h = await dashboard.openDashboard(tester, textScale: scale);
        expect(find.byType(LeafletDeliveryMap), findsOneWidget);
        expect(
          find.text('Sample rider → Sample delivery point'),
          findsOneWidget,
        );
        expect(find.textContaining('Illustration only'), findsOneWidget);
        expect(find.text('Powered by Geoapify'), findsNothing);
        expect(find.byTooltip('Use dark map'), findsNothing);
        await dashboard.revealHome(
          tester,
          find.byKey(const ValueKey('task-queue-delivery')),
        );
        expect(tester.takeException(), isNull);
        expect(h.navigation.active, isFalse);
      },
    );
  }
  dashboard.managedDashboardTest(
    'showing the sample does not request or retain rider GPS',
    (tester) async {
      final source = TestMapLocation();
      addTearDown(source.close);
      final location = HomeLocationController(source: source);
      final geo = dashboard.MemoryTiles();
      final h = await dashboard.openDashboard(
        tester,
        geoClient: geo,
        mapLocation: location,
        manual: false,
      );
      expect(source.streams, isEmpty);
      expect(location.fix, isNull);
      expect(geo.calls, isEmpty);
      expect(h.navigation.active, isFalse);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );
  dashboard.managedDashboardTest(
    'backgrounding closes the native map and recreates only the public sample',
    (tester) async {
      final sessions = <FakeDeliveryMapSession>[];
      final h = await dashboard.openDashboard(
        tester,
        mapFactory: () {
          final session = FakeDeliveryMapSession();
          sessions.add(session);
          return session;
        },
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(sessions.first.closes, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(LeafletDeliveryMap), findsOneWidget);
      expect(sessions.length, greaterThanOrEqualTo(2));
      expect(h.navigation.active, isFalse);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );
}
