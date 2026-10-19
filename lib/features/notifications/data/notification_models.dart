import '../../../core/commands/command_intent.dart';
import '../../../core/commands/notification_validation.dart';
import '../../auth/data/account.dart';
import '../../home/data/operations_models.dart';

/// Only these native destinations have an implemented, freshly checked view.
/// Returned hrefs are matched exactly and are never passed to a browser/client.
class NotificationTarget {
  const NotificationTarget._(this.kind, this.id, this.path);
  final String kind, id, path;

  static NotificationTarget? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    try {
      final kind = Wire.string(value['kind']);
      final id = kind == 'task'
          ? Wire.taskId(value['id'])
          : Wire.id(value['id']);
      final path = switch (kind) {
        'task' => 'rider/tasks/$id',
        'cash' => 'rider/cash/$id',
        'account' => 'rider/me',
        _ => null,
      };
      if (path == null || value['href'] != '/api/v1/$path') return null;
      return NotificationTarget._(kind, id, path);
    } on FormatException {
      return null;
    }
  }
}

class RiderNotification {
  RiderNotification.fromJson(Map<String, dynamic> json)
    : id = Wire.uuid(json['id']),
      type = Wire.string(json['type']),
      title = Wire.nullableString(json['title']),
      body = Wire.nullableString(json['body']),
      recordedAt = Wire.time(json['recorded_at']),
      readAt = json['read_at'] == null ? null : Wire.time(json['read_at']),
      target = NotificationTarget.parse(json['target']);
  RiderNotification._read(RiderNotification original, DateTime time)
    : id = original.id,
      type = original.type,
      title = original.title,
      body = original.body,
      recordedAt = original.recordedAt,
      readAt = original.readAt ?? time,
      target = original.target;
  final String id, type;
  final String? title, body;
  final DateTime recordedAt;
  final DateTime? readAt;
  final NotificationTarget? target;
  bool get unread => readAt == null;
  String get heading =>
      title?.trim().isNotEmpty == true ? title! : 'Rider update';
  RiderNotification read(DateTime time) => RiderNotification._read(this, time);
}

class NotificationPage {
  NotificationPage.fromJson(Map<String, dynamic> json)
    : unreadCount = Wire.count(json['unread_count']) {
    final rows = json['items'];
    if (rows is! List) Wire.invalid();
    items = List.unmodifiable(
      rows.map((row) => RiderNotification.fromJson(Wire.object(row))),
    );
    final paging = Wire.object(json['pagination']);
    page = Wire.count(paging['page']);
    perPage = Wire.count(paging['per_page']);
    total = Wire.count(paging['total']);
    lastPage = Wire.count(paging['last_page']);
    if (page < 1 ||
        page > 10000 ||
        perPage < 1 ||
        perPage > 50 ||
        lastPage < 1 ||
        lastPage != (total == 0 ? 1 : (total + perPage - 1) ~/ perPage) ||
        items.length > perPage ||
        items.length > total ||
        items.map((item) => item.id).toSet().length != items.length) {
      Wire.invalid();
    }
  }
  late final List<RiderNotification> items;
  late final int page, perPage, total, lastPage;
  final int unreadCount;
  bool get hasMore => page < lastPage && page < 10000;
}

class NotificationReadResult {
  NotificationReadResult.fromJson(Map<String, dynamic> json, this.intent) {
    if (!intent.isNotification ||
        Wire.uuid(json['idempotency_key']) != intent.key ||
        json['action'] != intent.action ||
        json['resource'] != intent.resource ||
        json['state'] != 'committed') {
      Wire.invalid();
    }
    recordedAt = Wire.time(json['recorded_at']);
    if (!Wire.time(json['expires_at']).isAfter(recordedAt)) Wire.invalid();
    replayed = Wire.boolean(json['replayed']);
    retryExpired = Wire.boolean(json['retry_expired']);
    ids = notificationIds(Wire.object(json['result'])['read_ids']);
    final expected = notificationIds(intent.body['displayed_ids']);
    if (ids.length != expected.length ||
        !Iterable.generate(ids.length).every((i) => ids[i] == expected[i])) {
      Wire.invalid();
    }
  }
  final CommandIntent intent;
  late final List<String> ids;
  late final DateTime recordedAt;
  late final bool replayed, retryExpired;
}

/// A small read-only linked view. This does not activate cash offers or earnings.
class NotificationCash {
  NotificationCash.fromJson(Map<String, dynamic> json)
    : id = Wire.id(json['id']),
      tracking = Wire.string(json['tracking_number']),
      status = Wire.string(json['status']),
      version = Wire.id(json['version']),
      heldCents = _cents(json['own_held_cents']),
      remittedCents = _cents(json['own_remitted_cents']),
      reconciledCents = _cents(json['reconciled_cents']),
      recordedAt = Wire.time(json['recorded_at']);
  final String id,
      tracking,
      status,
      version,
      heldCents,
      remittedCents,
      reconciledCents;
  final DateTime recordedAt;
  static String _cents(Object? value) {
    final result = Wire.string(value);
    if (RegExp(r'^(0|[1-9][0-9]*)$').firstMatch(result)?.end != result.length) {
      Wire.invalid();
    }
    return result;
  }
}

sealed class NotificationDestination {}

class NotificationTaskDestination extends NotificationDestination {
  NotificationTaskDestination(this.task);
  final OperationTask task;
}

class NotificationCashDestination extends NotificationDestination {
  NotificationCashDestination(this.cash);
  final NotificationCash cash;
}

class NotificationAccountDestination extends NotificationDestination {
  NotificationAccountDestination(this.account);
  final RiderAccount account;
}
