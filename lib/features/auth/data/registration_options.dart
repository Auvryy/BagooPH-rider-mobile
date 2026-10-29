import '../../../core/network/wire.dart';

/// Current server requirements. Policy versions are never bundled in the app.
class RiderRegistrationOptions {
  RiderRegistrationOptions.fromJson(Map<String, dynamic> json) {
    final policies = Wire.object(json['registration_policies']);
    if (policies['required'] != true || json['sex_required'] != true) {
      Wire.invalid();
    }
    termsVersion = _version(policies['terms_version']);
    privacyVersion = _version(policies['privacy_version']);
    termsPath = Wire.string(policies['terms_url']);
    privacyPath = Wire.string(policies['privacy_url']);
    if (termsPath != '/terms/$termsVersion' ||
        privacyPath != '/privacy/$privacyVersion') {
      Wire.invalid();
    }
    final values = json['sex_options'];
    if (values is! List || values.isEmpty || values.length > 16) {
      Wire.invalid();
    }
    sexOptions = List.unmodifiable(
      values.map((value) {
        final text = Wire.string(value);
        if (text.isEmpty || text.length > 40 || text.trim() != text) {
          Wire.invalid();
        }
        return text;
      }),
    );
    if (sexOptions.toSet().length != sexOptions.length) Wire.invalid();
    final limits = json['birth_date_limits'];
    adultMaximum = limits is Map && limits['adult_maximum'] is String
        ? DateTime.tryParse(limits['adult_maximum'] as String)
        : null;
  }

  late final String termsVersion, privacyVersion, termsPath, privacyPath;
  late final List<String> sexOptions;
  late final DateTime? adultMaximum;

  static String _version(Object? value) {
    final text = Wire.string(value);
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$').hasMatch(text)) {
      Wire.invalid();
    }
    return text;
  }

  bool samePolicies(RiderRegistrationOptions other) =>
      termsVersion == other.termsVersion &&
      privacyVersion == other.privacyVersion;

  Map<String, String> submission({
    required String sex,
    required bool accepted,
  }) {
    if (!sexOptions.contains(sex) || !accepted) {
      throw const FormatException(
        'Choose your sex and agree to the current policies.',
      );
    }
    return {
      'sex': sex,
      'policy_accepted': '1',
      'terms_version': termsVersion,
      'privacy_version': privacyVersion,
    };
  }
}
