import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/company/presentation/company_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/company_support.dart';

void main() {
  test(
    'company reads cannot restore private data after background or owner loss',
    () async {
      final s = companySetup();
      final c = RiderCompanyController(s.repository);
      addTearDown(c.dispose);
      final gate = Completer<void>();
      s.api.delay = gate;
      final read = c.refresh();
      await Future<void>.delayed(Duration.zero);
      c.setActive(false);
      gate.complete();
      await read;
      expect(c.assignment, isNull);
      expect(c.companies, isNull);
      expect(c.canAct, isFalse);
      c.setActive(true);
      await c.refresh();
      expect(c.assignment, isNotNull);
      expect(c.canAct, isTrue);
    },
  );
  test('unknown company command blocks a new decision until explicit original retry', () async {
    final s = companySetup();
    final controller = RiderCompanyController(s.repository);
    addTearDown(controller.dispose);
    await controller.refresh();
    s.api.loseBeforeCommit = true;
    expect(
      await controller.submit(
        controller.companies!.items.single,
        acknowledged: true,
      ),
      isFalse,
    );
    expect(controller.pendingIntent, isNotNull);
    expect(controller.canAct, isFalse);
    await controller.refresh();
    expect(controller.unknownRequest, isTrue);
    await controller.recover(retryUnknown: true);
    expect(controller.pendingIntent, isNull);
    expect(controller.applications!.items.single.effectiveStatus, 'pending');
    expect(s.api.membership['on_duty'], isFalse);
  });
  test('a failed refresh leaves previous read-only data with new decisions disabled', () async {
    final s = companySetup();
    final controller = RiderCompanyController(s.repository);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.canAct, isTrue);
    s.api.failure = const AccountFailure(
      'Service is unavailable.',
      status: 503,
    );
    await controller.refresh();
    expect(controller.assignment, isNotNull);
    expect(controller.readVerified, isFalse);
    expect(controller.canAct, isFalse);
  });
  test('service cooldown prevents company reads and decisions without another request', () async {
    final s = companySetup();
    final c = RiderCompanyController(s.repository);
    addTearDown(c.dispose);
    s.api.failure = const AccountFailure(
      'Wait before trying again.',
      status: 429,
      retryAfterSeconds: 30,
    );
    await c.refresh();
    final count = s.api.calls.length;
    expect(c.coolingDown, isTrue);
    await c.refresh();
    expect(s.api.calls, hasLength(count));
    expect(c.canAct, isFalse);
  });
}
