/// Matches the password policy advertised and enforced by the Rider API.
///
/// Passwords are checked exactly as entered. In particular, spaces are not
/// trimmed, and a punctuation or symbol character is still required.
String? riderNewPasswordError(String? value) {
  if (value == null || value.isEmpty) return 'Enter a new password.';

  final length = value.runes.length;
  if (length < 8 || length > 128) {
    return 'Use 8–128 characters.';
  }

  final uppercase = RegExp(r'\p{Lu}', unicode: true).hasMatch(value);
  final lowercase = RegExp(r'\p{Ll}', unicode: true).hasMatch(value);
  final number = RegExp(r'\p{N}', unicode: true).hasMatch(value);
  final symbol = RegExp(r'[\p{S}\p{P}]', unicode: true).hasMatch(value);
  final control = RegExp(r'\p{C}', unicode: true).hasMatch(value);

  if (control) return 'Remove control or non-printing characters.';
  if (!uppercase || !lowercase || !number || !symbol) {
    return 'Use uppercase and lowercase letters, a number, and a symbol.';
  }
  return null;
}
