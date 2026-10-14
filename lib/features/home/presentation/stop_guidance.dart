import '../data/operations_models.dart';

String custodyLabel(OperationTask task) => switch (task.custodyKind) {
  'seller' => 'Recorded custody: seller',
  'hub' =>
    task.custodyHubId == null
        ? 'Recorded custody: hub · hub ID unavailable'
        : 'Recorded custody: hub ${task.custodyHubId}',
  'courier' =>
    task.heldByMe
        ? 'Recorded custody: you'
        : 'Recorded custody: another courier',
  'buyer' => 'Recorded custody: buyer',
  _ => 'Recorded custody: unknown',
};

String nextActorLabel(OperationTask task) {
  if (task.actionDenials['handover'] == 'HANDOVER_HOLD') {
    return 'Logistics company · reviewed handover recovery';
  }
  if (task.actionDenials['handover'] != null) {
    return 'Check the current instruction';
  }
  if (task.preview) return 'Eligible rider · claim before collection';
  return switch ((task.stop.kind, task.stage)) {
    ('seller', 'assigned' || 'assigned_pickup') => 'You · pickup rider',
    ('origin_hub', 'picked_up') => 'You, then the origin hub handler',
    ('destination_hub', 'assigned_to_rider') => 'You · assigned delivery rider',
    ('destination_hub', 'delivery_failed') =>
      'You, then the destination hub handler',
    ('buyer', 'out_for_delivery') => 'You · assigned delivery rider',
    ('buyer', 'delivered') => 'Buyer · confirms receipt separately',
    _ => 'Check the current instruction',
  };
}

String legGuide(OperationTask task) => task.phase == 'pickup'
    ? 'Pickup leg: seller → origin hub. The hub confirms intake.'
    : task.stage == 'delivery_failed'
    ? 'Return leg: bring the parcel to the destination hub. The hub records receipt and decides any retry.'
    : 'Delivery leg: destination hub → buyer. The buyer confirms receipt separately.';

/// Compare the destination and authority the rider actually reviewed, rather
/// than a timestamp or an opaque version that may change for unrelated reasons.
bool sameReviewedStop(OperationTask a, OperationTask b) =>
    a.id == b.id &&
    a.tracking == b.tracking &&
    a.order == b.order &&
    a.preview == b.preview &&
    a.assignmentReference == b.assignmentReference &&
    a.stage == b.stage &&
    a.custodyKind == b.custodyKind &&
    a.custodyHubId == b.custodyHubId &&
    a.heldByMe == b.heldByMe &&
    a.nextInstruction == b.nextInstruction &&
    a.actionDenials['handover'] == b.actionDenials['handover'] &&
    a.stop.kind == b.stop.kind &&
    a.stop.name == b.stop.name &&
    a.stop.address == b.stop.address &&
    a.stop.phone == b.stop.phone &&
    a.stop.instructions == b.stop.instructions &&
    a.stop.latitude == b.stop.latitude &&
    a.stop.longitude == b.stop.longitude;
