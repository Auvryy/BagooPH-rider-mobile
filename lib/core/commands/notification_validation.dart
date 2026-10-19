import '../network/wire.dart';

/// The server fingerprints a sorted, exact list, never a time boundary.
List<String> notificationIds(Object? value) {
  if (value is! List || value.isEmpty || value.length > 50) Wire.invalid();
  final ids = value.map(Wire.uuid).toList()..sort();
  if (ids.toSet().length != ids.length) Wire.invalid();
  return List.unmodifiable(ids);
}
