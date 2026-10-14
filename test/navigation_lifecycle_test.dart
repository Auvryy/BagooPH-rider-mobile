import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/navigation_location.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'navigation_test.dart' as support;

class RenewableLocation implements NavigationLocation {
  int prepared = 0, listened = 0, cancelled = 0;
  bool allowed = true;
  Future<void>? cancellation;
  final streams = <StreamController<LocationFix>>[];
  @override
  Future<void> prepare() async {
    prepared++;
  }

  @override
  Future<bool> permitted() async => allowed;
  @override
  Stream<LocationFix> fixes() {
    listened++;
    final wait = cancellation;
    final stream = StreamController<LocationFix>(
      onCancel: () async {
        cancelled++;
        await wait;
      },
    );
    streams.add(stream);
    return stream.stream;
  }

  Future<void> close() async {
    for (final stream in streams) {
      await stream.close();
    }
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  for (final failure in [false, true]) {
    test(
      'location ${failure ? 'error' : 'completion'} ends navigation once and revalidation never restarts GPS',
      () async {
        final routes = support.Routes(), location = RenewableLocation();
        final nav = NavigationController(
          routes: routes,
          authorize: (_) async => support.task(),
          vehicleType: () async => 'motorcycle',
          location: location,
        );
        addTearDown(() async {
          nav.dispose();
          routes.dispose();
          await location.close();
        });
        await nav.start(support.task());
        final now = DateTime.now();
        location.streams.single.add(LocationFix(const LatLng(14, 121), now, 5));
        await settle();
        expect(nav.road, isNotNull);
        if (failure) {
          location.streams.single.addError(
            StateError('Synthetic location failure'),
          );
        } else {
          await location.streams.single.close();
        }
        await settle();
        expect(nav.active, isFalse);
        expect(nav.paused, isTrue);
        expect(nav.pausedTaskId, 'final_mile-1');
        expect(nav.task, isNull);
        expect(nav.fix, isNull);
        expect(nav.road, isNull);
        expect(location.cancelled, 1);
        final count = routes.calls.length;
        expect((await nav.revalidatePausedTask())?.id, 'final_mile-1');
        expect(nav.active, isFalse);
        expect(location.prepared, 1);
        expect(location.listened, 1);
        expect(routes.calls.length, count);
        await nav.start(support.task());
        expect(location.prepared, 2);
        expect(location.listened, 2);
        expect(nav.active, isTrue);
        expect(nav.pausedTaskId, isNull);
      },
    );
  }

  test(
    'an ended stream cancels its pending route and rejects late geometry',
    () async {
      final routes = support.Routes(), location = RenewableLocation();
      final reply = Completer<RoadRoute>();
      routes.response = () => reply.future;
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async => support.task(),
        vehicleType: () async => 'motorcycle',
        location: location,
      );
      addTearDown(() async {
        nav.dispose();
        routes.dispose();
        await location.close();
      });
      await nav.start(support.task());
      final route = nav.updateFix(
        LocationFix(const LatLng(14, 121), DateTime.now(), 5),
      );
      await settle();
      final cancel = routes.calls.single.cancel;
      await location.streams.single.close();
      expect(cancel.isCancelled, isTrue);
      reply.complete(RoadRoute.geoJson(support.geometry));
      await route;
      expect(nav.road, isNull);
      expect(nav.active, isFalse);
    },
  );

  test('a slow old cancellation cannot start an older target after a newer Navigate', () async {
    final routes = support.Routes(), location = RenewableLocation();
    final cancellation = Completer<void>();
    location.cancellation = cancellation.future;
    var current = support.task();
    final nav = NavigationController(
      routes: routes,
      authorize: (_) async => current,
      vehicleType: () async => 'motorcycle',
      location: location,
    );
    addTearDown(() async {
      if (!cancellation.isCompleted) cancellation.complete();
      nav.dispose();
      routes.dispose();
      await location.close();
    });
    await nav.start(current);
    final old = nav.start(support.task(id: '2'));
    location.cancellation = null;
    current = support.task(id: '3');
    await nav.start(current);
    cancellation.complete();
    await old;
    expect(nav.task?.id, 'final_mile-3');
    expect(location.prepared, 2);
    expect(location.listened, 2);
  });

  test(
    'Sedan / Van selects driving and registered vehicle takes precedence',
    () async {
      final routes = support.Routes();
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async => support.task(),
        vehicleType: () async => ' Sedan / Van ',
        manual: true,
      );
      addTearDown(() {
        nav.dispose();
        routes.dispose();
      });
      await nav.start(
        support.task(),
        chosenProfile: NavigationProfile.scooter,
        manualOrigin: const LatLng(14, 121),
      );
      expect(routes.calls.single.profile, NavigationProfile.drive);
      expect(NavigationProfile.forVehicle('cargo bicycle'), isNull);
      expect(NavigationProfile.forVehicle(null), isNull);
    },
  );

  test(
    'denied paused revalidation clears the target and never starts location',
    () async {
      final routes = support.Routes(), location = RenewableLocation();
      bool denied = false;
      final nav = NavigationController(
        routes: routes,
        authorize: (_) async {
          if (denied) throw const AccountFailure('Task hidden', status: 404);
          return support.task();
        },
        vehicleType: () async => 'motorcycle',
        location: location,
      );
      addTearDown(() async {
        nav.dispose();
        routes.dispose();
        await location.close();
      });
      await nav.start(support.task());
      await nav.stop(pause: true, reason: 'Revalidate task');
      denied = true;
      expect(await nav.revalidatePausedTask(), isNull);
      expect(nav.pausedTaskId, isNull);
      expect(nav.paused, isFalse);
      expect(location.listened, 1);
    },
  );

  test('late paused revalidation cannot restore a dismissed target', () async {
    final routes = support.Routes();
    Completer<OperationTask>? reply;
    final nav = NavigationController(
      routes: routes,
      authorize: (_) => reply?.future ?? Future.value(support.task()),
      vehicleType: () async => 'motorcycle',
      manual: true,
    );
    addTearDown(() {
      nav.dispose();
      routes.dispose();
    });
    await nav.start(support.task(), manualOrigin: const LatLng(14, 121));
    await nav.stop(pause: true);
    reply = Completer<OperationTask>();
    final check = nav.revalidatePausedTask();
    await nav.stop();
    reply.complete(support.task());
    expect(await check, isNull);
    expect(nav.pausedTaskId, isNull);
    expect(nav.message, isNull);
    expect(nav.active, isFalse);
  });
}
