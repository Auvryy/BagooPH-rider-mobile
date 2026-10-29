import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/saved_delivery_stop.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/native_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/delivery_map.dart';

OperationTask task({
  double? latitude = 14.3,
  double longitude = 121.2,
  String name = 'Recorded buyer',
}) {
  final json = jsonDecode(
    File('test/fixtures/operations/final-mile-task.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  (json['data']['stop'] as Map<String, dynamic>).addAll(<String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
  });
  return OperationTask.fromJson(json['data'] as Map<String, dynamic>);
}

class SavedStopTiles extends TileProvider {
  int closes = 0;
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
  @override
  void dispose() {
    closes++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('saved pins require actual renderable stop coordinates without replacing or clamping them', () {
    expect(SavedDeliveryStop.fromTask(null), isNull);
    for (final latitude in [null, double.nan, double.infinity, 86.0]) {
      expect(SavedDeliveryStop.fromTask(task(latitude: latitude)), isNull);
    }
    final stop = SavedDeliveryStop.fromTask(task())!;
    expect(stop.latitude, 14.3);
    expect(stop.longitude, 121.2);
    expect(stop.label, 'Recorded buyer');
    expect(stop, SavedDeliveryStop.fromTask(task()));
    expect(stop, isNot(SavedDeliveryStop.fromTask(task(longitude: 121.3))));
  });

  test('saved stop labels cannot end a document script or add executable markup', () {
    const label = '</script><script>alert(1)</script>\u2028\u2029';
    final stop = SavedDeliveryStop.fromTask(task(name: label))!;
    const base =
        '<div aria-label="Sample rider to delivery route"></div><script>window.riderDeliverySample={};</script>';
    final document = deliveryMapDocumentForStop(base, stop);
    expect(document, contains('aria-label="Saved current stop"'));
    expect(document, isNot(contains(label)));
    final encoded = document
        .split('window.riderSavedStop=')
        .last
        .split(';\nwindow.riderDeliverySample=')
        .first;
    expect((jsonDecode(encoded) as Map)['label'], label);
    expect(
      () => deliveryMapDocumentForStop('<title>Missing assets</title>', stop),
      throwsFormatException,
    );
  });

  testWidgets(
    'switching saved parcels closes the old renderer and ignores its late events',
    (tester) async {
      final sessions = <FakeDeliveryMapSession>[];
      final selected = ValueNotifier(SavedDeliveryStop.fromTask(task())!);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryMapDocumentProvider.overrideWithValue(
              () async => '<script>window.riderDeliverySample={};</script>',
            ),
            deliveryMapFactoryProvider.overrideWithValue(() {
              final session = FakeDeliveryMapSession();
              sessions.add(session);
              return session;
            }),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: ValueListenableBuilder<SavedDeliveryStop>(
                  valueListenable: selected,
                  builder: (_, stop, _) => LeafletDeliveryMap(stop: stop),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sessions.single.document, contains('"longitude":121.2'));
      selected.value = SavedDeliveryStop.fromTask(task(longitude: 121.3))!;
      await tester.pumpAndSettle();
      expect(sessions, hasLength(2));
      expect(sessions.first.closes, 1);
      expect(sessions.last.document, contains('"longitude":121.3'));
      sessions.first.event?.call('{"type":"tiles-unavailable"}');
      await tester.pump();
      expect(find.textContaining('Street tiles could not load'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(sessions.last.closes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Linux saved stops use one pin, no sample geometry, and can be recentered after dragging',
    (tester) async {
      final tiles = SavedStopTiles();
      final stop = SavedDeliveryStop.fromTask(task())!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryRoadPointsProvider.overrideWith(
              (_) =>
                  throw StateError('A saved stop must not load a sample road.'),
            ),
            deliveryTilesProvider.overrideWithValue(() => tiles),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: LeafletDeliveryMap(stop: stop),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PolylineLayer), findsNothing);
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers.single.point, const LatLng(14.3, 121.2));
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      controller.move(const LatLng(14.4, 121.3), 14);
      await tester.pump();
      await tester.tap(find.byTooltip('Recenter current stop'));
      await tester.pumpAndSettle();
      expect(controller.camera.center, markers.single.point);
      expect(controller.camera.zoom, 16);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tiles.closes, 1);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );
}
