import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/trips/presentation/trip_detail_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/trip_support.dart';

void main() {
  testWidgets('a debounced search makes no request after backgrounding', (
    tester,
  ) async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await tester.runAsync(h.boot);
    final before = h.api.calls
        .where((call) => call.path.startsWith('rider/trips?'))
        .length;
    h.work.searchTrips('BGO-CHANGED');
    h.work.setForeground(false);
    await tester.pump(const Duration(seconds: 1));
    expect(
      h.api.calls.where((call) => call.path.startsWith('rider/trips?')).length,
      before,
    );
    h.dispose();
  });
  test('server-filtered pages append without duplicate assignments and reset on new filters', () async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/trips?')) {
        final q = Uri.parse(path).queryParameters;
        if (q['phase'] == 'pickup') {
          return retainedTripEnvelope([
            retainedTripJson(id: '61', phase: 'pickup'),
          ]);
        }
        final page = int.parse(q['page']!);
        return retainedTripEnvelope(
          page == 1
              ? [retainedTripJson()]
              : [retainedTripJson(), retainedTripJson(id: '61')],
          page: page,
          total: 21,
          lastPage: 2,
        );
      }
      return h.domain.standardResponse(path, method, body, headers);
    };
    await h.work.refreshTrips();
    expect(h.work.hasNextTripPage, isTrue);
    h.work.nextTripPage();
    await Future<void>.delayed(Duration.zero);
    expect(h.work.visibleTrips.map((t) => t.id), ['trip-41', 'trip-61']);
    expect(h.work.hasNextTripPage, isFalse);
    h.work.filterTripPhase('pickup');
    await Future<void>.delayed(Duration.zero);
    expect(h.work.visibleTrips.single.operation!.phase, 'pickup');
    expect(h.work.tripPage, 0);
  });
  test('a late old search or page cannot overwrite the new query', () async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await h.boot();
    final old = Completer<Map<String, dynamic>>();
    h.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/trips?')) {
        return Uri.parse(path).queryParameters['payment'] == 'cod'
            ? retainedTripEnvelope([retainedTripJson(id: '61')])
            : old.future;
      }
      return h.domain.standardResponse(path, method, body, headers);
    };
    final first = h.work.refreshTrips();
    h.work.filterPayment(PaymentFilter.cod);
    await Future<void>.delayed(Duration.zero);
    old.complete(retainedTripEnvelope([retainedTripJson()]));
    await first;
    expect(h.work.visibleTrips.single.id, 'trip-61');
  });
  test(
    'soft list failure retains stale rows and capability loss clears them',
    () async {
      final h = TripHarness();
      addTearDown(h.dispose);
      await h.boot();
      expect(h.work.visibleTrips.single.id, 'trip-41');
      h.api.respond = (path, method, body, headers) async {
        if (path.startsWith('rider/trips?')) {
          throw const AccountFailure(
            'History temporarily offline',
            status: 503,
          );
        }
        final result = await h.domain.standardResponse(
          path,
          method,
          body,
          headers,
        );
        if (path == 'rider/home') {
          result['data']['capabilities']['trips'] = false;
        }
        return result;
      };
      await h.work.refreshTrips();
      expect(h.work.tripData.status, FeatureStatus.failed);
      expect(h.work.visibleTrips.single.id, 'trip-41');
      await h.work.refreshHome();
      await h.work.refreshTrips();
      expect(h.work.tripData.status, FeatureStatus.unavailable);
      expect(h.work.visibleTrips, isEmpty);
      expect(h.work.retainedTrips, isNull);
    },
  );
  test('private proof is authorized afresh and cannot substitute a different assignment or child', () async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await h.boot();
    await expectLater(
      h.repository.tripProof(
        'trip-41',
        'rider/trips/trip-99/checkpoints/42/proof',
      ),
      throwsA(isA<AccountFailure>()),
    );
    await expectLater(
      h.repository.tripProof(
        'trip-41',
        'rider/trips/trip-41/checkpoints/43/proof',
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.downloads, isEmpty);
    final result = await h.repository.tripProof(
      'trip-41',
      'rider/trips/trip-41/checkpoints/42/proof',
    );
    expect(result.bytes, h.png);
    final before = h.api.calls.length;
    h.rows.first['checkpoints'][1]['proof_url'] = null;
    await expectLater(
      h.repository.tripProof(
        'trip-41',
        'rider/trips/trip-41/checkpoints/42/proof',
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.calls.length, before + 1);
    expect(h.api.downloads.length, 1);
  });
  test('changed or invalid private bytes never reach the viewer', () async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await h.boot();
    h.api.onProof = (_) async => PrivateApiBytes(h.png, 'application/pdf');
    await expectLater(
      h.repository.tripProof(
        'trip-41',
        'rider/trips/trip-41/checkpoints/42/proof',
      ),
      throwsA(isA<AccountFailure>()),
    );
    h.api.onProof = (_) async => throw const AccountFailure(
      'Retained evidence changed',
      status: 409,
      code: 'EVIDENCE_CHANGED',
    );
    final c = TripDetailController(work: h.work, id: 'trip-41');
    addTearDown(c.dispose);
    await c.refresh();
    await c.loadProof('rider/trips/trip-41/checkpoints/42/proof');
    expect(c.proof.status, FeatureStatus.failed);
    expect(c.proof.data, isNull);
  });
  test('background invalidates pending proof and resume refreshes without reopening it', () async {
    final h = TripHarness();
    addTearDown(h.dispose);
    await h.boot();
    final c = TripDetailController(work: h.work, id: 'trip-41');
    addTearDown(c.dispose);
    await c.refresh();
    final bytes = Completer<PrivateApiBytes>();
    h.api.onProof = (_) => bytes.future;
    final request = c.loadProof('rider/trips/trip-41/checkpoints/42/proof');
    await Future<void>.delayed(Duration.zero);
    c.setForeground(false);
    bytes.complete(PrivateApiBytes(h.png, 'image/png'));
    await request;
    expect(c.detail.data, isNull);
    expect(c.proof.data, isNull);
    expect(c.proofPath, isNull);
    c.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(c.detail.data!.id, 'trip-41');
    expect(c.proof.data, isNull);
    expect(h.api.downloads.length, 1);
  });
  test(
    'explicit denial clears detail and proof before session cleanup',
    () async {
      final h = TripHarness();
      addTearDown(h.dispose);
      await h.boot();
      final c = TripDetailController(work: h.work, id: 'trip-41');
      addTearDown(c.dispose);
      await c.refresh();
      await c.loadProof('rider/trips/trip-41/checkpoints/42/proof');
      expect(c.proof.data, isNotNull);
      h.api.onProof = (_) async =>
          throw const AccountFailure('Access removed', status: 403);
      await c.loadProof('rider/trips/trip-41/checkpoints/42/proof');
      expect(c.proof.data, isNull);
      expect(c.detail.data, isNull);
      expect(h.work.tripData.data, isNull);
      expect(h.work.canReadTrips, isFalse);
    },
  );
  test(
    'account change or disposal rejects a late original-assignment result',
    () async {
      final h = TripHarness();
      addTearDown(h.dispose);
      await h.boot();
      final response = Completer<Map<String, dynamic>>();
      h.api.respond = (path, method, body, headers) => response.future;
      final c = TripDetailController(work: h.work, id: 'trip-41');
      final request = c.refresh();
      h.domain.current = false;
      c.dispose();
      response.complete({'data': h.rows.first});
      await request;
      expect(c.detail.data, isNull);
      expect(c.proof.data, isNull);
    },
  );
}
