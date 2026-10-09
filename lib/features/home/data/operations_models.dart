/// Accepted Rider operations v1 wire values. IDs and money never pass through
/// floating point; unfamiliar state codes remain server text.
class Wire {
  static Never invalid() =>
      throw const FormatException('The work response could not be verified.');
  static Map<String, dynamic> object(Object? v) =>
      v is Map<String, dynamic> ? v : invalid();
  static String string(Object? v) => v is String ? v : invalid();
  static String? nullableString(Object? v) => v == null ? null : string(v);
  static bool boolean(Object? v) => v is bool ? v : invalid();
  static int count(Object? v) => v is int && v >= 0 ? v : invalid();
  static String id(Object? v) {
    final s = string(v);
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(s) ||
        s.length > 19 ||
        BigInt.parse(s) > BigInt.parse('9223372036854775807')) {
      invalid();
    }
    return s;
  }

  static String version(Object? v) {
    final s = string(v);
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(s)) invalid();
    return s;
  }

  static String uuid(Object? v) {
    final s = string(v);
    if (!RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$').hasMatch(s)) {
      invalid();
    }
    return s;
  }

  static DateTime time(Object? v) {
    final s = string(v);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$').hasMatch(s)) {
      invalid();
    }
    final parsed = DateTime.tryParse(s);
    if (parsed == null || parsed.toIso8601String() != s) invalid();
    return parsed;
  }

  static String taskId(Object? v) {
    final s = string(v);
    final m = RegExp(r'^(pickup|final_mile)-([1-9][0-9]*)$').firstMatch(s);
    if (m == null) invalid();
    id(m[2]);
    return s;
  }

  static Map<String, bool> flags(Object? v) =>
      Map.unmodifiable(object(v).map((k, v) => MapEntry(k, boolean(v))));
  static Map<String, int> counts(Object? v) =>
      Map.unmodifiable(object(v).map((k, v) => MapEntry(k, count(v))));
}

class OperationsHome {
  OperationsHome.fromJson(Map<String, dynamic> j)
    : accountId = Wire.id(j['account_id']),
      onDuty = Wire.boolean(j['on_duty']),
      observedAt = Wire.time(j['observed_at']),
      capabilities = Wire.flags(j['capabilities']),
      counts = Wire.counts(j['counts']),
      capacity = Wire.counts(j['capacity']),
      limits = Wire.counts(j['limits']) {
    if (j['operations_api_version'] != 1) Wire.invalid();
    final placement = Wire.object(j['placement']);
    companyId = placement['company_id'] == null
        ? null
        : Wire.id(placement['company_id']);
    hubId = placement['hub_id'] == null ? null : Wire.id(placement['hub_id']);
    company = Wire.nullableString(placement['company_name']);
    hub = Wire.nullableString(placement['hub_name']);
    barangay = Wire.nullableString(placement['barangay']);
    final eligibility = Wire.object(j['eligibility']);
    operational = Wire.boolean(eligibility['operational']);
    canClaim = Wire.boolean(eligibility['can_claim']);
    claimDenial = Wire.nullableString(eligibility['claim_denial']);
    for (final k in ['home', 'duty', 'pickup_claim']) {
      if (!capabilities.containsKey(k)) Wire.invalid();
    }
    for (final k in ['available', 'pickup', 'final_mile']) {
      if (!counts.containsKey(k)) Wire.invalid();
    }
    for (final k in ['active_pickups', 'pickup_limit', 'remaining_pickups']) {
      if (!capacity.containsKey(k)) Wire.invalid();
    }
    for (final k in [
      'per_page_max',
      'poll_interval_seconds',
      'request_budget_per_minute',
      'idempotency_days',
    ]) {
      if (!limits.containsKey(k)) Wire.invalid();
    }
  }
  final String accountId;
  final bool onDuty;
  final DateTime observedAt;
  late final String? companyId, hubId, company, hub, barangay, claimDenial;
  late final bool operational, canClaim;
  final Map<String, bool> capabilities;
  final Map<String, int> counts, capacity, limits;
}

class TaskStop {
  TaskStop.fromJson(Map<String, dynamic> j)
    : kind = Wire.string(j['kind']),
      name = Wire.nullableString(j['name']),
      address = Wire.nullableString(j['address']),
      phone = Wire.nullableString(j['phone']),
      instructions = Wire.nullableString(j['instructions']) {
    if (!['seller', 'origin_hub', 'destination_hub', 'buyer'].contains(kind)) {
      Wire.invalid();
    }
    // Invalid coordinates are an address-first fallback, never an invented pin.
    final lat = j['latitude'], lon = j['longitude'];
    if (lat is num &&
        lon is num &&
        lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180) {
      latitude = lat.toDouble();
      longitude = lon.toDouble();
    } else {
      latitude = null;
      longitude = null;
    }
  }
  final String kind;
  final String? name, address, phone, instructions;
  late final double? latitude, longitude;
}

class OperationTask {
  OperationTask.fromJson(Map<String, dynamic> j)
    : id = Wire.taskId(j['id']),
      deliveryId = Wire.id(j['delivery_id']),
      phase = Wire.string(j['phase']),
      preview = Wire.boolean(j['preview']),
      assignmentReference = Wire.nullableString(j['assignment_reference']),
      tracking = Wire.string(j['tracking_number']),
      order = Wire.string(j['order_number']),
      commercialStatus = Wire.string(j['commercial_status']),
      stage = Wire.string(j['operational_stage']),
      version = Wire.version(j['version']),
      observedAt = Wire.time(j['observed_at']),
      stop = TaskStop.fromJson(Wire.object(j['stop'])),
      actions = Wire.flags(j['actions']),
      nextInstruction = Wire.string(j['next_instruction']) {
    if (!['pickup', 'final_mile'].contains(phase) ||
        id != '$phase-$deliveryId') {
      Wire.invalid();
    }
    final custody = Wire.object(j['custody']);
    custodyKind = Wire.string(custody['kind']);
    heldByMe = Wire.boolean(custody['held_by_me']);
    custodyHubId = custody['hub_id'] == null
        ? null
        : Wire.id(custody['hub_id']);
    actionDenials = Map.unmodifiable(
      Wire.object(j['action_denials'])
          .map((k, v) => MapEntry(k, Wire.nullableString(v))),
    );
    for (final k in [
      'claim',
      'pickup',
      'depart',
      'deliver',
      'fail',
      'release',
    ]) {
      if (!actions.containsKey(k)) Wire.invalid();
    }
    final payment = j['payment'];
    if (payment != null) {
      final p = Wire.object(payment);
      paymentMethod = Wire.string(p['method']);
      paymentStatus = Wire.string(p['commercial_payment_status']);
      final cents = p['cod_due_cents'];
      if (cents != null) {
        final s = Wire.string(cents);
        if (!RegExp(r'^(?:0|[1-9][0-9]*)$').hasMatch(s)) Wire.invalid();
        codDueCents = BigInt.parse(s);
      } else {
        codDueCents = null;
      }
    } else {
      paymentMethod = null;
      paymentStatus = null;
      codDueCents = null;
    }
    if (preview &&
        (phase != 'pickup' ||
            stop.kind != 'seller' ||
            payment != null ||
            stop.phone != null ||
            stop.instructions != null ||
            heldByMe)) {
      Wire.invalid();
    }
  }
  final String id,
      deliveryId,
      phase,
      tracking,
      order,
      commercialStatus,
      stage,
      version,
      nextInstruction;
  final String? assignmentReference;
  final bool preview;
  final DateTime observedAt;
  final TaskStop stop;
  final Map<String, bool> actions;
  late final Map<String, String?> actionDenials;
  late final String custodyKind;
  late final String? custodyHubId, paymentMethod, paymentStatus;
  late final bool heldByMe;
  late final BigInt? codDueCents;
}

class TaskPage {
  TaskPage.fromJson(Map<String, dynamic> j) {
    final rows = j['items'];
    if (rows is! List) Wire.invalid();
    items = List.unmodifiable(
      rows.map((v) => OperationTask.fromJson(Wire.object(v))),
    );
    final p = Wire.object(j['pagination']);
    page = Wire.count(p['page']);
    perPage = Wire.count(p['per_page']);
    total = Wire.count(p['total']);
    lastPage = Wire.count(p['last_page']);
    if (page < 1 ||
        page > 10000 ||
        perPage < 1 ||
        perPage > 50 ||
        lastPage < 1 ||
        items.length > perPage) {
      Wire.invalid();
    }
  }
  late final List<OperationTask> items;
  late final int page, perPage, total, lastPage;
  bool get hasNext => page < lastPage && page < 10000;
}

String exactPesos(BigInt cents) {
  final whole = (cents ~/ BigInt.from(100)).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '₱$whole.${(cents % BigInt.from(100)).toString().padLeft(2, '0')}';
}
