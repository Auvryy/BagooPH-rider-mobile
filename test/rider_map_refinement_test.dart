import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/home_location_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/native_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'home_dashboard_test.dart' as dashboard;
import 'support/map_location.dart';

void main() {
  for (final (size, scale) in [
    (const Size(320, 640), 2.0),
    (const Size(375, 812), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(1200, 500), 1.0),
    (const Size(1200, 850), 1.0),
  ]) {
    dashboard.managedDashboardTest(
      'light Leaflet standby remains usable at $size and ${scale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final h = await dashboard.openDashboard(tester, textScale: scale);
        expect(find.byType(LeafletDeliveryMap), findsOneWidget);
        expect(
          find.text('Rider GPS standby'),
          findsOneWidget,
        );
        expect(find.textContaining('Current rider GPS · Standby'), findsOneWidget);
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
    'standby map requests live GPS on Home without hardcoded sample lines and clears GPS when hidden',
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
      expect(find.byType(NativeDeliveryMap), findsOneWidget);
      expect(source.streams, hasLength(1));
      const realPoint = LatLng(14.5547, 121.0244);
      source.streams.single.add(LocationFix(realPoint, DateTime.now(), 12));
      await tester.pumpAndSettle();
      expect(location.fix?.point, realPoint);
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.single.point, realPoint);
      expect(find.byType(PolylineLayer), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(location.fix, isNull);
      expect(geo.calls, isEmpty);
      expect(h.navigation.active, isFalse);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );
  dashboard.managedDashboardTest(
    'backgrounding pauses the native map and recreates standby map on resume',
    (tester) async {
      final h = await dashboard.openDashboard(tester);
      expect(find.byType(FlutterMap), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Map paused while the app is hidden.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(h.navigation.active, isFalse);
      expect(h.api.calls.every((c) => c.method == 'GET'), isTrue);
    },
  );
}
