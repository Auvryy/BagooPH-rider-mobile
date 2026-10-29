import '../../../core/commands/command_intent.dart';
import '../../../core/commands/company_validation.dart';
import '../../../core/network/wire.dart';

export '../../../core/commands/company_validation.dart';

DateTime companyTime(Object? value) {
  final text = Wire.string(value);
  if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.(?:\d{3}|\d{6})Z$')
          .firstMatch(text)
          ?.end !=
      text.length) {
    Wire.invalid();
  }
  final time = DateTime.tryParse(text);
  if (time == null ||
      time.toIso8601String().substring(0, 19) != text.substring(0, 19)) {
    Wire.invalid();
  }
  return time;
}

class RiderCompany {
  RiderCompany.fromJson(Map<String, dynamic> json)
    : id = Wire.id(json['id']),
      name = Wire.string(json['name']),
      intakeVersion = companyCounter(json['intake_version']),
      areasTruncated = Wire.boolean(json['areas_truncated']) {
    if (json['areas'] is! List || (json['areas'] as List).length > 50) {
      Wire.invalid();
    }
    areas = List.unmodifiable(
      (json['areas'] as List).map((value) {
        final area = Wire.object(value);
        return [
          Wire.nullableString(area['city']),
          Wire.nullableString(area['province']),
        ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', ');
      }),
    );
  }
  final String id, name, intakeVersion;
  final bool areasTruncated;
  late final List<String> areas;
}

class CompanyPage<T> {
  CompanyPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decode,
    String Function(T) id,
  ) {
    if (json['items'] is! List) Wire.invalid();
    items = List.unmodifiable(
      (json['items'] as List).map((row) => decode(Wire.object(row))),
    );
    final p = Wire.object(json['pagination']);
    page = Wire.count(p['page']);
    perPage = Wire.count(p['per_page']);
    total = Wire.count(p['total']);
    lastPage = Wire.count(p['last_page']);
    if (page < 1 ||
        page > 10000 ||
        perPage < 1 ||
        perPage > 50 ||
        lastPage < 1 ||
        lastPage != (total == 0 ? 1 : (total + perPage - 1) ~/ perPage) ||
        items.length > perPage ||
        items.length > total ||
        items.map(id).toSet().length != items.length) {
      Wire.invalid();
    }
  }
  late final List<T> items;
  late final int page, perPage, total, lastPage;
  bool get hasMore => page < lastPage && page < 10000;
}

class CompanyOffer {
  CompanyOffer.fromJson(Map<String, dynamic> json)
    : id = Wire.id(json['id']),
      reference = Wire.string(json['reference']),
      version = companyCounter(json['version']),
      hubId = Wire.id(json['hub_id']),
      vehicleId = json['vehicle_id'] == null
          ? null
          : Wire.id(json['vehicle_id']),
      barangay = Wire.nullableString(json['barangay']),
      terms = Wire.string(json['terms']),
      termsHash = Wire.version(json['terms_hash']),
      issuedAt = companyTime(json['issued_at']),
      expiresAt = companyTime(json['expires_at']) {
    final assignment = Wire.object(json['assignment']);
    company = Wire.string(assignment['company']);
    hub = Wire.string(assignment['hub']);
    hubCode = Wire.nullableString(assignment['hub_code']);
    vehicle = Wire.string(assignment['vehicle']);
  }
  final String id, reference, version, hubId, terms, termsHash;
  final String? vehicleId, barangay;
  final DateTime issuedAt, expiresAt;
  late final String company, hub, vehicle;
  late final String? hubCode;
}

class CompanyDecision {
  CompanyDecision.fromJson(Map<String, dynamic> json)
    : action = Wire.string(json['action']),
      reason = Wire.nullableString(json['reason']),
      at = companyTime(json['at']);
  final String action;
  final String? reason;
  final DateTime at;
}

class CompanyApplication {
  CompanyApplication.fromJson(Map<String, dynamic> json) {
    id = Wire.id(json['id']);
    reference = Wire.string(json['reference']);
    final company = Wire.object(json['company']);
    companyId = Wire.id(company['id']);
    companyName = Wire.string(company['name']);
    status = Wire.string(json['status']);
    effectiveStatus = Wire.string(json['effective_status']);
    version = companyCounter(json['version']);
    submittedAt = companyTime(json['submitted_at']);
    final actions = Wire.flags(json['actions']);
    offer = json['offer'] == null
        ? null
        : CompanyOffer.fromJson(Wire.object(json['offer']));
    canAccept =
        actions['accept'] == true &&
        effectiveStatus == 'offered' &&
        offer != null;
    canDecline =
        actions['decline'] == true &&
        effectiveStatus == 'offered' &&
        offer != null;
    canWithdraw =
        actions['withdraw'] == true &&
        ['pending', 'offered'].contains(effectiveStatus);
    if (offer != null && json['current_offer_id'] != offer!.id) Wire.invalid();
    offers = _history(json['offers'], CompanyOffer.fromJson);
    decisions = _history(json['decisions'], CompanyDecision.fromJson);
    final limits = json['history_limits'];
    historyTruncated =
        limits is Map &&
        (limits['offers_truncated'] == true ||
            limits['decisions_truncated'] == true);
  }
  static List<T> _history<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value == null) return const [];
    if (value is! List || value.length > 50) Wire.invalid();
    return List.unmodifiable(value.map((row) => decode(Wire.object(row))));
  }

  late final String id,
      reference,
      companyId,
      companyName,
      status,
      effectiveStatus,
      version;
  late final DateTime submittedAt;
  late final CompanyOffer? offer;
  late final bool canAccept, canDecline, canWithdraw, historyTruncated;
  late final List<CompanyOffer> offers;
  late final List<CompanyDecision> decisions;
}

class CompanyAssignment {
  CompanyAssignment.fromJson(Map<String, dynamic> json) {
    final company = json['company'] == null
        ? null
        : Wire.object(json['company']);
    final hub = json['hub'] == null ? null : Wire.object(json['hub']);
    companyId = company == null ? null : Wire.id(company['id']);
    companyName = company == null ? null : Wire.string(company['name']);
    hubName = hub == null ? null : Wire.string(hub['name']);
    vehicle = Wire.string(Wire.object(json['vehicle'])['label']);
    barangay = Wire.nullableString(json['barangay']);
    onDuty = Wire.boolean(json['on_duty']);
    operational = Wire.boolean(Wire.object(json['eligibility'])['operational']);
    canApply = Wire.boolean(Wire.object(json['actions'])['apply']);
    if (canApply && companyId != null) Wire.invalid();
    blockedReason = Wire.nullableString(json['blocked_reason']);
    provenance = Wire.string(Wire.object(json['provenance'])['kind']);
    final sharing = Wire.object(json['sharing_summary']);
    sharedProfile = Map.unmodifiable({
      for (final field in [
        'name',
        'email',
        'phone',
        'city',
        'province',
        'vehicle_type',
        'approval_status',
      ])
        field: Wire.nullableString(sharing[field]),
    });
    observedAt = Wire.time(json['observed_at']);
  }
  late final String? companyId, companyName, hubName, barangay, blockedReason;
  late final String vehicle, provenance;
  late final bool onDuty, operational, canApply;
  late final Map<String, String?> sharedProfile;
  late final DateTime observedAt;
}

class CompanyCommandReceipt {
  CompanyCommandReceipt.fromJson(
    Map<String, dynamic> json,
    CommandIntent intent,
  ) {
    if (Wire.uuid(json['idempotency_key']) != intent.key ||
        json['action'] != intent.action ||
        json['resource'] != intent.resource ||
        json['state'] != 'committed') {
      Wire.invalid();
    }
    final result = Wire.object(json['result']);
    applicationId = Wire.id(result['id']);
    reference = Wire.string(result['reference']);
    status = Wire.string(result['status']);
    version = companyCounter(result['version']);
    final expected = switch (intent.action) {
      'company.submit' => 'pending',
      'company.accepted' => 'accepted',
      'company.declined' => 'declined',
      'company.withdrawn' => 'withdrawn',
      _ => null,
    };
    if (status != expected ||
        intent.action != 'company.submit' &&
            companyResourceId(intent.action, intent.resource) !=
                applicationId) {
      Wire.invalid();
    }
    if (intent.action == 'company.accepted' &&
        result['offer_id'] != intent.body['offer_id']) {
      Wire.invalid();
    }
    recordedAt = Wire.time(json['recorded_at']);
    expiresAt = Wire.time(json['expires_at']);
    retryExpired = Wire.boolean(json['retry_expired']);
    replayed = Wire.boolean(json['replayed']);
  }
  late final String applicationId, reference, status, version;
  late final DateTime recordedAt, expiresAt;
  late final bool retryExpired, replayed;
}
