import 'package:bagoo_rider_mobile/features/auth/data/registration_options.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> currentOptions() => {
  'sex_required': true,
  'sex_options': ['Female', 'Male', 'Other'],
  'registration_policies': {
    'required': true,
    'terms_version': '2026-10-12',
    'privacy_version': '2026-10-13',
    'terms_url': '/terms/2026-10-12',
    'privacy_url': '/privacy/2026-10-13',
  },
};

void main() {
  test('registration sends the displayed current policy versions and explicit sex/consent', () {
    final options = RiderRegistrationOptions.fromJson(currentOptions());
    expect(options.submission(sex: 'Other', accepted: true), {
      'sex': 'Other',
      'policy_accepted': '1',
      'terms_version': '2026-10-12',
      'privacy_version': '2026-10-13',
    });
    expect(
      () => options.submission(sex: 'Other', accepted: false),
      throwsFormatException,
    );
    expect(
      () => options.submission(sex: 'Unknown', accepted: true),
      throwsFormatException,
    );
  });

  test(
    'policy versions cannot open another host or unrelated application route',
    () {
      for (final path in [
        'https://example.test/terms',
        '//example.test/terms',
        '/profile',
        '/terms/other-version',
        '/terms/2026-10-12?x=1',
      ]) {
        final json = currentOptions();
        (json['registration_policies'] as Map)['terms_url'] = path;
        expect(
          () => RiderRegistrationOptions.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'missing contracts and malformed sex choices keep registration unavailable',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j.remove('registration_policies'),
        (j) => j['sex_options'] = [],
        (j) => j['sex_options'] = ['Female', 'Female'],
        (j) => j['sex_options'] = [' Female'],
        (j) => j['sex_required'] = false,
        (j) => (j['registration_policies'] as Map)['privacy_version'] =
            '../escape',
      ]) {
        final json = currentOptions();
        mutate(json);
        expect(
          () => RiderRegistrationOptions.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );

  test('a new policy revision requires a fresh acknowledgement', () {
    final original = RiderRegistrationOptions.fromJson(currentOptions());
    final json = currentOptions();
    final policies = json['registration_policies'] as Map;
    policies['terms_version'] = '2026-11-01';
    policies['terms_url'] = '/terms/2026-11-01';
    expect(
      original.samePolicies(RiderRegistrationOptions.fromJson(json)),
      isFalse,
    );
    expect(
      original.samePolicies(
        RiderRegistrationOptions.fromJson(currentOptions()),
      ),
      isTrue,
    );
  });
}
