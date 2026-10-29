import '../network/api_failure.dart';
import '../network/wire.dart';
import 'message_validation.dart';

const companyCommandActions = {
  'company.submit',
  'company.accepted',
  'company.declined',
  'company.withdrawn',
};

String companyCounter(Object? value) =>
    Wire.id(value is int ? '$value' : value);

String? companyNote(String? value, {String field = 'note'}) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    if (value.runes.length > 500) throw const FormatException();
    final text = messageText(value);
    if (text.runes.length < 5 || text.runes.length > 500) {
      throw const FormatException();
    }
    return text;
  } catch (_) {
    throw AccountFailure(
      'Check the highlighted fields.',
      fields: {
        field: 'Use 5–500 characters of plain text, or leave this blank.',
      },
    );
  }
}

String companyResourceId(String action, String resource) {
  final prefix = action == 'company.submit' ? 'company-' : 'company-request-';
  if (!companyCommandActions.contains(action) || !resource.startsWith(prefix)) {
    Wire.invalid();
  }
  return Wire.id(resource.substring(prefix.length));
}

void companyIntentFields(
  String action,
  String resource,
  Map<String, dynamic> body,
) {
  final id = companyResourceId(action, resource);
  final Set<String> required;
  final Set<String> allowed;
  if (action == 'company.submit') {
    required = {'company_id', 'intake_version', 'sharing_acknowledged'};
    allowed = {...required, 'note'};
    if (companyCounter(body['company_id']) != id ||
        body['sharing_acknowledged'] != true) {
      Wire.invalid();
    }
    companyCounter(body['intake_version']);
  } else {
    companyCounter(body['expected_version']);
    if (action == 'company.accepted') {
      required = {'expected_version', 'offer_id', 'terms_hash', 'acknowledged'};
      allowed = required;
      Wire.id(body['offer_id']);
      Wire.version(body['terms_hash']);
      if (body['acknowledged'] != true) Wire.invalid();
    } else {
      required = {'expected_version'};
      allowed = {...required, 'reason'};
    }
  }
  if (!body.keys.toSet().containsAll(required) ||
      !allowed.containsAll(body.keys)) {
    Wire.invalid();
  }
  for (final key in ['note', 'reason']) {
    if (body.containsKey(key) &&
        body[key] != null &&
        companyNote(Wire.string(body[key]), field: key) != body[key]) {
      Wire.invalid();
    }
  }
}
