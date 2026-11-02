import 'package:unorm_dart/unorm_dart.dart' as unicode;

String? riderEmailInputError(
  String? value, {
  String label = 'email address',
  bool normalizeCompatibilityCharacters = false,
}) {
  final text = normalizeCompatibilityCharacters
      ? _applicationNormalized(value ?? '')
      : (value ?? '').trim();
  if (text.isEmpty) return 'Enter your $label.';
  if (text.runes.length > 255) {
    return 'Use an email address up to 255 characters.';
  }
  if (RegExp(r'[\p{C}\s]', unicode: true).hasMatch(text) ||
      !RegExp(r'^\S+@\S+\.\S+$', unicode: true).hasMatch(text)) {
    return 'Enter a valid $label.';
  }
  return null;
}

String? riderCurrentPasswordError(String? value, {String label = 'password'}) {
  if (value == null || value.isEmpty) return 'Enter your $label.';
  if (value.runes.length > 4096) {
    return 'Use a $label up to 4,096 characters.';
  }
  return null;
}

String? riderSignInPasswordError(String? value) =>
    value == null || value.isEmpty ? 'Enter your password.' : null;

String? riderNameInputError(String? value) => _applicationTextError(
  value,
  label: 'full name',
  min: 2,
  max: 100,
  kind: _ApplicationTextKind.name,
  isRequired: true,
);

String? riderAddressInputError(String? value) => _applicationTextError(
  value,
  label: 'street address',
  min: 5,
  max: 500,
  kind: _ApplicationTextKind.location,
  isRequired: true,
);

String? riderLocationInputError(
  String? value, {
  required String label,
  bool isRequired = false,
}) => _applicationTextError(
  value,
  label: label,
  min: 2,
  max: 255,
  kind: _ApplicationTextKind.location,
  isRequired: isRequired,
);

String? riderPhilippineMobileError(
  String? value, {
  bool optional = false,
  int? maxCharacters,
}) {
  final text = (value ?? '').replaceAll(RegExp(r'^ +| +$'), '');
  if (text.isEmpty) return optional ? null : 'Enter your mobile number.';
  if (maxCharacters != null && text.runes.length > maxCharacters) {
    return 'Use a Philippine mobile number up to $maxCharacters characters.';
  }
  if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text)) {
    return 'Use a Philippine mobile number, such as 09171234567.';
  }

  var digits = text.replaceAll(RegExp(r'[ ()-]'), '');
  if (digits.startsWith('0')) {
    digits = '+63${digits.substring(1)}';
  } else if (digits.startsWith('63')) {
    digits = '+$digits';
  }
  return RegExp(r'^\+639[0-9]{9}$').hasMatch(digits)
      ? null
      : 'Use a Philippine mobile number, such as 09171234567 or +639171234567.';
}

String? riderPhilippinePlateError(
  String? value, {
  required String vehicleType,
}) {
  var text = _applicationNormalized(value ?? '').toUpperCase();
  if (text.isEmpty) return 'Enter your plate or registration number.';
  text = text.replaceAll(RegExp(r'[ -]+'), '-');
  if (text.length > 8 ||
      !RegExp(r'^[A-Z0-9]+(?:-[A-Z0-9]+)?$').hasMatch(text)) {
    return 'Enter a valid Philippine plate number for $vehicleType.';
  }

  final plate = text.replaceAll('-', '');
  final valid = vehicleType == 'Sedan / Van'
      ? RegExp(r'^[A-Z]{3}[0-9]{2,4}$').hasMatch(plate)
      : const {'Motorcycle', 'Scooter'}.contains(vehicleType) &&
            (RegExp(r'^(?:[A-Z]{2}[0-9]{4,5}|[0-9]{3,4}[A-Z]{2})$')
                    .hasMatch(plate) ||
                (plate.length == 6 &&
                    RegExp(r'^[A-Z0-9]{6}$').hasMatch(plate) &&
                    RegExp(r'[A-Z]').hasMatch(plate) &&
                    RegExp(r'[0-9]').hasMatch(plate)));
  return valid
      ? null
      : 'Enter a valid Philippine plate number for $vehicleType.';
}

String? riderPhilippineLicenseError(String? value) {
  var text = _applicationNormalized(value ?? '').toUpperCase();
  if (text.isEmpty) return 'Enter your driver’s license number.';
  text = text.replaceAll(RegExp(r'[ -]+'), '-');
  return RegExp(r'^(?:[A-Z][0-9]{2}-[0-9]{2}-[0-9]{6}|[A-Z][0-9]{10})$')
          .hasMatch(text)
      ? null
      : 'Use the license number on your card, such as N01-12-345678.';
}

enum _ApplicationTextKind { name, location }

String? _applicationTextError(
  String? value, {
  required String label,
  required int min,
  required int max,
  required _ApplicationTextKind kind,
  required bool isRequired,
}) {
  final text = _applicationNormalized(value ?? '');
  if (text.isEmpty) return isRequired ? 'Enter your $label.' : null;
  if (text.runes.length < min || text.runes.length > max) {
    return 'Use $min–$max characters for $label.';
  }

  final permitted = kind == _ApplicationTextKind.name
      ? RegExp(r"^[\p{Script=Latin}\p{M} .’'\-]+$", unicode: true)
      : RegExp(r"^[\p{Script=Latin}\p{M}\p{N} #.,’'\-/()&:]+$", unicode: true);
  final meaningful = kind == _ApplicationTextKind.name
      ? RegExp(r'\p{Script=Latin}', unicode: true)
      : RegExp(r'[\p{L}\p{N}]', unicode: true);
  final unsafe = RegExp(
    r'[\u034f\ufe00-\ufe0f]|(?:javascript|vbscript|data)\s*:|\bon[a-z]+\s*=',
    caseSensitive: false,
    unicode: true,
  );
  if (!permitted.hasMatch(text) ||
      !meaningful.hasMatch(text) ||
      unsafe.hasMatch(text)) {
    return kind == _ApplicationTextKind.name
        ? 'Use letters, spaces, apostrophes, hyphens, or periods for $label.'
        : 'Use meaningful plain text for $label.';
  }
  return null;
}

String _applicationNormalized(String value) =>
    unicode.nfkc(value).replaceAll(RegExp(r'^ +| +$'), '');
