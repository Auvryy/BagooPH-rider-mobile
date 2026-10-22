import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/cash/presentation/cash_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cash_support.dart';

import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';

Future<void> ready(CashController c) async {
  c.setVisible(true);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('inactive and background cash views clear financial facts and ignore late reads', () async {
    final h = CashHarness(), c = CashController(CashHarness().repository);
    c.dispose();
    final controller = CashController(h.repository);
    addTearDown(controller.dispose);
    await ready(controller);
    expect(controller.page, isNotNull);
    await controller.select(h.account.id);
    expect(controller.detail, isNotNull);
    final wait = Completer<void>();
    h.api.respond = (p, m, b, headers) async {
      if (p.startsWith('rider/cash?')) await wait.future;
      return h.respond(p, m, b, headers);
    };
    final refresh = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    controller.setForeground(false);
    expect(controller.page, isNull);
    expect(controller.detail, isNull);
    wait.complete();
    await refresh;
    expect(controller.page, isNull);
    expect(controller.canOffer, false);
    controller.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.page, isNotNull);
    controller.setVisible(false);
    expect(controller.page, isNull);
    expect(controller.detail, isNull);
  });
  test('Home capability loss and explicit denial clear held values', () async {
    final h = CashHarness();
    final controller = CashController(h.repository);
    addTearDown(controller.dispose);
    await ready(controller);
    h.capable = false;
    await controller.refresh();
    expect(controller.page, isNull);
    expect(controller.available, false);
    h.capable = true;
    await controller.refresh();
    expect(controller.page, isNotNull);
    h.api.respond = (p, m, b, headers) async {
      if (p.startsWith('rider/cash?')) {
        throw const AccountFailure('Forbidden', status: 403);
      }
      return h.respond(p, m, b, headers);
    };
    await controller.refresh();
    expect(controller.page, isNull);
    expect(controller.canOffer, false);
  });
  test(
    'account change ends session and prevents late data from becoming visible',
    () async {
      final h = CashHarness();
      var ended = false;
      final c = CashController(
        h.repository,
        onSessionEnd: (_) async {
          ended = true;
        },
      );
      addTearDown(c.dispose);
      await ready(c);
      h.current = false;
      await c.refresh();
      expect(ended, true);
      expect(c.page, isNull);
      expect(c.active, false);
    },
  );
  test('unknown offer remains exclusive and recovery checks preserve original request', () async {
    final h = CashHarness();
    final controller = CashController(h.repository);
    addTearDown(controller.dispose);
    await ready(controller);
    await controller.select(h.account.id);
    expect(controller.canOffer, true);
    h.api.respond = (p, m, b, headers) async {
      if (m == 'POST') {
        throw const AccountFailure('Uncertain', unconfirmed: true);
      }
      return h.respond(p, m, b, headers);
    };
    expect(
      await controller.offer(
        recipientId: '12',
        amount: '125.00',
        evidenceReference: 'TEST-01',
      ),
      false,
    );
    expect(controller.pending?.isCash, true);
    expect(controller.canOffer, false);
    final key = controller.pending!.key;
    await controller.recover();
    expect(controller.pending!.key, key);
    expect(h.api.calls.where((r) => r.method == 'POST').length, 1);
  });
  test(
    'field validation keeps reviewed form and inline server errors',
    () async {
      final h = CashHarness();
      final controller = CashController(h.repository);
      addTearDown(controller.dispose);
      await ready(controller);
      await controller.select(h.account.id);
      h.api.respond = (p, m, b, headers) async {
        if (m == 'POST') {
          throw const AccountFailure(
            'Check reference',
            status: 422,
            fields: {'evidence_reference': 'Use actual handover reference.'},
          );
        }
        return h.respond(p, m, b, headers);
      };
      await controller.offer(
        recipientId: '12',
        amount: '125.00',
        evidenceReference: 'TEST-01',
      );
      expect(controller.detail, isNotNull);
      expect(
        controller.failure!.fields['evidence_reference'],
        'Use actual handover reference.',
      );
      expect(controller.pending, isNull);
    },
  );
  test('old committed cash offer reports current received journal without requesting another receipt', () async {
    final h = CashHarness();
    h.api.respond = (p, m, b, headers) async {
      if (m == 'POST') {
        h.committed = h.result(h.journal.value!);
        throw const AccountFailure('Lost', unconfirmed: true);
      }
      return h.respond(p, m, b, headers);
    };
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    h.json['can_offer'] = false;
    h.json['own_held_cents'] = '0';
    h.json['own_remitted_cents'] = '12500';
    h.json['version'] = '3';
    final c = CashController(h.repository);
    addTearDown(c.dispose);
    c.selectedId = h.account.id;
    await ready(c);
    expect(c.pending, isNull);
    expect(c.detail!.held, BigInt.zero);
    expect(c.detail!.remitted, BigInt.from(12500));
    expect(
      c.notice,
      'Original cash offer recorded. Current receipt status is shown below.',
    );
    expect(c.notice!.contains('Await'), false);
  });
  test(
    'ordinary committed intent is described as work, never as a cash offer',
    () async {
      final h = CashHarness();
      final saved = CommandIntent(
        accountId: '5',
        key: commandUuid(),
        action: 'duty',
        resource: 'rider',
        body: {'on_duty': false},
        createdAt: DateTime.utc(2026, 10, 22),
      );
      h.journal.value = saved;
      h.api.respond = (p, m, b, headers) async {
        if (p.startsWith('rider/commands/')) {
          final result = h.result(saved);
          result['action'] = 'duty';
          result['resource'] = 'rider';
          result['result'] = {'on_duty': false};
          return {'data': result};
        }
        return h.respond(p, m, b, headers);
      };
      final c = CashController(h.repository);
      addTearDown(c.dispose);
      await ready(c);
      expect(c.notice, 'Original work request confirmed.');
      expect(c.pending, isNull);
    },
  );
  test('successful next page replaces displayed rows and preserves authoritative all-owned summary; transient failure retains prior page', () async {
    final h = CashHarness();
    var fail = false;
    h.api.respond = (p, m, b, headers) async {
      if (p.startsWith('rider/cash?')) {
        final page = int.parse(Uri.parse(p).queryParameters['page']!);
        if (fail && page == 3) {
          throw const AccountFailure('Temporary service failure', status: 503);
        }
        final rows = List.generate(
          page == 3 ? 1 : 20,
          (i) => cashFixture(id: '${page * 100 + i}', detail: false),
        );
        return {'data': cashPageFixture(items: rows, page: page, total: 41)};
      }
      return h.respond(p, m, b, headers);
    };
    final c = CashController(h.repository);
    addTearDown(c.dispose);
    await ready(c);
    expect(c.page!.page, 1);
    final summary = c.page!.held;
    await c.more();
    expect(c.page!.page, 2);
    expect(c.page!.items.length, 20);
    expect(c.page!.items.first.id, '200');
    expect(c.page!.held, summary);
    fail = true;
    await c.more();
    expect(c.page!.page, 2);
    expect(c.page!.items.first.id, '200');
    expect(c.page!.held, summary);
    expect(c.failure!.status, 503);
    fail = false;
    await c.more();
    expect(c.page!.page, 3);
    expect(c.page!.hasMore, false);
    expect(c.page!.items.single.id, '300');
    expect(c.page!.held, summary);
  });
  test('late next page is ignored after closing surface and cannot cross an account change', () async {
    for (final accountLoss in [false, true]) {
      final h = CashHarness();
      final wait = Completer<void>();
      h.api.respond = (p, m, b, headers) async {
        if (p.startsWith('rider/cash?')) {
          final page = int.parse(Uri.parse(p).queryParameters['page']!);
          if (page == 2) await wait.future;
          return {
            'data': cashPageFixture(
              items: List.generate(
                page == 1 ? 20 : 1,
                (i) => cashFixture(id: '${page * 100 + i}', detail: false),
              ),
              page: page,
              total: 21,
            ),
          };
        }
        return h.respond(p, m, b, headers);
      };
      final c = CashController(h.repository);
      await ready(c);
      final next = c.more();
      await Future<void>.delayed(Duration.zero);
      if (accountLoss) {
        h.current = false;
        c.revoke('Account changed.');
      } else {
        c.setVisible(false);
      }
      expect(c.page, isNull);
      wait.complete();
      await next;
      expect(c.page, isNull);
      expect(c.canOffer, false);
      c.dispose();
    }
  });
  test('service cooldown blocks new cash reads and offers', () async {
    final h = CashHarness();
    final controller = CashController(h.repository);
    addTearDown(controller.dispose);
    await ready(controller);
    h.api.respond = (p, m, b, headers) async {
      if (p.startsWith('rider/cash?')) {
        throw const AccountFailure('Wait', status: 429, retryAfterSeconds: 30);
      }
      return h.respond(p, m, b, headers);
    };
    await controller.refresh();
    expect(controller.coolingDown, true);
    expect(controller.canRefresh, false);
    expect(controller.canOffer, false);
    final count = h.api.calls.length;
    await controller.refresh();
    expect(h.api.calls.length, count);
  });
}
