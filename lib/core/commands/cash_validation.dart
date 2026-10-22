import '../network/api_failure.dart';
import '../network/wire.dart';
import 'parcel_validation.dart';

BigInt cashCents(Object? value, {bool signed = false}) {
  final text = Wire.string(value);
  final rule = signed ? r'^(?:0|-?[1-9][0-9]*)$' : r'^(?:0|[1-9][0-9]*)$';
  if (text.length > 100 || RegExp(rule).firstMatch(text)?.end != text.length) {
    Wire.invalid();
  }
  return BigInt.parse(text);
}

String cashPeso(BigInt cents) {
  final amount = cents.abs();
  final whole = (amount ~/ BigInt.from(100)).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${cents.isNegative ? '−' : ''}₱$whole.${(amount % BigInt.from(100)).toString().padLeft(2, '0')}';
}

String cashEvidence(String value) {
  final text = value.trim();
  if (text.length < 3 ||
      text.length > 120 ||
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9 :._/-]*$').firstMatch(text)?.end !=
          text.length ||
      RegExp(
        r'(?:javascript|vbscript|data)\s*:|\bon[a-z]+\s*=',
        caseSensitive: false,
      ).hasMatch(text)) {
    throw const AccountFailure(
      'Enter a plain handover reference of 3–120 characters.',
      fields: {
        'evidence_reference': 'Use letters, numbers, spaces, : . _ / or -.',
      },
    );
  }
  return text;
}

String cashQuery(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (text.runes.length > 100 ||
      !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text) ||
      RegExp(
            r"^[\p{Script=Latin}\p{M}\p{N} #.,’'\-/()&:]+$",
            unicode: true,
          ).firstMatch(text)?.end !=
          text.length ||
      RegExp(
        r'(?:javascript|vbscript|data)\s*:|\bon[a-z]+\s*=|[\u034f\ufe00-\ufe0f]',
        caseSensitive: false,
      ).hasMatch(text)) {
    throw const AccountFailure(
      'Search using a plain parcel reference of up to 100 characters.',
    );
  }
  return text;
}

void cashOfferFields(Map<String, dynamic> body) {
  if (body.length != 4 ||
      !body.keys.toSet().containsAll({
        'expected_version',
        'recipient_id',
        'amount',
        'evidence_reference',
      })) {
    Wire.invalid();
  }
  Wire.id(body['expected_version']);
  Wire.id(body['recipient_id']);
  if (pesoInputCents(Wire.string(body['amount']), field: 'amount') <=
      BigInt.zero) {
    Wire.invalid();
  }
  if (cashEvidence(Wire.string(body['evidence_reference'])) !=
      body['evidence_reference']) {
    Wire.invalid();
  }
}
