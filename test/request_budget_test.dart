import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/request_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native first-party transport shares a rolling request and write budget',
    () {
      var now = DateTime.utc(2026, 10, 9);
      final budget = NativeRequestBudget(now: () => now);
      for (var i = 0; i < 10; i++) {
        budget.reserve('POST');
      }
      expect(
        () => budget.reserve('PATCH'),
        throwsA(
          isA<AccountFailure>().having(
            (e) => e.retryAfterSeconds,
            'cooldown',
            60,
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        budget.reserve('GET');
      }
      expect(
        () => budget.reserve('GET'),
        throwsA(isA<AccountFailure>().having((e) => e.status, 'status', 429)),
      );
      now = now.add(const Duration(minutes: 1));
      budget.reserve('GET');
      budget.reserve('POST');
    },
  );
}
