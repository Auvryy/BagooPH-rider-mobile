import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/wire.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/trips/data/trip_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/trip_support.dart';

void main() {
  test('retained assignment preserves exact identifiers money original facts and Manila dates', () {
    final trip = RetainedTrip.fromJson(
      retainedTripJson(
        id: '9223372036854775807',
        delivery: '9007199254740993',
        cents: '9007199254740993123',
      ),
    );
    expect(trip.id, 'trip-9223372036854775807');
    expect(trip.taskId, 'final_mile-9007199254740993');
    expect(trip.collectedCents, BigInt.parse('9007199254740993123'));
    expect(dayLabel(trip.assignedAt), 'Oct 18, 2026');
    expect(trip.proofPaths, {
      'rider/trips/trip-9223372036854775807/checkpoints/42/proof',
    });
  });
  test('null original handoff facts and an unknown outcome are never replaced by current recipient data', () {
    final trip = RetainedTrip.fromJson(
      retainedTripJson(
        phase: 'pickup',
        recipient: null,
        address: null,
        cents: null,
        outcome: null,
      ),
    );
    expect(trip.recipient, isNull);
    expect(trip.address, isNull);
    expect(trip.collectedCents, isNull);
    final display = OperationsRepository.asRiderTrip(trip);
    expect(display.recipient, 'Recipient not recorded');
    expect(display.operation, same(trip));
    expect(display.cashCentavos, isNull);
    expect(display.outcome, 'No outcome recorded');
    expect(tripOutcomeLabel('new_server_state'), 'Unrecognized recorded state');
  });
  test('reject noncanonical IDs amounts phases times and foreign or misbound proof paths', () {
    for (final id in ['01', '0', '9223372036854775808', '41\n', '٤١']) {
      expect(
        () => RetainedTrip.fromJson(retainedTripJson(id: id)),
        throwsFormatException,
      );
    }
    for (final amount in ['-1', '1.00', '01', '1e3', '10\n']) {
      expect(
        () => RetainedTrip.fromJson(retainedTripJson(cents: amount)),
        throwsFormatException,
      );
    }
    for (final path in [
      'https://foreign.test/file',
      '/storage/proof.png',
      '/api/v1/rider/trips/trip-99/checkpoints/42/proof',
      '/api/v1/rider/trips/trip-41/checkpoints/43/proof',
      '/api/v1/rider/trips/trip-41/checkpoints/42/proof?token=x',
    ]) {
      final json = retainedTripJson();
      json['checkpoints'][1]['proof_url'] = path;
      expect(() => RetainedTrip.fromJson(json), throwsFormatException);
    }
    final mismatched = retainedTripJson()..['task_id'] = 'pickup-7';
    expect(() => RetainedTrip.fromJson(mismatched), throwsFormatException);
    final offset = retainedTripJson()
      ..['assignment_recorded_at'] = '2026-10-18T00:00:00+08:00';
    expect(() => RetainedTrip.fromJson(offset), throwsFormatException);
  });
  test(
    'command and task wire values reject otherwise matching trailing newlines',
    () {
      expect(() => Wire.taskId('pickup-7\n'), throwsFormatException);
      expect(() => Wire.id('7\n'), throwsFormatException);
      expect(() => Wire.version('${'a' * 64}\n'), throwsFormatException);
      expect(
        () => Wire.uuid('00000000-0000-4000-8000-000000000001\n'),
        throwsFormatException,
      );
    },
  );
  test('assignment-date query encodes literal search and supports one-sided inclusive dates', () {
    final filter = TripFilters(
      search: ' ORDER %_ / & ',
      phase: 'pickup',
      payment: 'prepaid',
      from: DateTime(2026, 10, 18),
    );
    final query = Uri(path: 'rider/trips', queryParameters: filter.query(2));
    expect(query.queryParameters, {
      'page': '2',
      'per_page': '20',
      'q': 'ORDER %_ / &',
      'phase': 'pickup',
      'payment': 'prepaid',
      'from_date': '2026-10-18',
    });
    expect(
      TripFilters(to: DateTime(2026, 10, 18)).query(1)['to_date'],
      '2026-10-18',
    );
    expect(
      () =>
          TripFilters(from: DateTime(2026, 10, 19), to: DateTime(2026, 10, 18)),
      throwsA(isA<AccountFailure>()),
    );
    expect(
      () => TripFilters(search: 'x' * 101),
      throwsA(isA<AccountFailure>()),
    );
    expect(() => TripFilters(search: 'x\ny'), throwsA(isA<AccountFailure>()));
  });
  test('page validates retained attribution and deduplicates stable original assignment IDs', () {
    final json =
        retainedTripEnvelope([retainedTripJson(), retainedTripJson()])['data']
            as Map<String, dynamic>;
    final page = RetainedTripPage.fromJson(json);
    expect(page.items.length, 1);
    expect(page.total, 2);
    expect(page.hasNext, isFalse);
    expect(
      () =>
          RetainedTripPage.fromJson({...json, 'attribution': 'current_rider'}),
      throwsFormatException,
    );
    expect(
      () => RetainedTripPage.fromJson({...json, 'date_basis': 'delivered_at'}),
      throwsFormatException,
    );
    expect(
      () => RetainedTripPage.fromJson({
        ...json,
        'pagination': {'page': '1', 'per_page': 20, 'total': 2, 'last_page': 1},
      }),
      throwsFormatException,
    );
  });
}
