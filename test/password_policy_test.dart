import 'package:bagoo_rider_mobile/core/security/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rider new-password policy', () {
    test('accepts the API minimum and maximum lengths', () {
      expect(riderNewPasswordError('Abcdef1!'), isNull);
      expect(
        riderNewPasswordError('Abcdef1!${List.filled(120, 'a').join()}'),
        isNull,
      );
    });

    test('rejects passwords outside the API length bounds', () {
      expect(riderNewPasswordError('Abcde1!'), isNotNull);
      expect(
        riderNewPasswordError('Abcdef1!${List.filled(121, 'a').join()}'),
        isNotNull,
      );
    });

    test(
      'requires uppercase, lowercase, number, and punctuation or symbol',
      () {
        for (final password in [
          'abcdef1!',
          'ABCDEF1!',
          'Abcdefg!',
          'Abcdef12',
          'Abcdef12 ',
        ]) {
          expect(riderNewPasswordError(password), isNotNull, reason: password);
        }
      },
    );

    test('accepts Unicode categories and preserves ordinary spaces', () {
      expect(riderNewPasswordError('Ábcde١!x'), isNull);
      expect(riderNewPasswordError(' Abcde1! '), isNull);
    });

    test('rejects control and non-printing characters', () {
      expect(riderNewPasswordError('Abcde1!\n'), isNotNull);
      expect(riderNewPasswordError('Abcde1!\u200b'), isNotNull);
    });

    test('requires a value', () {
      expect(riderNewPasswordError(null), isNotNull);
      expect(riderNewPasswordError(''), isNotNull);
    });
  });
}
