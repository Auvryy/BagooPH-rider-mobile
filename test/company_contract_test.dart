import 'package:bagoo_rider_mobile/features/company/data/company_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/company_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('exercised website company examples preserve exact offers and separate duty', () {
    final page = CompanyPage.fromJson(
      companyFixture('companies'),
      RiderCompany.fromJson,
      (c) => c.id,
    );
    expect(page.items.single.name, 'Bagoo Company Network');
    final offer = CompanyApplication.fromJson(
      companyFixture('application-offered'),
    );
    expect(offer.canAccept, isTrue);
    expect(offer.offer!.termsHash, hasLength(64));
    expect(offer.offer!.issuedAt.microsecond, 456);
    final accepted = CompanyAssignment.fromJson(
      companyFixture('assignment-accepted'),
    );
    expect(accepted.companyId, '1');
    expect(accepted.onDuty, isFalse);
    expect(accepted.canApply, isFalse);
    expect(
      CompanyApplication.fromJson(companyFixture('application-expired'))
          .canAccept,
      isFalse,
    );
    expect(
      companyTime('2026-10-15T06:14:13.000000Z'),
      DateTime.utc(2026, 10, 15, 6, 14, 13),
    );
  });
  test('company intents require real acknowledgement and reject managed fields or altered hashes', () {
    Map<String, dynamic> body() => {
      'company_id': '1',
      'intake_version': 1,
      'sharing_acknowledged': true,
    };
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (b) => b['sharing_acknowledged'] = 'true',
      (b) => b['company_id'] = '01',
      (b) => b['intake_version'] = 1.0,
      (b) => b['rider_id'] = '9',
      (b) => b['on_duty'] = true,
    ]) {
      final value = body();
      mutate(value);
      expect(
        () => CommandIntent(
          accountId: '7',
          key: commandUuid(),
          action: 'company.submit',
          resource: 'company-1',
          body: value,
          createdAt: DateTime.utc(2026),
        ),
        throwsFormatException,
      );
    }
    expect(companyNote('  Ａvailable for work  '), 'Available for work');
    for (final text in [
      'abc',
      '<script>work</script>',
      'work\u200B note',
      'x' * 501,
    ]) {
      expect(() => companyNote(text), throwsA(isA<Exception>()));
    }
  });
  test('company journal is protected and separate from parcel, messages and another account', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final origin = Uri.parse('https://example.test/api/v1');
    final journal = SecureCommandJournal(
      origin: origin,
      accountId: '7',
      scope: 'company',
    );
    final intent = CommandIntent(
      accountId: '7',
      key: commandUuid(),
      action: 'company.submit',
      resource: 'company-1',
      body: {
        'company_id': '1',
        'intake_version': '1',
        'sharing_acknowledged': true,
      },
      createdAt: DateTime.utc(2026),
    );
    await journal.write(intent);
    expect((await journal.read())!.key, intent.key);
    expect(
      await SecureCommandJournal(origin: origin, accountId: '7').read(),
      isNull,
    );
    expect(
      await SecureCommandJournal(
        origin: origin,
        accountId: '7',
        scope: 'messages',
      ).read(),
      isNull,
    );
    expect(
      await SecureCommandJournal(
        origin: origin,
        accountId: '8',
        scope: 'company',
      ).read(),
      isNull,
    );
    await expectLater(
      SecureCommandJournal(origin: origin, accountId: '7').write(intent),
      throwsFormatException,
    );
  });
}
