import 'dart:convert';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/native_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/onboarding/data/onboarding_preferences.dart';
import 'package:bagoo_rider_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_all/webview_all.dart';

// Public map only: no account, API session, location or parcel operation.
class ObservedMap implements DeliveryMapSession {
  ObservedMap(this.delegate, this.events);
  final DeliveryMapSession delegate;
  final Set<String> events;
  @override
  Widget get view => delegate.view;
  @override
  Future<void> load(String document, void Function(String) onEvent) =>
      delegate.load(document, (message) {
        final value = jsonDecode(message) as Map;
        events.add(value['type'] as String);
        onEvent(message);
      });
  @override
  Future<void> close() => delegate.close();
}

class IntroPreferences implements OnboardingPreferences {
  bool seen = false;
  @override
  Future<bool> readSeen() async => seen;
  @override
  Future<void> writeSeen(bool value) async {
    seen = value;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'the actual platform renders public street tiles and the road path',
    (tester) async {
      final container = ProviderContainer();
      final factory = container.read(deliveryMapFactoryProvider);
      final events = <String>{};
      final scroll = ScrollController();
      final linux = defaultTargetPlatform == TargetPlatform.linux;
      Widget app(BuildContext context) => MaterialApp(
        // DevicePreview 1.3 checks this legacy flag on direct MaterialApp roots.
        // ignore: deprecated_member_use
        useInheritedMediaQuery: linux,
        locale: linux ? DevicePreview.locale(context) : null,
        builder: linux ? DevicePreview.appBuilder : null,
        theme: buildRiderTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Transform.scale(
                    scale: .85,
                    child: const SizedBox(
                      width: 360,
                      height: 340,
                      child: LeafletDeliveryMap(),
                    ),
                  ),
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryMapFactoryProvider.overrideWithValue(
              () => ObservedMap(factory(), events),
            ),
          ],
          child: linux ? DevicePreview(builder: app) : Builder(builder: app),
        ),
      );

      bool loaded() => linux
          ? find.byType(NativeDeliveryMap).evaluate().isNotEmpty &&
                tester
                    .widgetList<RawImage>(
                      find.descendant(
                        of: find.byType(FlutterMap),
                        matching: find.byType(RawImage),
                      ),
                    )
                    .any((image) => image.image != null)
          : events.contains('ready') && events.contains('tiles-ready');
      for (var i = 0; i < 200 && !loaded(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        loaded(),
        isTrue,
        reason:
            'The actual renderer must load street tiles, not only create a widget. Events: $events',
      );
      expect(find.textContaining('could not'), findsNothing);
      expect(find.textContaining('too long'), findsNothing);
      if (linux) {
        final line = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
        expect(line.polylines.single.points.length, greaterThan(2));
        final controller = tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!;
        final zoom = controller.camera.zoom;
        await tester.tap(find.byTooltip('Zoom in'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.camera.zoom, closeTo(zoom + 1, .001));
        final center = controller.camera.center;
        await tester.timedDrag(
          find.byType(FlutterMap),
          const Offset(40, 65),
          const Duration(milliseconds: 500),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(controller.camera.center, isNot(center));
      } else {
        final view = tester.widget<WebViewWidget>(find.byType(WebViewWidget));
        final controller = view.platform.params.controller;
        Future<Object> transform() => controller.runJavaScriptReturningResult(
          "document.querySelector('.leaflet-map-pane').style.transform",
        );
        final before = await transform();
        await tester.timedDrag(
          find.byType(WebViewWidget),
          const Offset(40, 65),
          const Duration(milliseconds: 500),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(
          await transform(),
          isNot(before),
          reason: 'A finger drag must pan the actual Leaflet map.',
        );
      }
      expect(
        scroll.offset,
        0,
        reason: 'Dragging inside the map must not scroll its parent page.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 250));
      container.dispose();
      scroll.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'the welcome artwork, bundled logo and all three pages render on the actual device',
    (tester) async {
      final preferences = IntroPreferences();
      var applied = false;
      final linux = defaultTargetPlatform == TargetPlatform.linux;
      Widget app(BuildContext context) => MaterialApp(
        // DevicePreview 1.3 validates the legacy flag on direct MaterialApp roots.
        // ignore: deprecated_member_use
        useInheritedMediaQuery: linux,
        locale: linux ? DevicePreview.locale(context) : null,
        builder: linux ? DevicePreview.appBuilder : null,
        theme: buildRiderTheme(),
        home: RiderOnboardingPage(onApply: () => applied = true),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingPreferencesProvider.overrideWithValue(preferences),
          ],
          child: linux ? DevicePreview(builder: app) : Builder(builder: app),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Every parcel starts with you.'), findsOneWidget);
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((image) => image.image != null),
        isTrue,
        reason: 'The real bundled brand image must load.',
      );
      for (var page = 0; page < 3; page++) {
        expect(find.byKey(ValueKey('onboarding-art-$page')), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('onboarding-cta')),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(const ValueKey('onboarding-cta')));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
      expect(applied, isTrue);
      expect(preferences.seen, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
}
