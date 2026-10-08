enum TaskQueue {
  available('Available pickups', 'Pickups are claimed by the rider.'),
  pickups('My pickups', 'The origin hub records receipt after collection.'),
  delivery(
    'Assigned delivery',
    'Final-mile work is assigned by the destination hub.',
  );

  const TaskQueue(this.label, this.description);
  final String label, description;
}

enum PaymentFilter { all, cod, prepaid }

enum FeatureStatus { loading, ready, refreshing, unavailable, failed }

class FeatureData<T> {
  const FeatureData.loading()
    : status = FeatureStatus.loading,
      data = null,
      message = null;
  const FeatureData.ready(this.data)
    : status = FeatureStatus.ready,
      message = null;
  const FeatureData.refreshing(this.data)
    : status = FeatureStatus.refreshing,
      message = null;
  const FeatureData.unavailable(this.message)
    : status = FeatureStatus.unavailable,
      data = null;
  const FeatureData.failed(this.message, [this.data])
    : status = FeatureStatus.failed;
  final FeatureStatus status;
  final T? data;
  final String? message;
}

class RiderTask {
  const RiderTask({
    required this.id,
    required this.tracking,
    required this.stage,
    required this.stop,
    required this.address,
    required this.nextStep,
    this.cashCentavos,
  });
  final String id, tracking, stage, stop, address, nextStep;
  final int? cashCentavos;
}

class TripCheckpoint {
  const TripCheckpoint(this.label, this.recordedAt);
  final String label;
  final DateTime? recordedAt;
}

class RiderTrip {
  const RiderTrip({
    required this.id,
    required this.tracking,
    required this.recipient,
    required this.address,
    required this.outcome,
    required this.recordedAt,
    required this.payment,
    required this.checkpoints,
    this.cashCentavos,
  });
  final String id, tracking, recipient, address, outcome;
  final DateTime recordedAt;
  final PaymentFilter payment;
  final int? cashCentavos;
  final List<TripCheckpoint> checkpoints;
}

class RiderMessage {
  const RiderMessage({
    required this.id,
    required this.text,
    required this.fromRider,
    required this.recordedAt,
    this.localPreview = false,
  });
  final String id, text;
  final bool fromRider, localPreview;
  final DateTime recordedAt;
}

class RiderConversation {
  const RiderConversation({
    required this.id,
    required this.tracking,
    required this.participant,
    required this.phase,
    required this.canSend,
    required this.messages,
    this.unreadCount = 0,
  });
  final String id, tracking, participant, phase;
  final bool canSend;
  final List<RiderMessage> messages;
  final int unreadCount;
  String get phaseLabel =>
      phase == 'pickup' ? 'Seller · Pickup' : 'Buyer · Final mile';
  RiderConversation withMessage(RiderMessage message) => RiderConversation(
    id: id,
    tracking: tracking,
    participant: participant,
    phase: phase,
    canSend: canSend,
    unreadCount: unreadCount,
    messages: List.unmodifiable([...messages, message]),
  );
  RiderConversation read() => RiderConversation(
    id: id,
    tracking: tracking,
    participant: participant,
    phase: phase,
    canSend: canSend,
    messages: messages,
  );
}

String pesos(int centavos) {
  final negative = centavos < 0;
  final value = centavos.abs();
  final whole = (value ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '${negative ? '-' : ''}₱$whole.${(value % 100).toString().padLeft(2, '0')}';
}

DateTime manilaTime(DateTime date) =>
    date.toUtc().add(const Duration(hours: 8));
String dayLabel(DateTime date) {
  final local = manilaTime(date);
  return calendarDateLabel(local);
}

String calendarDateLabel(DateTime local) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String timeLabel(DateTime date) {
  final local = manilaTime(date);
  return '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
}
