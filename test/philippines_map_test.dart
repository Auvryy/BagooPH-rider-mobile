import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_map_focus.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/philippines_map_region.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/philippines_map_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'operations_contract_test.dart' as support;

OperationTask mapTask({
  String id = '1',
  double? latitude = 14.6,
  double? longitude = 121,
}) {
  final json =
      support.fixture('final-mile-task')['data'] as Map<String, dynamic>;
  json['id'] = 'final_mile-$id';
  json['delivery_id'] = id;
  final stop = json['stop'] as Map<String, dynamic>;
  stop['latitude'] = latitude;
  stop['longitude'] = longitude;
  return OperationTask.fromJson(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhilippinesMapRegion region;
  setUpAll(() async {
    region = PhilippinesMapRegion.decode(
      await File('assets/maps/philippines-display.geojson').readAsString(),
    );
  });
  test(
    'bundled country outline retains islands and GeoJSON coordinate order',
    () async {
      final loaded = PhilippinesMapRegion.decode(
        await rootBundle.loadString('assets/maps/philippines-display.geojson'),
      );
      final metadata = jsonDecode(
        await File('assets/maps/philippines-display-source.json')
            .readAsString(),
      );
      expect(loaded.polygons.length, metadata['sourcePolygons']);
      expect(loaded.polygons.length, 2852);
      final raw = jsonDecode(
        await File('assets/maps/philippines-display.geojson').readAsString(),
      );
      expect(
        loaded.polygons.first.first.first.longitude,
        raw['coordinates'][0][0][0][0],
      );
      expect(
        loaded.polygons.first.first.first.latitude,
        raw['coordinates'][0][0][0][1],
      );
      for (final point in [
        const LatLng(14.6, 121),
        const LatLng(10.3157, 123.8854),
        const LatLng(7.073, 125.612),
        const LatLng(20.45, 121.97),
      ]) {
        expect(region.containsLand(point), isTrue, reason: '$point');
      }
      for (final point in [
        const LatLng(1.35, 103.82),
        const LatLng(25, 121.5),
        const LatLng(6, 116),
        const LatLng(14.65, 120.9),
      ]) {
        expect(region.containsLand(point), isFalse, reason: '$point');
      }
    },
  );
  test(
    'malformed outlines fail clearly instead of producing a guessed mask',
    () {
      for (final json in [
        {'type': 'Polygon', 'coordinates': []},
        {'type': 'MultiPolygon', 'coordinates': []},
        {
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [121, 14],
                [121, 15],
                [122, 15],
                [122, 14],
              ],
            ],
          ],
        },
        {
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [1, 1],
                [1, 2],
                [2, 2],
                [1, 1],
              ],
            ],
          ],
        },
      ]) {
        expect(
          () => PhilippinesMapRegion.decode(jsonEncode(json)),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'runtime provider loads the bundled outline through the asset/isolate path',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final loaded = await container.read(philippinesMapRegionProvider.future);
      expect(loaded.polygons, hasLength(2852));
      expect(loaded.containsLand(const LatLng(14.6, 121)), isTrue);
    },
  );
  test('active navigation frames real road points before another selection or queue', () {
    final current = mapTask(),
        other = mapTask(id: '2', latitude: 10.3157, longitude: 123.8854);
    final road = RoadRoute([
      [
        const LatLng(14.61, 121.01),
        const LatLng(14.62, 121.02),
        const LatLng(14.6, 121),
      ],
    ]);
    final focus = HomeMapFocus.resolve(
      region: region,
      navigatingTask: current,
      fix: LocationFix(const LatLng(14.61, 121.01), DateTime.now(), 5),
      road: road,
      selectedTask: other,
      queuedTasks: [other],
    );
    expect(focus.kind, HomeMapFocusKind.navigation);
    expect(focus.points, containsAll(road.lines.single));
    expect(focus.points, isNot(contains(const LatLng(10.3157, 123.8854))));
    expect(focus.label, 'Current route');
  });
  test('selected stop remains the focus and one unchanged pin when the list is filtered', () {
    final selected = mapTask(), other = mapTask(id: '2');
    final focus = HomeMapFocus.resolve(
      region: region,
      selectedTask: selected,
      queuedTasks: [other],
    );
    expect(focus.kind, HomeMapFocusKind.selectedStop);
    expect(focus.points, [const LatLng(14.6, 121)]);
    final pins = HomeMapFocus.pins(
      queuedTasks: [other],
      selectedTask: selected,
      navigatingTask: selected,
    );
    expect(pins.map((t) => t.id), containsAll([selected.id, other.id]));
    expect(pins.where((t) => t.id == selected.id), hasLength(1));
    expect(pins.firstWhere((t) => t.id == selected.id), same(selected));
  });
  test('unknown and outside-outline destinations retain data without a replacement point', () {
    final missing = mapTask(latitude: null, longitude: null);
    final outside = mapTask(latitude: 6, longitude: 116);
    for (final task in [missing, outside]) {
      final focus = HomeMapFocus.resolve(
        region: region,
        selectedTask: task,
        queuedTasks: [mapTask(id: '2')],
      );
      expect(focus.kind, HomeMapFocusKind.overview);
      expect(focus.points, isEmpty);
      expect(focus.missingCoordinates, task == missing);
      expect(focus.outsideOutline, task == outside);
    }
    expect(HomeMapFocus.pointFor(outside), const LatLng(6, 116));
    expect(
      HomeMapFocus.pins(queuedTasks: [], selectedTask: outside).single,
      same(outside),
    );
  });
  test('queue/country fallback never guesses rider or hub positions', () {
    final queued = HomeMapFocus.resolve(
      region: region,
      queuedTasks: [mapTask()],
    );
    expect(queued.kind, HomeMapFocusKind.queuedStops);
    final country = HomeMapFocus.resolve(
      region: region,
      queuedTasks: [mapTask(latitude: null, longitude: null)],
    );
    expect(country.kind, HomeMapFocusKind.overview);
    expect(country.label, 'Philippines overview');
    expect(country.points, isEmpty);
    expect(
      PhilippinesMapRegion.tileIntersectsDisplay(15, 27390, 15025),
      isTrue,
    );
    expect(PhilippinesMapRegion.tileIntersectsDisplay(15, 0, 0), isFalse);
    expect(PhilippinesMapRegion.tileIntersectsDisplay(22, 0, 0), isFalse);
  });

  test('a real rider snapshot takes priority over distant queued stops but selection stays deliberate', () {
    final rider = LocationFix(const LatLng(14.6, 121), DateTime.now(), 5);
    final other = mapTask(latitude: 10.3157, longitude: 123.8854);
    final focus = HomeMapFocus.resolve(
      region: region,
      riderFix: rider,
      queuedTasks: [other],
    );
    expect(focus.kind, HomeMapFocusKind.rider);
    expect(focus.points, [rider.point]);
    expect(focus.label, 'Your area');
    final selected = HomeMapFocus.resolve(
      region: region,
      riderFix: rider,
      selectedTask: other,
      queuedTasks: [],
    );
    expect(selected.kind, HomeMapFocusKind.selectedStop);
    expect(selected.points, [const LatLng(10.3157, 123.8854)]);
    final preview = HomeMapFocus.resolve(
      region: region,
      riderFix: rider,
      manual: true,
      queuedTasks: [],
    );
    expect(preview.label, 'Preview area');
    final outside = HomeMapFocus.resolve(
      region: region,
      riderFix: LocationFix(const LatLng(6, 116), DateTime.now(), 5),
      queuedTasks: [],
    );
    expect(outside.kind, HomeMapFocusKind.overview);
  });

  final views = [
    for (final width in [320.0, 1000.0])
      for (var zoom = 4; zoom <= 19; zoom++)
        (width: width, zoom: zoom.toDouble(), rotation: 0.0),
    for (final zoom in [4.5, 10.5, 18.5])
      (width: 390.0, zoom: zoom, rotation: 20.0),
  ];
  for (final view in views) {
    final zoom = view.zoom;
    testWidgets(
      'country mask at ${view.width}px, zoom $zoom, rotation ${view.rotation}',
      (tester) async {
        tester.view.physicalSize = Size(view.width, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = MapController();
        addTearDown(controller.dispose);
        final key = GlobalKey();
        final isOverview = zoom <= 6;
        final center = isOverview
            ? PhilippinesMapRegion.cameraBounds.center
            : const LatLng(14.6, 121);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoom,
                    initialRotation: view.rotation,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: PhilippinesMapRegion.cameraBounds,
                    ),
                  ),
                  children: [
                    const SizedBox.expand(
                      child: ColoredBox(color: Colors.green),
                    ),
                    PhilippinesMapMask(region: region),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final capture = (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final folder = Directory('build/ph-map-verification')
            ..createSync(recursive: true);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${folder.path}/mask-w${view.width.toInt()}-z$zoom-r${view.rotation}.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
          final result = (
            width: image.width,
            height: image.height,
            bytes: bytes,
          );
          image.dispose();
          return result;
        }))!;
        final bytes = capture.bytes;
        Color at(LatLng point) {
          final offset = controller.camera.latLngToScreenOffset(point);
          final x = offset.dx.round(), y = offset.dy.round();
          expect(x, inInclusiveRange(0, capture.width - 1));
          expect(y, inInclusiveRange(0, capture.height - 1));
          final i = (y * capture.width + x) * 4;
          return Color.fromARGB(
            bytes.getUint8(i + 3),
            bytes.getUint8(i),
            bytes.getUint8(i + 1),
            bytes.getUint8(i + 2),
          );
        }

        expect(at(const LatLng(14.6, 121)).toARGB32(), Colors.green.toARGB32());
        if (zoom == 4) {
          expect(
            at(const LatLng(25, 121.5)).toARGB32(),
            RiderColors.canvas.toARGB32(),
          );
          expect(
            at(const LatLng(6, 116)).toARGB32(),
            RiderColors.canvas.toARGB32(),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
