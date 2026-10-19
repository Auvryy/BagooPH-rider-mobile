import 'dart:math';

import '../network/wire.dart';
import 'message_validation.dart';
import 'notification_validation.dart';
import 'parcel_proof.dart';
import 'parcel_validation.dart';

String commandUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Exact persisted intent for the selected ordinary work commands. The legacy
/// duty/claim JSON remains readable. Unknown future variants are never deleted.
class CommandIntent {
  CommandIntent({
    required this.accountId,
    required this.key,
    required this.action,
    required this.resource,
    required Map<String, dynamic> body,
    required this.createdAt,
    this.proof,
  }) : body = Map.unmodifiable({
         ...body,
         if (action == 'notification.read')
           'displayed_ids': notificationIds(body['displayed_ids']),
       }) {
    Wire.id(accountId);
    Wire.uuid(key);
    if (action == 'duty') {
      if (resource != 'rider' || body.length != 1 || proof != null) {
        Wire.invalid();
      }
      Wire.boolean(body['on_duty']);
    } else if (action == 'claim') {
      if (!Wire.taskId(resource).startsWith('pickup-') ||
          body.length != 1 ||
          proof != null) {
        Wire.invalid();
      }
      Wire.version(body['expected_version']);
    } else if (isNotification) {
      if (resource != 'notifications' || body.length != 1 || proof != null) {
        Wire.invalid();
      }
      notificationIds(body['displayed_ids']);
    } else if (isMessage) {
      messageThreadParts(resource);
      if (proof != null || body.length != 1) Wire.invalid();
      if (action == 'message.send') {
        final text = Wire.string(body['text']);
        if (messageText(text) != text) Wire.invalid();
      } else {
        Wire.id(body['through_message_id']);
      }
    } else {
      final selected = parcelAction;
      if (selected == null ||
          !Wire.taskId(resource).startsWith(
            selected == ParcelAction.pickup ? 'pickup-' : 'final_mile-',
          )) {
        Wire.invalid();
      }
      final required = {'expected_version', 'barcode'};
      final allowed = {...required, 'notes'};
      if (selected == ParcelAction.deliver) {
        required.addAll({
          'recipient_name',
          'recipient_relationship',
          'cash_received',
          'change_given',
          'cash_confirmed',
        });
        parcelText(
          Wire.string(body['recipient_name']),
          'recipient_name',
          min: 2,
          max: 255,
        );
        if (!recipientRelationships.containsKey(
              body['recipient_relationship'],
            ) ||
            body['cash_confirmed'] != true) {
          Wire.invalid();
        }
        pesoInputCents(Wire.string(body['cash_received']));
        pesoInputCents(
          Wire.string(body['change_given']),
          field: 'change_given',
        );
      } else if (selected == ParcelAction.fail) {
        required.addAll({'notes', 'reason', 'location_name'});
        if (!failureReasonCodes.contains(body['reason'])) Wire.invalid();
        parcelText(
          Wire.string(body['location_name']),
          'location_name',
          max: 255,
        );
      }
      allowed.addAll(required);
      if (!body.keys.toSet().containsAll(required) ||
          !allowed.containsAll(body.keys) ||
          selected.requiresProof != (proof != null) ||
          (proof != null && proof!.key != key)) {
        Wire.invalid();
      }
      Wire.version(body['expected_version']);
      final code = Wire.string(body['barcode']);
      if (parcelWaybill(code) != code) Wire.invalid();
      if (body['notes'] != null) {
        parcelText(Wire.string(body['notes']), 'notes');
      }
      if (selected == ParcelAction.fail && body['notes'] == null) {
        Wire.invalid();
      }
    }
  }

  factory CommandIntent.fromJson(Map<String, dynamic> j) => CommandIntent(
    accountId: Wire.id(j['account_id']),
    key: Wire.uuid(j['key']),
    action: Wire.string(j['action']),
    resource: Wire.string(j['resource']),
    body: Wire.object(j['body']),
    createdAt: Wire.time(j['created_at']),
    proof: j['proof'] == null
        ? null
        : ParcelProofReference.fromJson(Wire.object(j['proof'])),
  );

  final String accountId, key, action, resource;
  final Map<String, dynamic> body;
  final DateTime createdAt;
  final ParcelProofReference? proof;
  bool get isMessage => action == 'message.send' || action == 'message.read';
  bool get isNotification => action == 'notification.read';
  ParcelAction? get parcelAction =>
      ParcelAction.values.where((value) => value.name == action).firstOrNull;
  String get deliveryId => isNotification
      ? Wire.invalid()
      : isMessage
      ? messageThreadParts(resource).deliveryId
      : resource.split('-').last;
  String get path => switch (action) {
    'duty' => 'rider/duty',
    'claim' => 'rider/pickup-jobs/${resource.substring(7)}/claim',
    'message.send' => 'rider/conversations/$resource/messages',
    'message.read' => 'rider/conversations/$resource/read',
    'notification.read' =>
      (body['displayed_ids'] as List).length == 1
          ? 'rider/notifications/${(body['displayed_ids'] as List).single}/read'
          : 'rider/notifications/read-through',
    _ => 'rider/tasks/$resource/$action',
  };
  String get method => action == 'duty' ? 'PATCH' : 'POST';
  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'key': key,
    'action': action,
    'resource': resource,
    'body': body,
    'created_at': DateTime.fromMillisecondsSinceEpoch(
      createdAt.millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String(),
    if (proof != null) 'proof': proof!.toJson(),
  };
}
