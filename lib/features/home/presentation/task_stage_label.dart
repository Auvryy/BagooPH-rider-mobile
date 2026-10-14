/// Display only. Permissions and transitions still use the original server data.
String taskStageLabel(String stage) => switch (stage) {
  'unassigned' => 'Ready for pickup',
  'assigned' || 'assigned_pickup' => 'Pickup assigned',
  'picked_up' => 'Bring to origin hub',
  'assigned_to_rider' => 'Collect at destination hub',
  'out_for_delivery' => 'On delivery',
  'delivery_failed' => 'Return to destination hub',
  _ => 'Unknown work stage',
};
