import '../../home/data/operations_models.dart';

int handoverVersion(Object? value) {
  if (value is! int || value < 1 || value > 1000000) Wire.invalid();
  return value;
}

String handoverStateLabel(String state) => switch (state) {
  'pending_review' => 'Pending review',
  'needs_recovery' => 'Recovery required',
  'recovered' => 'Received and recovered',
  'dismissed' => 'Dismissed',
  _ => 'State unavailable',
};

class HandoverSummary {
  HandoverSummary.fromJson(Map<String, dynamic> j)
    : id = Wire.id(j['id']),
      reference = Wire.string(j['reference']),
      tracking = Wire.string(j['tracking_number']),
      state = Wire.string(j['state']),
      kind = Wire.string(j['kind']),
      version = handoverVersion(j['version']),
      held = Wire.boolean(j['held']),
      createdAt = Wire.time(j['created_at']) {
    if (![
          'pending_review',
          'needs_recovery',
          'dismissed',
          'recovered',
        ].contains(state) ||
        !['missed_ready', 'missed_scan'].contains(kind)) {
      Wire.invalid();
    }
  }
  final String id, reference, tracking, state, kind;
  final int version;
  final bool held;
  final DateTime createdAt;
}

class HandoverPage {
  HandoverPage.fromJson(Map<String, dynamic> j) {
    final rows = j['items'];
    if (rows is! List) Wire.invalid();
    items = List.unmodifiable(
      rows.map((v) => HandoverSummary.fromJson(Wire.object(v))),
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
  late final List<HandoverSummary> items;
  late final int page, perPage, total, lastPage;
  bool get hasNext => page < lastPage && page < 10000;
}

class HandoverSnapshot {
  HandoverSnapshot.fromJson(Map<String, dynamic> j)
    : status = Wire.nullableString(j['commercial_status']),
      stage = Wire.nullableString(j['operational_stage']),
      custodyKind = Wire.string(j['custody_kind']),
      custodyLabel = Wire.string(j['custody_label']);
  final String? status, stage;
  final String custodyKind, custodyLabel;
}

class HandoverRecovery {
  HandoverRecovery.fromJson(Map<String, dynamic> j)
    : id = Wire.id(j['id']),
      reference = Wire.string(j['reference']),
      mode = Wire.string(j['mode']),
      holderIsMe = Wire.boolean(j['holder_is_me']),
      expiresAt = Wire.time(j['expires_at']),
      acknowledged = Wire.boolean(j['acknowledged']),
      closed = Wire.boolean(j['closed']),
      blocker = Wire.nullableString(j['blocker']),
      version = handoverVersion(j['expected_version']),
      sourceToken = j['source_token'] == null
          ? null
          : Wire.version(j['source_token']),
      manifestReference = Wire.nullableString(j['manifest_reference']),
      linkedReference = Wire.nullableString(j['linked_recovery_reference']),
      acknowledge = Wire.boolean(Wire.object(j['actions'])['acknowledge']) {
    final hub = Wire.object(j['receiving_hub']);
    hubId = Wire.id(hub['id']);
    hubName = Wire.string(hub['name']);
    hubAddress = Wire.nullableString(hub['address']);
    if (![
          'pickup',
          'departure',
          'hub_intake',
          'hub_manifest',
          'hub_failed_return',
          'hub_existing',
        ].contains(mode) ||
        (!holderIsMe && (sourceToken != null || acknowledge))) {
      Wire.invalid();
    }
  }
  final String id, reference, mode;
  late final String hubId, hubName;
  late final String? hubAddress;
  final String? blocker, sourceToken, manifestReference, linkedReference;
  final int version;
  final bool holderIsMe, acknowledged, closed, acknowledge;
  final DateTime expiresAt;
  bool canAcknowledge(DateTime now) =>
      holderIsMe &&
      acknowledge &&
      !acknowledged &&
      !closed &&
      blocker == null &&
      sourceToken != null &&
      expiresAt.isAfter(now.toUtc());
  bool sameAuthority(HandoverRecovery other) =>
      id == other.id &&
      version == other.version &&
      sourceToken == other.sourceToken &&
      mode == other.mode &&
      hubId == other.hubId;
}

class HandoverEvent {
  HandoverEvent.fromJson(Map<String, dynamic> j)
    : id = Wire.id(j['id']),
      type = Wire.string(j['type']),
      role = Wire.string(j['actor_role']),
      notes = Wire.string(j['notes']),
      at = Wire.time(j['recorded_at']);
  final String id, type, role, notes;
  final DateTime at;
}

class HandoverDetail extends HandoverSummary {
  HandoverDetail.fromJson(Map<String, dynamic> j) : super.fromJson(j) {
    final reported = Wire.object(j['reported']);
    reportedHolder = Wire.string(reported['holder']);
    reportedLocation = Wire.string(reported['location']);
    notes = Wire.string(reported['notes']);
    final recorded = Wire.object(j['recorded']);
    original = HandoverSnapshot.fromJson(Wire.object(recorded['original']));
    current = HandoverSnapshot.fromJson(Wire.object(recorded['current']));
    final evidence = Wire.object(j['evidence']);
    evidencePath = Wire.string(evidence['download_path']);
    mime = Wire.string(evidence['mime_type']);
    if (evidencePath != '/api/v1/rider/handover-issues/$id/evidence' ||
        ![
          'image/jpeg',
          'image/png',
          'image/webp',
          'application/pdf',
        ].contains(mime)) {
      Wire.invalid();
    }
    recovery = j['recovery'] == null
        ? null
        : HandoverRecovery.fromJson(Wire.object(j['recovery']));
    final events = j['history'];
    if (events is! List) Wire.invalid();
    history = List.unmodifiable(
      events.map((v) => HandoverEvent.fromJson(Wire.object(v))),
    );
  }
  late final String reportedHolder, reportedLocation, notes, evidencePath, mime;
  late final HandoverSnapshot original, current;
  late final HandoverRecovery? recovery;
  late final List<HandoverEvent> history;
}
