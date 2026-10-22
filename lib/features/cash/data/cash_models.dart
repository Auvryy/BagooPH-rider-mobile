import '../../../core/commands/cash_validation.dart';
import '../../../core/network/wire.dart';

export '../../../core/commands/cash_validation.dart';

List<T> _rows<T>(Object? value, T Function(Map<String, dynamic>) decode) {
  if (value is! List) Wire.invalid();
  return List.unmodifiable(value.map((row) => decode(Wire.object(row))));
}

void _earnings(Object? value) {
  final data = Wire.object(value);
  if (data['available'] != false || data['confirmed_cents'] != null) {
    Wire.invalid();
  }
}

class CashPerson {
  CashPerson.fromJson(Map<String, dynamic> j)
    : id = Wire.id(j['id']),
      name = Wire.string(j['name']);
  final String id, name;
}

class CashHolder {
  CashHolder.fromJson(Map<String, dynamic> j)
    : id = Wire.id(j['user_id']),
      name = Wire.string(j['name']),
      stage = Wire.string(j['stage']),
      cents = cashCents(j['amount_cents']),
      restricted = Wire.boolean(j['restricted']);
  final String id, name, stage;
  final BigInt cents;
  final bool restricted;
}

class CashPending {
  CashPending.fromJson(Map<String, dynamic> j)
    : reference = Wire.string(j['reference']),
      cents = cashCents(j['amount_cents']),
      holderId = Wire.id(j['holder_id']),
      recipientId = Wire.id(j['recipient_id']),
      holderName = Wire.string(j['holder_name']),
      recipientName = Wire.string(j['recipient_name']);
  final String reference, holderId, recipientId, holderName, recipientName;
  final BigInt cents;
}

class CashEvent {
  CashEvent.fromJson(Map<String, dynamic> j)
    : reference = Wire.string(j['reference']),
      sequence = Wire.id(j['sequence']),
      kind = Wire.string(j['event_type']),
      actorRole = Wire.string(j['actor_role']),
      actorName = Wire.string(j['actor_name']),
      fromStage = Wire.nullableString(j['from_stage']),
      toStage = Wire.nullableString(j['to_stage']),
      provenance = Wire.nullableString(j['provenance']),
      evidence = Wire.nullableString(j['evidence_reference']),
      reason = Wire.nullableString(j['reason']),
      source = Wire.nullableString(j['source_reference']),
      recordedAt = Wire.time(j['recorded_at']),
      amount = _money(j['amount_cents'], signed: true),
      expected = _money(j['expected_cents']),
      received = _money(j['received_cents']),
      discrepancy = _money(j['discrepancy_cents'], signed: true),
      fromId = j['from_user_id'] == null ? null : Wire.id(j['from_user_id']),
      toId = j['to_user_id'] == null ? null : Wire.id(j['to_user_id']);
  static BigInt? _money(Object? v, {bool signed = false}) =>
      v == null ? null : cashCents(v, signed: signed);
  final String reference, sequence, kind, actorRole, actorName;
  final String? fromStage,
      toStage,
      provenance,
      evidence,
      reason,
      source,
      fromId,
      toId;
  final DateTime recordedAt;
  final BigInt? amount, expected, received, discrepancy;
}

class CashDifference {
  CashDifference.fromJson(Map<String, dynamic> j)
    : source = Wire.string(j['source_reference']),
      cents = cashCents(j['difference_cents'], signed: true),
      holderId = Wire.id(j['holder_id']),
      resolvedBy = Wire.nullableString(j['resolved_by']);
  final String source, holderId;
  final String? resolvedBy;
  final BigInt cents;
}

class CashAccount {
  CashAccount.fromJson(Map<String, dynamic> j, {bool detail = false})
    : id = Wire.id(j['id']),
      reference = Wire.string(j['reference']),
      deliveryId = Wire.id(j['delivery_id']),
      tracking = Wire.string(j['tracking_number']),
      order = Wire.string(j['order_number']),
      sourceKind = Wire.string(j['source_kind']),
      status = Wire.string(j['status']),
      version = Wire.id(j['version']),
      sourceEvent = Wire.string(j['source_event_reference']),
      hub = Wire.string(j['hub_name']),
      company = Wire.string(j['company_name']),
      held = cashCents(j['own_held_cents']),
      remitted = cashCents(j['own_remitted_cents']),
      expected = cashCents(j['expected_cents']),
      subtotal = cashCents(j['product_subtotal_cents']),
      discount = cashCents(j['discount_cents']),
      shipping = cashCents(j['shipping_cents']),
      collected = cashCents(j['collected_cents']),
      reconciled = cashCents(j['reconciled_cents']),
      excess = cashCents(j['excess_cents']),
      recordedAt = Wire.time(j['recorded_at']),
      canOffer = Wire.boolean(j['can_offer']),
      pending = j['pending_handover'] == null
          ? null
          : CashPending.fromJson(Wire.object(j['pending_handover'])),
      holders = _rows(j['holders'], CashHolder.fromJson),
      recipients = detail
          ? _rows(j['recipients'], CashPerson.fromJson)
          : const [],
      history = detail ? _rows(j['history'], CashEvent.fromJson) : const [],
      discrepancies = detail
          ? _rows(j['discrepancies'], CashDifference.fromJson)
          : const [],
      isDetail = detail {
    _earnings(j['earnings']);
    if (j['can_receive'] != false ||
        j['can_reconcile'] != false ||
        (canOffer &&
            (pending != null ||
                held <= BigInt.zero ||
                status == 'reconciled')) ||
        recipients.map((r) => r.id).toSet().length != recipients.length ||
        history.map((r) => r.sequence).toSet().length != history.length) {
      Wire.invalid();
    }
  }
  final String id,
      reference,
      deliveryId,
      tracking,
      order,
      sourceKind,
      status,
      version,
      sourceEvent,
      hub,
      company;
  final BigInt held,
      remitted,
      expected,
      subtotal,
      discount,
      shipping,
      collected,
      reconciled,
      excess;
  final DateTime recordedAt;
  final bool canOffer, isDetail;
  final CashPending? pending;
  final List<CashHolder> holders;
  final List<CashPerson> recipients;
  final List<CashEvent> history;
  final List<CashDifference> discrepancies;
  bool sameOfferTerms(CashAccount other) =>
      id == other.id &&
      version == other.version &&
      held == other.held &&
      canOffer == other.canOffer &&
      pending?.reference == other.pending?.reference &&
      recipients.length == other.recipients.length &&
      recipients.every(
        (r) => other.recipients.any((x) => x.id == r.id && x.name == r.name),
      );
}

class CashPage {
  CashPage.fromJson(Map<String, dynamic> j)
    : items = _rows(j['items'], CashAccount.fromJson) {
    final summary = Wire.object(j['summary']);
    if (summary['basis'] != 'all_owned_cash_journals') Wire.invalid();
    held = cashCents(summary['own_held_cents']);
    unresolved = Wire.count(summary['accounts_with_unresolved_difference']);
    _earnings(j['earnings']);
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
        lastPage != (total == 0 ? 1 : (total + perPage - 1) ~/ perPage) ||
        items.length > perPage ||
        items.length > total ||
        items.map((r) => r.id).toSet().length != items.length) {
      Wire.invalid();
    }
  }
  final List<CashAccount> items;
  late final BigInt held;
  late final int unresolved, page, perPage, total, lastPage;
  bool get hasMore => page < lastPage && page < 10000;
}
