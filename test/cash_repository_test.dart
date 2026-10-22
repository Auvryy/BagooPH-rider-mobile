import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/cash/data/cash_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';

import 'support/cash_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cash intents use account/API-isolated ordinary journal and preserve other scopes', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final origin = Uri.parse('https://example.test/api/v1');
    final work = SecureCommandJournal(origin: origin, accountId: '5');
    final cash = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'cash.offer',
      resource: 'cash-7',
      body: {
        'expected_version': '1',
        'recipient_id': '12',
        'amount': '125.00',
        'evidence_reference': 'TEST-01',
      },
      createdAt: DateTime.utc(2026),
    );
    await work.write(cash);
    expect(
      (await SecureCommandJournal(origin: origin, accountId: '5').read())!.key,
      cash.key,
    );
    expect(
      await SecureCommandJournal(origin: origin, accountId: '6').read(),
      isNull,
    );
    expect(
      await SecureCommandJournal(
        origin: Uri.parse('https://other.test/api/v1'),
        accountId: '5',
      ).read(),
      isNull,
    );
    expect(
      await SecureCommandJournal(
        origin: origin,
        accountId: '5',
        scope: 'messages',
      ).read(),
      isNull,
    );
    final notices = SecureCommandJournal(
      origin: origin,
      accountId: '5',
      scope: 'notifications',
    );
    await expectLater(notices.write(cash), throwsFormatException);
    final duty = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'duty',
      resource: 'rider',
      body: {'on_duty': false},
      createdAt: DateTime.utc(2026),
    );
    await work.write(duty);
    expect((await work.read())!.action, 'duty');
    await work.clear();
  });
  test('all-owned summary, large IDs/cents and signed journal adjustments remain exact', () {
    final json = cashFixture();
    json['history'][0]['amount_cents'] = '-9007199254740993';
    json['history'][0]['discrepancy_cents'] = '-100';
    json['discrepancies'] = [
      {
        'source_reference': 'SHORTAGE-01',
        'difference_cents': '-100',
        'holder_id': '5',
        'resolved_by': null,
      },
    ];
    final account = CashAccount.fromJson(json, detail: true),
        page = CashPage.fromJson(cashPageFixture());
    expect(account.id, '9007199254740993');
    expect(account.history.single.amount, BigInt.parse('-9007199254740993'));
    expect(account.discrepancies.single.cents, BigInt.from(-100));
    expect(cashPeso(page.held), '₱9,007,199,254,740,993,125.00');
    expect(cashPeso(BigInt.from(-100)), '−₱1.00');
  });
  test('invalid schemas, earnings, duplicates and parcel hex sequence are rejected', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['version'] = 'a' * 64,
      (j) => j['own_held_cents'] = '1.2',
      (j) => j['own_held_cents'] = 12500,
      (j) => j['can_receive'] = true,
      (j) => j['earnings'] = {'available': true, 'confirmed_cents': '5'},
      (j) => j['recipients'].add(j['recipients'][0]),
    ]) {
      final j = cashFixture();
      mutate(j);
      expect(
        () => CashAccount.fromJson(j, detail: true),
        throwsFormatException,
      );
    }
    final p = cashPageFixture();
    p['summary']['basis'] = 'filtered_page';
    expect(() => CashPage.fromJson(p), throwsFormatException);
  });
  test(
    'read-only dashboard is usable with independent offer gate disabled',
    () async {
      final h = CashHarness();
      h.repository = h.restart(enabled: false);
      expect(
        const AppConfig('https://example.test/api/v1').cashWritesVerified,
        false,
      );
      expect(await h.repository.cashAvailable(), true);
      expect(
        (await h.repository.cashPage(query: 'BGO-TEST')).held,
        BigInt.parse('900719925474099312500'),
      );
      expect(
        (await h.repository.cashDetail(h.account.id)).held,
        BigInt.from(12500),
      );
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
    },
  );
  test('offer persists exact original body before dispatch, and only accepts awaiting receipt', () async {
    final h = CashHarness();
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        expect(h.journal.events, ['persist']);
        final intent = h.journal.value!;
        expect(intent.action, 'cash.offer');
        expect(intent.resource, 'cash-${h.account.id}');
        expect(intent.body, {
          'expected_version': '1',
          'recipient_id': '12',
          'amount': '125.00',
          'evidence_reference': 'TEST-HANDOVER-01',
        });
        expect(body, intent.body);
        expect(headers['Idempotency-Key'], intent.key);
      }
      return h.respond(path, method, body, headers);
    };
    final result = await h.submit();
    expect(result['handover_state'], 'awaiting_recipient_receipt');
    expect(h.journal.value, isNull);
    expect(h.account.held, BigInt.from(12500));
    expect(h.account.remitted, BigInt.zero);
  });
  test(
    'journal refuses privilege fields, wrong sequence and malformed reference',
    () {
      final h = CashHarness();
      for (final override in [
        {'holder_id': '5'},
        {'expected_version': 'a' * 64},
        {'recipient_id': '9223372036854775808'},
        {'amount': '0'},
        {'amount': '1e2'},
        {'evidence_reference': 'data:abc'},
      ]) {
        expect(
          () => CommandIntent(
            accountId: '5',
            key: commandUuid(),
            action: 'cash.offer',
            resource: 'cash-${h.account.id}',
            body: {
              'expected_version': '1',
              'recipient_id': '12',
              'amount': '1.00',
              'evidence_reference': 'TEST-01',
              ...override,
            },
            createdAt: DateTime.utc(2026),
          ),
          throwsA(anything),
        );
      }
    },
  );
  test('cash lost response survives restart; gate-off lookup confirms original result', () async {
    final h = CashHarness();
    h.api.respond = (p, m, b, headers) async {
      if (m == 'POST') {
        h.committed = h.result(h.journal.value!);
        throw const AccountFailure('Lost response', unconfirmed: true);
      }
      return h.respond(p, m, b, headers);
    };
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    h.journal.value = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    h.repository = h.restart(enabled: false);
    expect((await h.repository.reconcile())!['event_reference'], 'EVENT-OFFER');
    expect(h.journal.value, isNull);
    expect(h.api.calls.where((r) => r.method == 'POST').length, 1);
  });
  test('unknown lookup never clears or creates replacement; retry uses same key/body', () async {
    final h = CashHarness();
    var post = 0;
    h.api.respond = (p, m, b, headers) async {
      if (m == 'POST' && post++ == 0) {
        throw const AccountFailure('Lost request', unconfirmed: true);
      }
      return h.respond(p, m, b, headers);
    };
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    expect(await h.repository.reconcile(), isNull);
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    h.repository = h.restart();
    await h.repository.reconcile(retryUnknown: true, mayDispatch: () => true);
    final writes = h.api.calls.where((r) => r.method == 'POST').toList();
    expect(writes.length, 2);
    expect(writes[1].headers['Idempotency-Key'], original.key);
    expect(writes[1].body, writes[0].body);
    expect(h.journal.value, isNull);
  });
  test('unknown retry is blocked by gate, background, old window and revoked capability', () async {
    for (final state in ['gate', 'background', 'expired', 'capability']) {
      final h = CashHarness();
      h.api.respond = (p, m, b, headers) async {
        if (m == 'POST') throw const AccountFailure('Lost', unconfirmed: true);
        return h.respond(p, m, b, headers);
      };
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      final key = h.journal.value!.key;
      h.repository = h.restart(
        enabled: state != 'gate',
        now: () => DateTime.utc(2026, 10, state == 'expired' ? 30 : 22, 2),
      );
      h.capable = state != 'capability';
      await expectLater(
        h.repository.reconcile(
          retryUnknown: true,
          mayDispatch: () => state != 'background',
        ),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value!.key, key);
      expect(h.api.calls.where((r) => r.method == 'POST').length, 1);
    }
  });
  test('storage failure, wrong recipient, excess/zero amount and changed review never dispatch', () async {
    for (final state in [
      'storage',
      'recipient',
      'amount',
      'zero',
      'changed',
      'capability',
    ]) {
      final h = CashHarness();
      final reviewed = h.account;
      if (state == 'storage') h.journal.failWrite = true;
      if (state == 'capability') h.capable = false;
      if (state == 'changed') h.json['own_held_cents'] = '12000';
      await expectLater(
        h.repository.offerCash(
          reviewed,
          recipientId: state == 'recipient' ? '99' : '12',
          amount: state == 'amount'
              ? '126'
              : state == 'zero'
              ? '0'
              : '125.00',
          evidenceReference: 'TEST-01',
          mayDispatch: () => true,
        ),
        throwsA(anything),
      );
      expect(h.api.calls.where((r) => r.method == 'POST'), isEmpty);
    }
  });
  test('simultaneous cash and duty attempts cannot bypass shared unresolved work lock', () async {
    final h = CashHarness(), wait = Completer<void>();
    h.api.respond = (p, m, b, headers) async {
      if (m == 'POST') await wait.future;
      return h.respond(p, m, b, headers);
    };
    final offer = h.submit();
    await Future<void>.delayed(Duration.zero);
    await expectLater(h.repository.duty(true), throwsA(isA<AccountFailure>()));
    wait.complete();
    await offer;
  });
  test(
    'malformed or mismatched committed results retain original recovery intent',
    () async {
      for (final field in [
        'cash_account_id',
        'handover_state',
        'ledger_version',
      ]) {
        final h = CashHarness();
        h.api.respond = (p, m, b, headers) async {
          if (m == 'POST') {
            final result = h.result(h.journal.value!);
            result['result'][field] = field == 'cash_account_id'
                ? '999'
                : field == 'ledger_version'
                ? 'a' * 64
                : 'received';
            return {'data': result};
          }
          return h.respond(p, m, b, headers);
        };
        await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
        expect(h.journal.value, isNotNull);
      }
    },
  );
  test('cash search rejects invisible markup and meaningless punctuation', () {
    for (final query in [
      '---',
      'data:abc',
      'ab\u034fcd',
      'abc<def',
      'ab\ufe00cd',
    ]) {
      expect(() => cashQuery(query), throwsA(isA<AccountFailure>()));
    }
    expect(cashQuery(' BGO-TEST '), 'BGO-TEST');
  });
}
