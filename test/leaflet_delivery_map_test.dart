import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/road_routing.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/leaflet_delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/delivery_map.dart';

Widget view(DeliveryMapFactory factory) => ProviderScope(
  overrides: [
    deliveryMapFactoryProvider.overrideWithValue(factory),
    deliveryMapDocumentProvider.overrideWithValue(
      () async => "<title>Sample delivery route</title>",
    ),
  ],
  child: MaterialApp(
    theme: buildRiderTheme(),
    home: const Scaffold(
      body: SizedBox(height: 420, child: LeafletDeliveryMap()),
    ),
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the bundled Leaflet document uses unfiltered OSM tiles with no key or account connection', () async {
    final doc = await deliveryMapDocument();
    expect(doc, contains('Leaflet 1.9.4'));
    expect(doc, contains('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
    expect(doc, contains("connect-src 'none'"));
    expect(doc, contains('OpenStreetMap contributors'));
    expect(doc, contains('Plus Jakarta Sans'));
    expect(doc, contains('smoothFactor: 0'));
    expect(doc, isNot(contains('geoapify')));
    expect(doc, isNot(contains('grayscale(')));
    expect(
      File('assets/maps/rider-delivery-map.js').readAsStringSync(),
      isNot(contains('getCurrentPosition')),
    );
    expect(
      File('assets/maps/rider-delivery-map.js').readAsStringSync(),
      isNot(contains('watchPosition')),
    );
  });
  test('the sample contains a rider and delivery illustration without logistics or private parcel data', () {
    final sample = jsonDecode(
      File('assets/maps/rider-delivery-sample.json').readAsStringSync(),
    ) as Map;
    expect(
      sample['notice'],
      contains('not a live rider or an assigned parcel'),
    );
    expect((sample['coordinates'] as List).length, greaterThan(2));
    expect(
      jsonEncode(sample),
      isNot(matches('hub|logistics|parcel_id|token|apiKey')),
    );
    expect(UnavailableRoadRouting().configured, isFalse);
  });
  testWidgets(
    'the local renderer mounts, reports tile errors, retries and closes once',
    (tester) async {
      final sessions = <FakeDeliveryMapSession>[];
      await tester.pumpWidget(
        view(() {
          final session = FakeDeliveryMapSession();
          sessions.add(session);
          return session;
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leaflet test view'), findsOneWidget);
      expect(sessions.single.document, contains('Sample delivery route'));
      sessions.single.event!('{"type":"tiles-unavailable"}');
      await tester.pump();
      expect(
        find.textContaining('Street tiles could not load'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry map'));
      await tester.pumpAndSettle();
      expect(sessions, hasLength(2));
      expect(sessions.first.closes, 1);
      expect(find.textContaining('Street tiles could not load'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(sessions.last.closes, 1);
    },
  );
  testWidgets(
    'a load completing after unmount cannot restore a map or callback',
    (tester) async {
      final pending = Completer<void>();
      final session = FakeDeliveryMapSession()..pending = pending;
      await tester.pumpWidget(view(() => session));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(session.closes, 1);
      pending.complete();
      await tester.pumpAndSettle();
      session.event?.call('{"type":"ready"}');
      await tester.pump();
      expect(find.text('Leaflet test view'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'startup failure gives a retry and ignores malformed bridge messages',
    (tester) async {
      final broken = FakeDeliveryMapSession()
        ..error = StateError('unavailable');
      await tester.pumpWidget(view(() => broken));
      await tester.pumpAndSettle();
      expect(find.textContaining('The map could not open'), findsOneWidget);
      expect(find.text('Retry map'), findsOneWidget);
      broken.event?.call('{"type":"ready","foreign":"value"}');
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
