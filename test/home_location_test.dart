import 'dart:async';

import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/foreground_map_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/home_location_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'navigation_test.dart' as navigation;
import 'support/map_location.dart';
import 'support/test_auth_repository.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 22, 4);
  const point = LatLng(14.6, 121);

  test(
    'Home acquires one valid fresh snapshot and cancels GPS immediately',
    () async {
      final source = TestMapLocation();
      final c = HomeLocationController(source: source, now: () => now);
      addTearDown(() async {
        c.dispose();
        await source.close();
      });
      c.setVisible(true);
      await flush();
      expect(source.requests, [true]);
      expect(c.locating, isTrue);
      for (final value in [
        LocationFix(point, now.subtract(const Duration(seconds: 31)), 5),
        LocationFix(point, now.add(const Duration(seconds: 1)), 5),
        LocationFix(point, now, 51),
        LocationFix(point, now, double.nan),
        LocationFix(const LatLng(100, 121), now, 5),
      ]) {
        source.streams.single.add(value);
      }
      await flush();
      expect(c.fix, isNull);
      expect(source.cancelled, 0);
      source.streams.single.add(LocationFix(point, now, 12));
      await flush();
      expect(c.fix?.point, point);
      expect(c.locating, isFalse);
      expect(source.cancelled, 1);
      expect(c.message, isNull);
      await c.locate();
      expect(
        c.fix?.point,
        point,
        reason: 'Keep the accepted snapshot while replacing it instead of jumping to a distant queue.',
      );
      source.permission = MapLocationAccess.denied;
      await c.suspend();
      c.setVisible(true);
      await flush();
      expect(c.fix, isNull);
      expect(c.message, contains('Allow location'));
    },
  );

  for (final access in [
    MapLocationAccess.denied,
    MapLocationAccess.deniedForever,
    MapLocationAccess.servicesOff,
  ]) {
    test(
      '$access keeps Home browsable without starting a GPS stream',
      () async {
        final source = TestMapLocation()..permission = access;
        final c = HomeLocationController(source: source);
        addTearDown(c.dispose);
        c.setVisible(true);
        await flush();
        expect(c.locating, isFalse);
        expect(c.fix, isNull);
        expect(c.message, isNotEmpty);
        expect(source.streams, isEmpty);
        c.setVisible(false);
        c.setVisible(true);
        await flush();
        expect(source.requests, [
          true,
          false,
        ], reason: 'Returning to Home never repeats the permission prompt.');
        source.permission = MapLocationAccess.granted;
        await c.locate();
        expect(source.requests.last, isTrue);
        expect(source.streams, hasLength(1));
        await c.suspend();
        await source.close();
      },
    );
  }

  test('hidden Home ignores a late permission reply and refreshes silently on return', () async {
    final source = TestMapLocation()..permissionReply = Completer();
    final c = HomeLocationController(source: source, now: () => now);
    addTearDown(() async {
      c.dispose();
      await source.close();
    });
    c.setVisible(true);
    await flush();
    await c.suspend();
    source.permissionReply!.complete(MapLocationAccess.granted);
    await flush();
    expect(source.streams, isEmpty);
    expect(c.fix, isNull);
    c.setVisible(true);
    await flush();
    expect(source.requests, [true, false]);
    source.streams.single.add(LocationFix(point, now, 5));
    await flush();
    expect(c.fix, isNotNull);
    await c.suspend();
    expect(c.fix, isNull);
  });

  testWidgets(
    '15-second acquisition timeout cancels and permits an explicit retry',
    (tester) async {
      final source = TestMapLocation();
      final c = HomeLocationController(source: source);
      addTearDown(() async {
        c.dispose();
        await source.close();
      });
      c.setVisible(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      expect(c.locating, isFalse);
      expect(source.cancelled, 1);
      expect(c.message, contains('No precise location'));
      await c.locate();
      expect(source.streams, hasLength(2));
      await c.suspend();
    },
  );

  for (final error in [true, false]) {
    test(
      'GPS ${error ? 'failure' : 'completion'} remains recoverable',
      () async {
        final source = TestMapLocation();
        final c = HomeLocationController(source: source);
        addTearDown(() async {
          c.dispose();
          await source.close();
        });
        c.setVisible(true);
        await flush();
        if (error) {
          source.streams.single.addError(StateError('synthetic'));
        } else {
          await source.streams.single.close();
        }
        await flush();
        expect(c.locating, isFalse);
        expect(c.message, isNotEmpty);
        expect(c.fix, isNull);
        await c.locate();
        expect(c.locating, isTrue);
      },
    );
  }

  test('an outside-PH fix never replaces the country view', () async {
    final source = TestMapLocation();
    final c = HomeLocationController(source: source, now: () => now);
    addTearDown(() async {
      c.dispose();
      await source.close();
    });
    c.setVisible(true);
    await flush();
    source.streams.single.add(LocationFix(const LatLng(51, 0), now, 5));
    await flush();
    expect(c.fix, isNull);
    expect(c.message, contains('outside this Philippines map'));
    expect(source.cancelled, 1);
  });

  test('navigation waits for Home GPS cancellation before preparing its own stream', () async {
    final source = TestMapLocation()..cancellationReply = Completer();
    final c = HomeLocationController(source: source);
    final location = navigation.Location(), routes = navigation.Routes();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => navigation.task(),
      vehicleType: () async => 'motorcycle',
      location: location,
      beforeStart: c.suspend,
    );
    addTearDown(() async {
      nav.dispose();
      c.dispose();
      routes.dispose();
      await source.close();
      await location.stream.close();
    });
    c.setVisible(true);
    await flush();
    final starting = nav.start(navigation.task());
    await flush();
    expect(source.cancelled, 1);
    expect(location.prepared, 0);
    expect(location.listened, 0);
    source.cancellationReply!.complete();
    await starting;
    expect(location.prepared, 1);
    expect(location.listened, 1);
    expect(nav.active, isTrue);
    expect(c.fix, isNull);
  });

  test(
    'disposed account scope rejects pending samples and clears its snapshot',
    () async {
      final source = TestMapLocation();
      final c = HomeLocationController(source: source, now: () => now);
      c.setVisible(true);
      await flush();
      c.dispose();
      source.streams.single.add(LocationFix(point, now, 5));
      await flush();
      expect(c.fix, isNull);
      expect(source.cancelled, 1);
      await source.close();
    },
  );

  test(
    'the real provider replaces in-memory locations on logout/account change',
    () async {
      final repository = TestAuthRepository()
        ..account = TestAuthRepository.approved;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await flush();
      final first = container.read(homeLocationProvider);
      first.fix = LocationFix(point, now, 5);
      await container.read(authControllerProvider.notifier).logout();
      final signedOut = container.read(homeLocationProvider);
      expect(signedOut, isNot(same(first)));
      expect(first.fix, isNull);
      expect(signedOut.fix, isNull);
      expect(signedOut.supported, isFalse);
      await container
          .read(authControllerProvider.notifier)
          .login('synthetic', 'synthetic');
      expect(container.read(homeLocationProvider), isNot(same(signedOut)));
      expect(container.read(homeLocationProvider).fix, isNull);
    },
  );

  test(
    'Linux has an explicit manual preview without invoking the location source',
    () async {
      final c = HomeLocationController(manual: true, now: () => now);
      addTearDown(c.dispose);
      c.setVisible(true);
      await c.locate();
      expect(c.supported, isFalse);
      expect(c.fix, isNull);
      c.setManualOrigin(point);
      expect(c.fix?.point, point);
      c.setManualOrigin(const LatLng(51, 0));
      expect(c.fix?.point, point);
      await c.suspend();
      expect(
        c.fix?.point,
        point,
        reason: 'Only the explicitly entered preview remains for this account.',
      );
    },
  );

  testWidgets(
    'Android foreground adapter requests no navigation notification or foreground-service settings',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final previous = GeolocatorPlatform.instance;
      final platform = _LocationPlatform();
      GeolocatorPlatform.instance = platform;
      addTearDown(() => GeolocatorPlatform.instance = previous);
      final source = AndroidForegroundMapLocation();
      expect(
        await source.access(requestPermission: true),
        MapLocationAccess.granted,
      );
      expect(platform.permissionRequests, 1);
      await source.fixes().drain<void>();
      final settings = platform.settings as AndroidSettings;
      expect(settings.foregroundNotificationConfig, isNull);
      expect(settings.accuracy, LocationAccuracy.high);
      platform.permission = LocationPermission.denied;
      expect(
        await source.access(requestPermission: false),
        MapLocationAccess.denied,
      );
      expect(platform.permissionRequests, 1);
      platform.services = false;
      expect(
        await source.access(requestPermission: true),
        MapLocationAccess.servicesOff,
      );
      expect(platform.permissionRequests, 1);
    },
  );
}

class _LocationPlatform extends GeolocatorPlatform {
  bool services = true;
  int permissionRequests = 0;
  LocationPermission permission = LocationPermission.denied;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => services;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission = LocationPermission.whileInUse;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings = locationSettings;
    return const Stream.empty();
  }
}
