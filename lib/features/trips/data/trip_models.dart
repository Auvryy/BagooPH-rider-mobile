import '../../../core/network/api_failure.dart';
import '../../../core/network/wire.dart';
import '../../cash/data/rider_financial_models.dart';

String tripId(Object? value) {
  final text = Wire.string(value);
  if (!text.startsWith('trip-')) Wire.invalid();
  Wire.id(text.substring(5));
  return text;
}

String? privateTripProof(
  Object? value,
  String trip,
  String kind,
  String child,
) {
  if (value == null) return null;
  final path = Wire.string(value);
  if (path != '/api/v1/rider/trips/$trip/$kind/$child/proof') Wire.invalid();
  return path.substring('/api/v1/'.length);
}

BigInt? tripCents(Object? value) {
  if (value == null) return null;
  final text = Wire.string(value);
  final match = RegExp(r'^(?:0|[1-9][0-9]*)$').firstMatch(text);
  if (match == null || match.end != text.length) Wire.invalid();
  return BigInt.parse(text);
}

class RetainedCheckpoint {
  RetainedCheckpoint.fromJson(Map<String, dynamic> j, String trip)
    : id = Wire.id(j['id']),
      reference = Wire.string(j['reference']),
      kind = Wire.string(j['kind']),
      recordedAt = Wire.time(j['recorded_at']),
      waybillMatched = Wire.boolean(j['waybill_matched']),
      proofPath = privateTripProof(
        j['proof_url'],
        trip,
        'checkpoints',
        Wire.id(j['id']),
      );
  final String id, reference, kind;
  final DateTime recordedAt;
  final bool waybillMatched;
  final String? proofPath;
}

class RetainedAttempt {
  RetainedAttempt.fromJson(Map<String, dynamic> j, String trip)
    : id = Wire.id(j['id']),
      reference = Wire.string(j['reference']),
      number = Wire.count(j['number']),
      reason = Wire.string(j['reason']),
      recordedAt = Wire.time(j['recorded_at']),
      proofPath = privateTripProof(
        j['proof_url'],
        trip,
        'attempts',
        Wire.id(j['id']),
      ) {
    if (proofPath == null) Wire.invalid();
  }
  final String id, reference, reason;
  final int number;
  final DateTime recordedAt;
  final String? proofPath;
}

/// Retained original assignment facts, deliberately separate from current task
/// state and from later riders' outcomes. Null original facts remain null.
class RetainedTrip {
  RetainedTrip.fromJson(Map<String, dynamic> j)
    : id = tripId(j['id']),
      assignmentReference = Wire.string(j['assignment_reference']),
      deliveryId = Wire.id(j['delivery_id']),
      taskId = Wire.taskId(j['task_id']),
      phase = Wire.string(j['phase']),
      tracking = Wire.string(j['tracking_number']),
      order = Wire.string(j['order_number']),
      outcome = Wire.nullableString(j['outcome']),
      assignedAt = Wire.time(j['assignment_recorded_at']),
      lastRecordedAt = j['last_recorded_at'] == null
          ? null
          : Wire.time(j['last_recorded_at']),
      commercialStatus = Wire.string(j['commercial_status']),
      currentStage = Wire.string(j['current_operational_stage']),
      recipient = Wire.nullableString(j['recipient']),
      address = Wire.nullableString(j['address']),
      paymentMethod = Wire.string(j['payment_method']),
      collectedCents = tripCents(j['collected_cents']) {
    if (!['pickup', 'final_mile'].contains(phase) ||
        taskId != '$phase-$deliveryId') {
      Wire.invalid();
    }
    earnings = RiderEarnings.fromJson(j['earnings']);
    if (j['checkpoints'] is! List || j['attempts'] is! List) Wire.invalid();
    checkpoints = List.unmodifiable(
      (j['checkpoints'] as List).map(
        (row) => RetainedCheckpoint.fromJson(Wire.object(row), id),
      ),
    );
    attempts = List.unmodifiable(
      (j['attempts'] as List).map(
        (row) => RetainedAttempt.fromJson(Wire.object(row), id),
      ),
    );
    if (checkpoints.map((item) => item.id).toSet().length !=
            checkpoints.length ||
        attempts.map((item) => item.id).toSet().length != attempts.length) {
      Wire.invalid();
    }
  }
  final String id,
      assignmentReference,
      deliveryId,
      taskId,
      phase,
      tracking,
      order;
  final String commercialStatus, currentStage, paymentMethod;
  final String? outcome, recipient, address;
  final DateTime assignedAt;
  final DateTime? lastRecordedAt;
  final BigInt? collectedCents;
  late final RiderEarnings earnings;
  late final List<RetainedCheckpoint> checkpoints;
  late final List<RetainedAttempt> attempts;
  Set<String> get proofPaths => {
    ...checkpoints.map((row) => row.proofPath).whereType<String>(),
    ...attempts.map((row) => row.proofPath).whereType<String>(),
  };
}

class RetainedTripPage {
  RetainedTripPage.fromJson(Map<String, dynamic> j) {
    if (j['attribution'] != 'retained_assignment' ||
        j['date_basis'] != 'assignment_recorded_at' ||
        j['items'] is! List) {
      Wire.invalid();
    }
    final pagination = Wire.object(j['pagination']);
    page = Wire.count(pagination['page']);
    perPage = Wire.count(pagination['per_page']);
    total = Wire.count(pagination['total']);
    lastPage = Wire.count(pagination['last_page']);
    final rows = j['items'] as List;
    if (page < 1 ||
        page > 10000 ||
        perPage < 1 ||
        perPage > 50 ||
        lastPage < 1 ||
        rows.length > perPage) {
      Wire.invalid();
    }
    if (lastPage != (total == 0 ? 1 : (total + perPage - 1) ~/ perPage) ||
        (page > lastPage && rows.isNotEmpty)) {
      Wire.invalid();
    }
    final unique = <String, RetainedTrip>{};
    for (final row in rows) {
      final trip = RetainedTrip.fromJson(Wire.object(row));
      unique[trip.id] = trip;
    }
    items = List.unmodifiable(unique.values);
  }
  late final int page, perPage, total, lastPage;
  late final List<RetainedTrip> items;
  bool get hasNext => page < lastPage && page < 10000;
}

String assignmentDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class TripFilters {
  TripFilters({
    String search = '',
    this.phase,
    this.payment = 'all',
    this.from,
    this.to,
  }) : search = search.trim() {
    if (this.search.runes.length > 100 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(this.search) ||
        !['all', 'cod', 'prepaid'].contains(payment) ||
        (phase != null && !['pickup', 'final_mile'].contains(phase))) {
      throw const AccountFailure('Check the trip search and filters.');
    }
    for (final value in [from, to].whereType<DateTime>()) {
      if (value.year < 1 || value.year > 9999) {
        throw const AccountFailure('Choose a valid assignment date.');
      }
    }
    if (from != null &&
        to != null &&
        assignmentDate(from!).compareTo(assignmentDate(to!)) > 0) {
      throw const AccountFailure(
        'The start date must be on or before the end date.',
      );
    }
  }
  final String search, payment;
  final String? phase;
  final DateTime? from, to;
  Map<String, String> query(int page) {
    if (page < 1 || page > 10000) Wire.invalid();
    return {
      'page': '$page',
      'per_page': '20',
      if (search.isNotEmpty) 'q': search,
      'phase': ?phase,
      'payment': payment,
      if (from != null) 'from_date': assignmentDate(from!),
      if (to != null) 'to_date': assignmentDate(to!),
    };
  }
}

String tripOutcomeLabel(String? code) => switch (code) {
  'assigned_pickup' => 'Pickup assigned',
  'assigned_to_rider' => 'Delivery assigned',
  'picked_up' => 'Collected',
  'arrived_at_origin_hub' => 'Received at origin hub',
  'out_for_delivery' => 'Out for delivery',
  'delivery_failed' => 'Failed attempt',
  'delivered' => 'Delivered',
  null => 'No outcome recorded',
  _ => 'Unrecognized recorded state',
};
