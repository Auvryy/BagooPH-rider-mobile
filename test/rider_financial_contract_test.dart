import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/features/cash/data/cash_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/trips/data/trip_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cash_support.dart';
import 'support/trip_support.dart';

Map<String, dynamic> earnings({
  String confirmed = '0',
  String pending = '2500',
}) => {
  'available': true,
  'confirmed_cents': confirmed,
  'pending_cents': pending,
  'basis': 'original_delivery_earnings_ledger',
};
Map<String, dynamic> shift({bool clear = false}) => {
  'shift_id': 8,
  'started_at': '2026-10-29T01:00:00.000Z',
  'collected_cents': '12500',
  'remitted_cents': clear ? '12500' : '0',
  'held_cents': clear ? '0' : '12500',
  'pending_handovers': clear ? 0 : 1,
  'unresolved_differences': 0,
  'can_close': clear,
  'accounts': [],
};

void main() {
  test('current earned-ledger cash and retained trips accept zero and large exact amounts', () {
    for (final cents in ['0', '2500', '9007199254740993123']) {
      final account = CashAccount.fromJson(
        cashFixture()..['earnings'] = earnings(confirmed: cents),
      );
      expect(account.earnings.confirmed, BigInt.parse(cents));
      expect(account.held, BigInt.from(12500));
      final trip = RetainedTrip.fromJson(
        retainedTripJson()..['earnings'] = earnings(confirmed: cents),
      );
      expect(trip.earnings.confirmed, BigInt.parse(cents));
      expect(trip.collectedCents, BigInt.from(12500));
    }
  });

  test('an empty current cash response preserves earnings and the separate shift ledger', () {
    final page = CashPage.fromJson({
      'items': [],
      'summary': {
        'basis': 'all_owned_cash_journals',
        'own_held_cents': '0',
        'accounts_with_unresolved_difference': 0,
      },
      'earnings': earnings(),
      'shift': shift(),
      'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'last_page': 1},
    });
    expect(page.items, isEmpty);
    expect(page.earnings.confirmed, BigInt.zero);
    expect(page.earnings.pending, BigInt.from(2500));
    expect(page.shift!.id, '8');
    expect(page.shift!.held, BigInt.from(12500));
    expect(page.shift!.canClose, isFalse);
  });

  test('Home retains server shift closure evidence and older optional absence remains compatible', () {
    final fixture = jsonDecode(
      File('test/fixtures/operations/home.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final json = Map<String, dynamic>.from(fixture['data'] as Map);
    expect(OperationsHome.fromJson(json).shift, isNull);
    json['shift'] = shift(clear: true);
    final home = OperationsHome.fromJson(json);
    expect(home.shift!.canClose, isTrue);
    expect(home.shift!.remitted, BigInt.from(12500));
  });

  test(
    'absent historical earnings remain unavailable, never an invented zero',
    () {
      final value = RiderEarnings.fromJson({
        'available': false,
        'confirmed_cents': null,
      });
      expect(value.available, isFalse);
      expect(value.confirmed, isNull);
      expect(value.pending, isNull);
    },
  );

  test(
    'malformed or invented earning sources do not become displayed balances',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['confirmed_cents'] = '-1',
        (j) => j['confirmed_cents'] = 1,
        (j) => j['confirmed_cents'] = '1.00',
        (j) => j['pending_cents'] = '01',
        (j) => j['basis'] = 'collected_cod',
        (j) => j.remove('pending_cents'),
        (j) => j['available'] = false,
      ]) {
        final json = earnings();
        mutate(json);
        expect(() => RiderEarnings.fromJson(json), throwsFormatException);
      }
      final invalid = shift()..['can_close'] = true;
      expect(() => RiderShiftSummary.fromJson(invalid), throwsFormatException);
    },
  );
}
