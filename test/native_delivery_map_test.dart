import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/native_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class FailedTile extends Fake implements TileImage {}

class MemoryTiles extends TileProvider {
  int closed = 0;
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
  @override
  void dispose() {
    closed++;
  }
}

List<LatLng> samplePoints() =>
    ((jsonDecode(
              File('assets/maps/rider-delivery-sample.json').readAsStringSync(),
            ) as Map)['coordinates']
            as List)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the native map loads the same complete road geometry as the bundled renderer', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      await container.read(deliveryRoadPointsProvider.future),
      samplePoints(),
    );
  });

  testWidgets(
    'Linux phone preview uses the real Flutter map with road bends, pins and working controls',
    (tester) async {
      final tiles = <MemoryTiles>[];
      final points = samplePoints();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryRoadPointsProvider.overrideWith((ref) async => points),
            deliveryTilesProvider.overrideWithValue(() {
              final provider = MemoryTiles();
              tiles.add(provider);
              return provider;
            }),
            deliveryMapFactoryProvider.overrideWithValue(
              () => throw StateError(
                'Linux must not create a native WebView overlay.',
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: Center(
                child: Transform.scale(
                  scale: .7,
                  child: const SizedBox(
                    width: 390,
                    height: 340,
                    child: LeafletDeliveryMap(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NativeDeliveryMap), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
      final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(line.polylines.single.points, points);
      expect(line.simplificationTolerance, 0);
      expect(line.polylines.single.color, const Color(0xFFE00D42));
      expect(
        tester
            .widget<MarkerLayer>(find.byType(MarkerLayer))
            .markers
            .map((pin) => pin.point),
        [points.first, points.last],
      );
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      final initialZoom = controller.camera.zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, closeTo(initialZoom + 1, .001));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, closeTo(initialZoom, .001));
      controller.move(points.first, 18);
      await tester.pump();
      await tester.tap(find.byTooltip('Show sample route'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, closeTo(initialZoom, .001));
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expect(tiles, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tiles.single.closed, 1);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'tile errors keep the route visible, and retry replaces and disposes the tile source',
    (tester) async {
      final tiles = <MemoryTiles>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryRoadPointsProvider.overrideWith(
              (ref) async => samplePoints(),
            ),
            deliveryTilesProvider.overrideWithValue(() {
              final provider = MemoryTiles();
              tiles.add(provider);
              return provider;
            }),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: const Scaffold(
              body: SizedBox(
                width: 390,
                height: 340,
                child: NativeDeliveryMap(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      layer.errorTileCallback!(FailedTile(), Exception('No network'), null);
      await tester.pump();
      await tester.pump();
      expect(
        find.textContaining('Street tiles could not load'),
        findsOneWidget,
      );
      expect(find.byType(PolylineLayer), findsOneWidget);
      await tester.tap(find.text('Retry map'));
      await tester.pumpAndSettle();
      expect(tiles, hasLength(2));
      expect(tiles.first.closed, 1);
      expect(find.textContaining('Street tiles could not load'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tiles.last.closed, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
