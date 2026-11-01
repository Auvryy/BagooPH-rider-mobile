import '../data/operations_models.dart';

/// The committed order status is independent from the parcel checkpoint and
/// from a hub's receipt of collected COD. Never infer a flow version here.
String deliveryRecordedNotice(Object? commercialStatus) =>
    switch (commercialStatus) {
      'completed' => 'Delivery verified and order completed. Any collected COD still needs a separate hub receipt. Review recorded earnings in Trips or Cash.',
      'delivered' => 'Delivery recorded with order status Delivered. Refresh Trips for the latest completion status. Any collected COD still needs a separate hub receipt.',
      _ => 'Delivery recorded. Refresh Trips to check the order status. Any collected COD still needs a separate hub receipt.',
    };

String taskInstruction(OperationTask task) {
  if (task.preview || task.actionDenials['handover'] != null) {
    return task.nextInstruction;
  }
  if (task.phase == 'final_mile' && task.stage == 'delivered') {
    return deliveryRecordedNotice(task.commercialStatus);
  }
  // The deployed v1 envelope serves version-two orders too. Retain the actual
  // server instruction while correcting this older unconditional completion copy.
  return task.nextInstruction.replaceAll(
    'The buyer confirms receipt separately.',
    'Check the recorded order status after delivery. Any COD handover remains separate.',
  );
}

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
    ('buyer', 'delivered') =>
      task.commercialStatus == 'completed'
          ? 'Delivery complete · check any outstanding cash responsibility'
          : 'Check the recorded order completion status',
    _ => 'Check the current instruction',
  };
}

String legGuide(OperationTask task) => task.phase == 'pickup'
    ? 'Pickup leg: seller → origin hub. The hub confirms intake.'
    : task.stage == 'delivery_failed'
    ? 'Return leg: bring the parcel to the destination hub. The hub records receipt and decides any retry.'
    : 'Delivery leg: destination hub → buyer. Valid handover evidence determines order completion; cash receipt is recorded separately.';

/// Compare the destination and authority the rider actually reviewed, rather
/// than a timestamp or an opaque version that may change for unrelated reasons.
bool sameReviewedStop(OperationTask a, OperationTask b) =>
    a.id == b.id &&
    a.tracking == b.tracking &&
    a.order == b.order &&
    a.preview == b.preview &&
    a.assignmentReference == b.assignmentReference &&
    a.stage == b.stage &&
    a.commercialStatus == b.commercialStatus &&
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
