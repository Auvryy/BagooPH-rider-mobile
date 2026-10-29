import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/company_support.dart';

void main() {
  test('applying uses current intake and explicit sharing, without changing duty or role', () async {
    final s = companySetup();
    final company = (await s.repository.companies()).items.single;
    final result = await s.repository.submit(
      company,
      sharingAcknowledged: true,
      note: '  Available for work  ',
      mayDispatch: () => true,
    );
    expect(result.status, 'pending');
    expect(s.api.writes, 1);
    expect(s.journal.value, isNull);
    final write = s.api.calls.last;
    expect(write.body, {
      'company_id': '1',
      'intake_version': '1',
      'sharing_acknowledged': true,
      'note': 'Available for work',
    });
    expect(write.headers['Idempotency-Key'], isNotEmpty);
    expect(s.api.membership['on_duty'], isFalse);
  });
  test(
    'acceptance rechecks the exact version, offer and terms before sending',
    () async {
      final s = companySetup();
      final reviewed = await s.repository.application('1');
      final result = await s.repository.decide(
        reviewed,
        'company.accepted',
        acknowledged: true,
        mayDispatch: () => true,
      );
      expect(result.status, 'accepted');
      expect(s.api.membership['on_duty'], isFalse);
      final body = s.api.calls.last.body as Map;
      expect(body['offer_id'], reviewed.offer!.id);
      expect(body['terms_hash'], reviewed.offer!.termsHash);
      expect(body['expected_version'], reviewed.version);
      expect(body['acknowledged'], isTrue);
    },
  );
  test('changed-and-restored offers, intake and unavailable actions never dispatch stale consent', () async {
    final s = companySetup();
    final reviewed = await s.repository.application('1');
    s.api.detail['version'] = 3;
    await expectLater(
      s.repository.decide(
        reviewed,
        'company.accepted',
        acknowledged: true,
        mayDispatch: () => true,
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(s.api.writes, 0);
    expect(s.journal.value, isNull);
    final company = (await s.repository.companies()).items.single;
    s.api.company['intake_version'] = 2;
    await expectLater(
      s.repository.submit(
        company,
        sharingAcknowledged: true,
        mayDispatch: () => true,
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(s.api.writes, 0);
  });
  test('a lost committed response reconciles the original receipt without another write', () async {
    final s = companySetup();
    final company = (await s.repository.companies()).items.single;
    s.api.loseAfterCommit = true;
    await expectLater(
      s.repository.submit(
        company,
        sharingAcknowledged: true,
        mayDispatch: () => true,
      ),
      throwsA(isA<AccountFailure>()),
    );
    final key = s.journal.value!.key;
    final receipt = await s.repository.reconcile(mayDispatch: () => false);
    expect(receipt!.status, 'pending');
    expect(s.api.writes, 1);
    expect(s.journal.value, isNull);
    expect(s.api.results.containsKey(key), isTrue);
  });
  test('unknown outcome retains its key; explicit retry uses the identical original body', () async {
    final s = companySetup();
    final company = (await s.repository.companies()).items.single;
    s.api.loseBeforeCommit = true;
    await expectLater(
      s.repository.submit(
        company,
        sharingAcknowledged: true,
        mayDispatch: () => true,
      ),
      throwsA(isA<AccountFailure>()),
    );
    final original = s.journal.value!;
    await expectLater(
      s.repository.reconcile(mayDispatch: () => true),
      throwsA(isA<AccountFailure>()),
    );
    expect(s.journal.value!.key, original.key);
    await s.repository.reconcile(retryUnknown: true, mayDispatch: () => true);
    final writes = s.api.calls.where((c) => c.method == 'POST').toList();
    expect(writes, hasLength(2));
    expect(writes[0].headers, writes[1].headers);
    expect(writes[0].body, writes[1].body);
  });
  test(
    'storage, acknowledgement and background failures prevent dispatch',
    () async {
      final s = companySetup();
      final company = (await s.repository.companies()).items.single;
      await expectLater(
        s.repository.submit(
          company,
          sharingAcknowledged: false,
          mayDispatch: () => true,
        ),
        throwsFormatException,
      );
      s.journal.failWrite = true;
      await expectLater(
        s.repository.submit(
          company,
          sharingAcknowledged: true,
          mayDispatch: () => true,
        ),
        throwsStateError,
      );
      expect(s.api.writes, 0);
      s.journal.failWrite = false;
      await expectLater(
        s.repository.submit(
          company,
          sharingAcknowledged: true,
          mayDispatch: () => false,
        ),
        throwsA(isA<AccountFailure>()),
      );
      expect(s.api.writes, 0);
    },
  );
  test('malformed receipt is retained for reconciliation instead of reporting success', () async {
    final s = companySetup();
    final company = (await s.repository.companies()).items.single;
    s.api.wrongReceipt = true;
    await expectLater(
      s.repository.submit(
        company,
        sharingAcknowledged: true,
        mayDispatch: () => true,
      ),
      throwsFormatException,
    );
    expect(s.journal.value, isNotNull);
    expect(s.api.writes, 1);
  });
  test(
    'account change rejects reads without exposing the old company data',
    () async {
      var current = true;
      final s = companySetup(isCurrent: () => current);
      current = false;
      await expectLater(
        s.repository.assignment(),
        throwsA(isA<AccountFailure>()),
      );
      expect(s.api.calls, isEmpty);
    },
  );
}
