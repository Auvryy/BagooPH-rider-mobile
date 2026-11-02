import 'package:bagoo_rider_mobile/core/security/account_input_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rider account input validation', () {
    test('email limits, whitespace, controls, and endpoint normalization', () {
      expect(riderEmailInputError('rider@example.com'), isNull);
      expect(riderEmailInputError('rider+orders@delivery-team.ph'), isNull);
      expect(riderEmailInputError('"rider@ops"@example.com'), isNull);
      expect(riderEmailInputError('rider@example.рф'), isNull);
      expect(riderEmailInputError('rider@example.com\u200b'), isNotNull);
      expect(riderEmailInputError('not-an-email'), isNotNull);
      for (final malformed in [
        'x..y@example.com',
        'x@example..com',
        'x@-example.com',
        'x@example-.com',
        'x@example.com-',
        'x@@example.com',
      ]) {
        expect(riderEmailInputError(malformed), isNotNull, reason: malformed);
      }
      expect(
        riderEmailInputError('a@${List.filled(250, 'b').join()}.com'),
        contains('255'),
      );
      expect(riderEmailInputError('rider＠example.com'), isNotNull);
      expect(
        riderEmailInputError(
          'rider＠example.com',
          normalizeCompatibilityCharacters: true,
        ),
        isNull,
      );
    });

    test('Settings current password uses the API bound', () {
      expect(riderCurrentPasswordError('legacy password'), isNull);
      expect(riderCurrentPasswordError(List.filled(4096, 'x').join()), isNull);
      expect(
        riderCurrentPasswordError(List.filled(4097, 'x').join()),
        isNotNull,
      );
      expect(riderCurrentPasswordError(''), isNotNull);
    });

    test('verification codes are exactly six ASCII digits', () {
      expect(riderVerificationCodeError('123456'), isNull);
      for (final value in [
        null,
        '',
        '12345',
        '1234567',
        '12 456',
        '12a456',
        '１２３４５６',
        '123456 ',
      ]) {
        expect(riderVerificationCodeError(value), isNotNull, reason: '$value');
      }
    });

    test('sign-in password is only required, matching the login API', () {
      expect(riderSignInPasswordError('legacy password'), isNull);
      expect(riderSignInPasswordError(List.filled(4097, 'x').join()), isNull);
      expect(riderSignInPasswordError(''), isNotNull);
    });

    test('name and address rules reject unsupported and unsafe text', () {
      expect(riderNameInputError('  José D’Angelo  '), isNull);
      expect(riderNameInputError('A'), isNotNull);
      expect(riderNameInputError('Rider 123'), isNotNull);
      expect(riderNameInputError('<script>'), isNotNull);
      expect(riderNameInputError('onload = test'), isNotNull);
      expect(riderAddressInputError('123 Sampaguita Street'), isNull);
      expect(riderAddressInputError('Abcd'), isNotNull);
      expect(riderAddressInputError('123 Street\nCity'), isNotNull);
      expect(riderAddressInputError(List.filled(501, 'a').join()), isNotNull);
    });

    test(
      'optional location values may be blank but must match server bounds',
      () {
        expect(riderLocationInputError('   ', label: 'province'), isNull);
        expect(riderLocationInputError('Laguna', label: 'province'), isNull);
        expect(riderLocationInputError('A', label: 'barangay'), isNotNull);
        expect(
          riderLocationInputError(
            'Quezon City',
            label: 'city or municipality',
            isRequired: true,
          ),
          isNull,
        );
        expect(
          riderLocationInputError(
            '  ',
            label: 'city or municipality',
            isRequired: true,
          ),
          isNotNull,
        );
      },
    );

    test(
      'Philippine mobile accepts canonical formats and rejects other numbers',
      () {
        for (final value in [
          '09171234567',
          '0917 123 4567',
          '+63 917 123 4567',
          '639171234567',
        ]) {
          expect(riderPhilippineMobileError(value), isNull, reason: value);
        }
        for (final value in [
          '2025550199',
          '0917123456',
          '+639171234567 ext 1',
          '０９１７１２３４５６７',
        ]) {
          expect(riderPhilippineMobileError(value), isNotNull, reason: value);
        }
        expect(riderPhilippineMobileError('  ', optional: true), isNull);
        expect(riderPhilippineMobileError('  '), isNotNull);
        expect(
          riderPhilippineMobileError('0917 123 4567', maxCharacters: 10),
          isNotNull,
        );
      },
    );

    test('plate formats depend on the selected vehicle', () {
      expect(
        riderPhilippinePlateError('AB1234', vehicleType: 'Motorcycle'),
        isNull,
      );
      expect(
        riderPhilippinePlateError('AB 1234', vehicleType: 'Scooter'),
        isNull,
      );
      expect(
        riderPhilippinePlateError('ABC1234', vehicleType: 'Sedan / Van'),
        isNull,
      );
      expect(
        riderPhilippinePlateError('DEMO-123', vehicleType: 'Motorcycle'),
        isNotNull,
      );
      expect(
        riderPhilippinePlateError('ABC1234', vehicleType: 'Motorcycle'),
        isNotNull,
      );
      expect(
        riderPhilippinePlateError('AB1234', vehicleType: 'Unknown'),
        isNotNull,
      );
    });

    test('license accepts the formatted and compact server forms', () {
      expect(riderPhilippineLicenseError('N01-12-345678'), isNull);
      expect(riderPhilippineLicenseError('n0112345678'), isNull);
      expect(riderPhilippineLicenseError('N01 12 345678'), isNull);
      expect(riderPhilippineLicenseError('DEMO-123'), isNotNull);
      expect(riderPhilippineLicenseError('N01-12-34567'), isNotNull);
    });
  });
}
