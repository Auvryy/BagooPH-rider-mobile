import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/cash/data/cash_models.dart';
import 'package:bagoo_rider_mobile/features/cash/presentation/financial_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'shift and earned amounts remain separate at 320px/$scale text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        final earnings = RiderEarnings.fromJson({
          'available': true,
          'confirmed_cents': '2500',
          'pending_cents': '1000',
          'basis': 'original_delivery_earnings_ledger',
        });
        final shift = RiderShiftSummary.fromJson({
          'shift_id': 8,
          'started_at': '2026-10-29T01:00:00.000Z',
          'collected_cents': '12500',
          'remitted_cents': '0',
          'held_cents': '12500',
          'pending_handovers': 1,
          'unresolved_differences': 0,
          'can_close': false,
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      RiderEarningsSummary(earnings: earnings),
                      RiderShiftSummaryPanel(
                        shift: shift,
                        onCash: () => opened++,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Released earnings'), findsOneWidget);
        expect(find.text(cashPeso(BigInt.from(2500))), findsOneWidget);
        expect(find.text(cashPeso(BigInt.from(12500))), findsNWidgets(2));
        expect(
          find.text('Your hub still needs to confirm the cash handover.'),
          findsOneWidget,
        );
        final button = find.text('Review cash handovers');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        expect(opened, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unavailable earnings do not display a fabricated zero balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: Scaffold(
          body: RiderEarningsSummary(
            earnings: RiderEarnings.fromJson({
              'available': false,
              'confirmed_cents': null,
            }),
          ),
        ),
      ),
    );
    expect(find.text('Earnings unavailable'), findsOneWidget);
    expect(find.text(cashPeso(BigInt.zero)), findsNothing);
  });
}
