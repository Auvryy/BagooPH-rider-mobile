import '../network/api_failure.dart';

/// Matches the backend's ASCII-only normalization. Never use a saved reference
/// as capture evidence, or translate a tracking-page URL into an API scan.
String parcelWaybill(String value) {
  if (!RegExp(r'^[ -~]+$').hasMatch(value)) {
    throw const AccountFailure(
      'Scan the waybill attached to this parcel.',
      fields: {'barcode': 'The scan must contain the parcel waybill code.'},
    );
  }
  final code = value.replaceAll(RegExp(r'^ +| +$'), '').toUpperCase();
  if (code.length > 255 || !RegExp(r'^[A-Z0-9][A-Z0-9_-]*$').hasMatch(code)) {
    throw const AccountFailure(
      'Scan the parcel code, rather than a tracking-page link.',
      fields: {'barcode': 'Use the barcode or QR code on the parcel waybill.'},
    );
  }
  return code;
}

String parcelText(String value, String field, {int min = 1, int max = 500}) {
  final text = value.trim();
  if (text.runes.length < min ||
      text.runes.length > max ||
      RegExp(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f<>`{}]').hasMatch(text) ||
      !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) {
    throw AccountFailure(
      'Check the highlighted fields.',
      fields: {field: 'Use plain text between $min and $max characters.'},
    );
  }
  return text;
}

/// Exact server-compatible peso input, without floating-point arithmetic.
BigInt pesoInputCents(String value, {String field = 'cash_received'}) {
  if (!RegExp(r'^(?:0|[1-9][0-9]{0,8})(?:\.[0-9]{1,2})?$').hasMatch(value)) {
    throw AccountFailure(
      'Enter a peso amount with at most two decimal places.',
      fields: {field: 'Use an amount such as 125 or 125.50, without commas.'},
    );
  }
  final parts = value.split('.');
  return BigInt.parse(parts.first) * BigInt.from(100) +
      BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
}

const recipientRelationships = {
  'buyer': 'Buyer',
  'household': 'Household member',
  'authorized_recipient': 'Authorized recipient',
};

const failureReasonCodes = {
  'customer_unreachable',
  'customer_unavailable',
  'address_clarification',
  'unsafe_conditions',
  'cod_unavailable',
  'customer_refused',
};

enum ParcelAction {
  pickup,
  depart,
  deliver,
  fail;

  bool get requiresProof => this == deliver || this == fail;
  String get recordedStage => switch (this) {
    pickup => 'picked_up',
    depart => 'out_for_delivery',
    deliver => 'delivered',
    fail => 'delivery_failed',
  };
  String get label => switch (this) {
    pickup => 'Confirm collection',
    depart => 'Confirm departure',
    deliver => 'Record delivery',
    fail => 'Record failed attempt',
  };
}
