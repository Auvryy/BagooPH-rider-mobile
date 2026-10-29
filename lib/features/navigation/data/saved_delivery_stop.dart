import '../../home/data/operations_models.dart';

/// A saved, authorized parcel stop. It is neither GPS nor a calculated route.
class SavedDeliveryStop {
  const SavedDeliveryStop._(
    this.reference,
    this.label,
    this.latitude,
    this.longitude,
  );
  final String reference, label;
  final double latitude, longitude;
  static SavedDeliveryStop? fromTask(OperationTask? task) {
    final latitude = task?.stop.latitude, longitude = task?.stop.longitude;
    if (task == null ||
        latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 85 ||
        longitude.abs() > 180) {
      return null;
    }
    return SavedDeliveryStop._(
      '${task.id}:${task.stop.kind}',
      task.stop.name ?? 'Saved current stop',
      latitude,
      longitude,
    );
  }

  Map<String, Object> toJson() => {
    'reference': reference,
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
  };
  @override
  bool operator ==(Object other) =>
      other is SavedDeliveryStop &&
      reference == other.reference &&
      label == other.label &&
      latitude == other.latitude &&
      longitude == other.longitude;
  @override
  int get hashCode => Object.hash(reference, label, latitude, longitude);
}
