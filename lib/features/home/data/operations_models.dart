import '../../../core/network/wire.dart';

export '../../../core/network/wire.dart';

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
    handoverApiVersion =
        j['handover_api_version'] is int && j['handover_api_version'] == 1
        ? 1
        : null;
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
  late final int? handoverApiVersion;
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
    failurePolicy = j['failure_policy'] == null
        ? null
        : FailurePolicy.fromJson(Wire.object(j['failure_policy']));
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
  late final FailurePolicy? failurePolicy;
}

class FailurePolicy {
  FailurePolicy.fromJson(Map<String, dynamic> j)
    : attemptLimit = Wire.count(j['attempt_limit']),
      recordedAttempts = Wire.count(j['recorded_attempts']),
      returnHubId = Wire.id(j['return_hub_id']),
      retryAuthority = Wire.string(j['retry_authority']) {
    if (attemptLimit < 1 || j['reasons'] is! List) Wire.invalid();
    final labels = <String, String>{};
    for (final value in j['reasons'] as List) {
      final reason = Wire.object(value);
      final code = Wire.string(reason['code']);
      if (labels.containsKey(code)) Wire.invalid();
      labels[code] = Wire.string(reason['label']);
    }
    reasons = Map.unmodifiable(labels);
    for (final field in [
      'requires_notes',
      'requires_location',
      'requires_private_image',
    ]) {
      Wire.boolean(j[field]);
    }
  }
  final int attemptLimit, recordedAttempts;
  final String returnHubId, retryAuthority;
  late final Map<String, String> reasons;
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
