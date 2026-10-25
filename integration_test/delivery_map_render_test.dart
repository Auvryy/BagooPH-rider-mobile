import 'dart:convert';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/native_delivery_map.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'the actual platform renders public street tiles and the road path',
    (tester) async {
      final container = ProviderContainer();
      final factory = container.read(deliveryMapFactoryProvider);
      final events = <String>{};
      final linux = defaultTargetPlatform == TargetPlatform.linux;
      Widget app(BuildContext context) => MaterialApp(
      // DevicePreview 1.3 checks this legacy flag on direct MaterialApp roots.
      // ignore: deprecated_member_use
      useInheritedMediaQuery: linux,
        locale: linux ? DevicePreview.locale(context) : null,
        builder: linux ? DevicePreview.appBuilder : null,
        theme: buildRiderTheme(),
        home: Scaffold(
          body: Center(
            child: Transform.scale(
              scale: .85,
              child: const SizedBox(
                width: 360,
                height: 340,
                child: LeafletDeliveryMap(),
              ),
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
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 250));
      container.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
