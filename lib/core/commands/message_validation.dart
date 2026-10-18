import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../network/api_failure.dart';
import '../network/wire.dart';

/// Native thread references are assignment- and participant-bound, not user IDs.
({String phase, String deliveryId, String assignmentId, String participantId})
messageThreadParts(Object? value) {
  final text = Wire.string(value);
  final match = RegExp(
    r'^(pickup|final_mile)-([1-9][0-9]*)-([1-9][0-9]*)-([1-9][0-9]*)$',
  ).firstMatch(text);
  if (match == null || match.end != text.length) Wire.invalid();
  return (
    phase: match[1]!,
    deliveryId: Wire.id(match[2]),
    assignmentId: Wire.id(match[3]),
    participantId: Wire.id(match[4]),
  );
}

/// Match the owner's NFKC/plain-text policy before retaining the exact body.
/// Control characters are rejected before normalization can conceal them.
String messageText(String value) {
  final permitted = RegExp(r'^(?:[^\p{C}<>`{}]|\r?\n)*$', unicode: true);
  if (permitted.firstMatch(value)?.end != value.length) _invalidText();
  final text = unicode
      .nfkc(value)
      .replaceAll(RegExp(r'^[ \r\n]+|[ \r\n]+$'), '');
  if (text.runes.isEmpty ||
      text.runes.length > 1000 ||
      permitted.firstMatch(text)?.end != text.length ||
      RegExp(r'[\u034f\ufe00-\ufe0f]').hasMatch(text) ||
      RegExp(
        r'(?:javascript|vbscript|data)\s*:|\bon[a-z]+\s*=',
        caseSensitive: false,
      ).hasMatch(text) ||
      !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) {
    _invalidText();
  }
  return text;
}

Never _invalidText() => throw const AccountFailure(
  'Check your message before sending.',
  fields: {
    'text': 'Use 1–1,000 characters of plain text without markup or hidden characters.',
  },
);
