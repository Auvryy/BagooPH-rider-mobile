import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/task_payment_instruction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

void main() {
  testWidgets(
    'current instructions distinguish exact COD, paid wallet and missing payment evidence',
    (tester) async {
      final h = ParcelHarness(action: ParcelAction.deliver);
      Future<void> show() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskPaymentInstruction(task: h.task)),
        ),
      );
      h.taskJson['payment']['cod_due_cents'] = '900719925474099301';
      await show();
      expect(
        find.text('COD to collect: ₱9,007,199,254,740,993.01'),
        findsOneWidget,
      );
      h.taskJson['payment'] = {
        'method': 'wallet',
        'commercial_payment_status': 'paid',
        'cod_due_cents': null,
      };
      h.taskJson['stop']['kind'] = 'buyer';
      await show();
      expect(
        find.text('Paid — no cash to collect · Bagoo Wallet'),
        findsOneWidget,
      );
      for (final payment in [
        null,
        {
          'method': 'wallet',
          'commercial_payment_status': 'unpaid',
          'cod_due_cents': null,
        },
        {
          'method': 'card',
          'commercial_payment_status': 'paid',
          'cod_due_cents': null,
        },
      ]) {
        h.taskJson['payment'] = payment;
        await show();
        expect(
          find.textContaining('Payment instructions unavailable.'),
          findsOneWidget,
        );
        expect(find.textContaining('Paid — no cash'), findsNothing);
      }
    },
  );

  testWidgets('owned pickup does not expose final-mile payment instructions', (
    tester,
  ) async {
    final h = ParcelHarness(action: ParcelAction.pickup);
    await tester.pumpWidget(
      MaterialApp(home: TaskPaymentInstruction(task: h.task)),
    );
    expect(
      find.byKey(const ValueKey('task-payment-instruction')),
      findsNothing,
    );
  });
}
