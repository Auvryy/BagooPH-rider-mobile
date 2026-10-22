import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_map_chrome.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/map_tile_source.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/home_location_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'home_dashboard_test.dart' as dashboard;
import 'support/map_location.dart';

const _origin = LatLng(14.6, 121);
const _stop = LatLng(14.606, 121.008);

class _Artwork extends dashboard.MemoryTiles {
  static const directory = String.fromEnvironment('MAP_ARTWORK_DIR');
  final requested = <String>{};
  @override
  Future<Uint8List> tile(
    int z,
    int x,
    int y, {
    CancelToken? cancel,
    MapTileSource source = const MapTileSource(),
  }) async {
    final path =
        '${source.style.providerId}/$z-$x-$y${source.retina ? '@2x' : ''}.png';
    requested.add(path);
    final fallback = await super.tile(z, x, y, cancel: cancel, source: source);
    if (directory.isNotEmpty) {
      final file = File('$directory/$path');
      if (file.existsSync()) return file.readAsBytesSync();
    }
    return fallback;
  }
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  _Artwork artwork,
) async {
  if (!const bool.fromEnvironment('MAP_RENDER')) return;
  // Native image decoding runs outside the widget test's fake clock. Wait for
  // the real tile codecs before capturing, then advance the tile fade frames.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (PaintingBinding.instance.imageCache.pendingImageCount > 0 &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('home-dashboard-render')),
  );
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  repaint(boundary);
  await tester.pump();
  await tester.runAsync(() async {
    final picture = await boundary.toImage(pixelRatio: 1.5);
    final data = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/map-refinement/renders/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    final welcome = find.text('Welcome, Example Rider.');
    File('build/map-refinement/renders/$name.layout.json').writeAsStringSync(
      jsonEncode({
        'view': {
          'width': tester.view.physicalSize.width,
          'height': tester.view.physicalSize.height,
        },
        'welcome': welcome.evaluate().isEmpty
            ? null
            : tester.getRect(welcome).toString(),
        'map': tester.getRect(find.byType(FlutterMap)).toString(),
        'root': tester
            .getRect(find.byKey(const ValueKey('home-dashboard-render')))
            .toString(),
      }),
    );
    picture.dispose();
    final requests = File('build/map-refinement/tiles-needed.txt');
    final all = {
      ...(requests.existsSync() ? requests.readAsLinesSync() : <String>[]),
      ...artwork.requested,
    }.toList()..sort();
    requests.writeAsStringSync('${all.join('\n')}\n');
  });
}

MapCamera _camera(WidgetTester tester) => tester
    .widget<FlutterMap>(find.byType(FlutterMap, skipOffstage: false))
    .mapController!
    .camera;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Plus Jakarta Sans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  dashboard.managedDashboardTest(
    'valid foreground GPS automatically frames the rider before a distant queued stop',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final source = TestMapLocation();
      addTearDown(source.close);
      final location = HomeLocationController(source: source);
      final geo = _Artwork();
      final h = await dashboard.openDashboard(
        tester,
        geoClient: geo,
        mapLocation: location,
        manual: false,
        stopPoint: const LatLng(10.3157, 123.8854),
      );
      expect(source.streams, hasLength(1));
      expect(h.navigation.active, isFalse);
      source.streams.single.add(LocationFix(_origin, DateTime.now(), 5));
      await tester.pumpAndSettle();
      expect(
        _camera(tester).center.latitude,
        closeTo(_origin.latitude, .000001),
      );
      expect(
        _camera(tester).center.longitude,
        closeTo(_origin.longitude, .000001),
      );
      expect(_camera(tester).zoom, 15);
      expect(find.text('Your area'), findsOneWidget);
      expect(find.byType(HomeMapPositionMarker), findsOneWidget);
      expect(h.navigation.active, isFalse);
      expect(source.cancelled, 1);
      expect(geo.sources.every((s) => s.style == MapTileStyle.dark), isTrue);
      expect(h.api.calls.every((call) => call.method == 'GET'), isTrue);
      await _capture(tester, 'gps-rider-area', geo);
    },
  );

  dashboard.managedDashboardTest(
    'panning holds the camera through a later snapshot until explicit Recenter',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final source = TestMapLocation();
      addTearDown(source.close);
      final location = HomeLocationController(source: source);
      final h = await dashboard.openDashboard(
        tester,
        geoClient: _Artwork(),
        mapLocation: location,
        manual: false,
      );
      source.streams.single.add(LocationFix(_origin, DateTime.now(), 5));
      await tester.pumpAndSettle();
      final map = find.byType(FlutterMap);
      await tester.dragFrom(
        tester.getTopLeft(map) + const Offset(50, 140),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      final held = _camera(tester).center;
      expect(h.navigation.following, isFalse);
      await location.locate();
      source.streams.last.add(
        LocationFix(const LatLng(14.602, 121.003), DateTime.now(), 5),
      );
      await tester.pumpAndSettle();
      expect(_camera(tester).center, held);
      await dashboard.tapHome(tester, find.byTooltip('Recenter'));
      source.streams.last.add(LocationFix(_origin, DateTime.now(), 5));
      await tester.pumpAndSettle();
      expect(h.navigation.following, isTrue);
      expect(_camera(tester).center, _origin);
    },
  );

  dashboard.managedDashboardTest(
    'backgrounding Home cancels acquisition and returning requests a silent fresh sample',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final source = TestMapLocation();
      addTearDown(source.close);
      final location = HomeLocationController(source: source);
      await dashboard.openDashboard(
        tester,
        geoClient: _Artwork(),
        mapLocation: location,
        manual: false,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(source.cancelled, 1);
      expect(location.locating, isFalse);
      expect(location.fix, isNull);
      expect(find.byType(FlutterMap), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(source.requests, [true, false]);
      source.streams.last.add(LocationFix(_origin, DateTime.now(), 5));
      await tester.pumpAndSettle();
      expect(_camera(tester).center, _origin);
    },
  );

  dashboard.managedDashboardTest(
    'Linux starts in PH and only an entered manual origin creates the preview marker',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      final location = HomeLocationController(manual: true);
      final geo = _Artwork();
      final h = await dashboard.openDashboard(
        tester,
        coordinates: false,
        geoClient: geo,
        mapLocation: location,
      );
      expect(find.text('Philippines overview'), findsOneWidget);
      expect(_camera(tester).zoom, lessThan(7));
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      await _capture(tester, 'philippines-overview', geo);
      await dashboard.tapHome(
        tester,
        find.byKey(const ValueKey('home-preview-area')),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Preview latitude'),
        '51',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Preview longitude'),
        '0',
      );
      await tester.tap(find.text('Show area'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter valid coordinates on the Philippines map.'),
        findsOneWidget,
      );
      expect(location.fix, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Preview latitude'),
        '14.6',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Preview longitude'),
        '121',
      );
      await tester.tap(find.text('Show area'));
      await tester.pumpAndSettle();
      expect(location.fix?.point, _origin);
      expect(find.text('Preview area'), findsWidgets);
      expect(find.text('Manual preview origin'), findsOneWidget);
      expect(_camera(tester).center, _origin);
      expect(_camera(tester).zoom, 15);
      expect(h.navigation.active, isFalse);
    },
  );

  for (final view in [
    (size: const Size(375, 812), scale: 1.0, reduced: false),
    (size: const Size(320, 640), scale: 2.0, reduced: true),
    (size: const Size(844, 390), scale: 1.0, reduced: true),
    (size: const Size(1200, 500), scale: 1.0, reduced: true),
    (size: const Size(1200, 850), scale: 1.0, reduced: false),
  ]) {
    dashboard.managedDashboardTest(
      'dark/daylight map controls remain usable at ${view.size}, ${view.scale}x text',
      (tester) async {
        tester.view.physicalSize = view.size;
        tester.view.devicePixelRatio = 1;
        final location = HomeLocationController(manual: true)
          ..setManualOrigin(_origin);
        final geo = _Artwork();
        final h = await dashboard.openDashboard(
          tester,
          geoClient: geo,
          mapLocation: location,
          stopPoint: _stop,
          textScale: view.scale,
          reducedMotion: view.reduced,
        );
        final feature = tester.widget<HomeMapChrome>(
          find.byType(HomeMapChrome),
        );
        expect(feature.dark, isTrue);
        expect(find.byType(DraggableScrollableSheet), findsNothing);
        for (final name in [
          'Zoom in',
          'Zoom out',
          'Recenter',
          'Use daylight map',
        ]) {
          expect(
            tester.getSize(find.byTooltip(name)).shortestSide,
            greaterThanOrEqualTo(48),
          );
        }
        // Freeze an explicitly synthetic route for layout review. Opt-in artwork
        // can supply real Geoapify geometry for these same public sample points.
        final sample = File('${_Artwork.directory}/sample-route.json');
        final road = _Artwork.directory.isNotEmpty && sample.existsSync()
            ? RoadRoute.geoJson(jsonDecode(sample.readAsStringSync()))
            : RoadRoute([
                [_origin, const LatLng(14.602, 121.003), _stop],
              ]);
        h.navigation.task = h.task;
        h.navigation.active = true;
        h.navigation.fix = LocationFix(_origin, DateTime.now(), 5);
        h.navigation.road = road;
        h.navigation.recenter();
        await tester.pumpAndSettle();
        final line = tester
            .widget<PolylineLayer>(find.byType(PolylineLayer))
            .polylines
            .first;
        expect(line.borderStrokeWidth, greaterThan(0));
        expect(_camera(tester).center, _origin);
        expect(_camera(tester).zoom, greaterThanOrEqualTo(14));
        await dashboard.revealHome(tester, find.byType(HomeMapChrome));
        await _capture(
          tester,
          'dark-${view.size.width.toInt()}-${view.size.height.toInt()}-${view.scale}x',
          geo,
        );
        final tokens = geo.tokens.toList();
        final before = _camera(tester).center;
        await dashboard.tapHome(tester, find.byTooltip('Use daylight map'));
        expect(
          tester.widget<HomeMapChrome>(find.byType(HomeMapChrome)).dark,
          isFalse,
        );
        expect(tokens.every((token) => token.isCancelled), isTrue);
        expect(_camera(tester).center, before);
        expect(h.navigation.active, isTrue);
        expect(h.navigation.road, same(road));
        await _capture(
          tester,
          'daylight-${view.size.width.toInt()}-${view.size.height.toInt()}-${view.scale}x',
          geo,
        );
        await dashboard.tapHome(tester, find.byTooltip('Zoom in'));
        expect(h.navigation.following, isFalse);
        await dashboard.tapHome(tester, find.byTooltip('Show full route'));
        for (final point in road.lines.expand((line) => line)) {
          expect(_camera(tester).visibleBounds.contains(point), isTrue);
        }
        await dashboard.revealHome(tester, find.text('Powered by Geoapify'));
        expect(find.text('Powered by Geoapify'), findsOneWidget);
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (view.size.width == 375) {
          final semantics = tester.ensureSemantics();
          try {
            await dashboard.revealHome(tester, find.byTooltip('Zoom in'));
            final zoom = find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Zoom in',
            );
            final node = tester.getSemantics(zoom).getSemanticsData();
            expect(node.label, 'Zoom in');
            expect(node.hasAction(ui.SemanticsAction.tap), isTrue);
            final previousZoom = _camera(tester).zoom;
            Focus.of(
              tester.element(
                find.descendant(
                  of: zoom,
                  matching: find.byIcon(Icons.add_rounded),
                ),
              ),
            ).requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(_camera(tester).zoom, closeTo(previousZoom + 1, .0001));
          } finally {
            semantics.dispose();
          }
        }
      },
    );
  }

  test('map-specific text and route colors maintain independent contrast', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final la = luminance(a), lb = luminance(b);
      return ((la > lb ? la : lb) + .05) / ((la > lb ? lb : la) + .05);
    }

    expect(
      contrast(RiderMapColors.ink, RiderMapColors.surface),
      greaterThan(4.5),
    );
    expect(
      contrast(RiderMapColors.muted, RiderMapColors.surface),
      greaterThan(4.5),
    );
    expect(
      contrast(RiderMapColors.routeOutline, RiderMapColors.canvas),
      greaterThan(3),
    );
    expect(contrast(RiderColors.ink, RiderColors.surface), greaterThan(4.5));
  });

  dashboard.managedDashboardTest(
    'high-density displays select native 2x tiles automatically',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      final geo = _Artwork();
      await dashboard.openDashboard(tester, geoClient: geo);
      expect(geo.sources, isNotEmpty);
      expect(geo.sources.every((source) => source.retina), isTrue);
      expect(
        geo.sources.every((source) => source.style == MapTileStyle.dark),
        isTrue,
      );
      await dashboard.tapHome(
        tester,
        find.byKey(const ValueKey('home-sharper-labels')),
      );
      expect(geo.sources.any((source) => !source.retina), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
