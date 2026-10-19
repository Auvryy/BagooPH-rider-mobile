import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notification_models.dart';
import 'package:bagoo_rider_mobile/features/notifications/data/notifications_repository.dart';
import 'package:bagoo_rider_mobile/features/notifications/presentation/notifications_controller.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';

import '../operations_contract_test.dart' as ops;

String noticeId(int number) =>
    '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';
Map<String, dynamic> notificationJson(
  int number, {
  bool read = false,
  Object? target,
  String? title,
  String? body,
}) => {
  'id': noticeId(number),
  'type': 'parcel-event',
  'title': title ?? 'Your parcel update $number',
  'body': body ?? 'Review the current parcel details before continuing.',
  'recorded_at': '2026-10-19T03:00:00.000Z',
  'read_at': read ? '2026-10-19T03:05:00.000Z' : null,
  'target': target,
};
Map<String, dynamic> notificationEnvelope(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int? total,
  int? unread,
}) => {
  'data': {
    'items': items,
    'unread_count': unread ?? items.where((i) => i['read_at'] == null).length,
    'pagination': {
      'page': page,
      'per_page': 20,
      'total': total ?? items.length,
      'last_page': (((total ?? items.length) + 19) ~/ 20).clamp(1, 10000),
    },
  },
};
Map<String, dynamic> notificationCommand(
  CommandIntent intent, {
  bool expired = false,
  List<String>? ids,
}) => {
  'data': {
    'idempotency_key': intent.key,
    'action': 'notification.read',
    'resource': 'notifications',
    'state': 'committed',
    'result': {'read_ids': ids ?? intent.body['displayed_ids']},
    'recorded_at': '2026-10-19T03:05:00.000Z',
    'expires_at': '2026-10-26T03:05:00.000Z',
    'replayed': false,
    'retry_expired': expired,
  },
};

class NotificationSession extends ops.Session implements RiderReadSessionApi {
  final cancellations = <RiderReadCancellation>[];
  @override
  Future<Map<String, dynamic>> authenticatedRead(
    String path, {
    required RiderReadCancellation cancellation,
  }) {
    cancellations.add(cancellation);
    return authenticatedRequest(path);
  }
}

class NotificationsHarness {
  NotificationsHarness({
    bool enabled = true,
    bool workspace = false,
    bool realWork = false,
  }) {
    api.respond = respond;
    operations = OperationsRepository(
      api,
      accountId: '5',
      journal: ops.Journal(),
      writesVerified: false,
      isCurrent: () => current,
    );
    repository = OperationsNotificationsRepository(
      api,
      accountId: '5',
      journal: journal,
      isCurrent: () => current,
      readHome: operations.home,
      writesVerified: enabled,
      now: () => now,
    );
    work = workspace
        ? WorkspaceController(
            realWork ? operations : const UnavailableWorkspaceRepository(),
            notificationsRepository: repository,
          )
        : null;
    controller =
        work?.notifications ??
        NotificationsController(
          repository,
          onSessionEnd: (message) async {
            ended.add(message);
          },
        );
  }
  final api = NotificationSession();
  final journal = ops.Journal();
  late final OperationsRepository operations;
  late final OperationsNotificationsRepository repository;
  late final NotificationsController controller;
  late final WorkspaceController? work;
  bool current = true, available = true, unknown = false;
  DateTime now = DateTime.utc(2026, 10, 19, 3);
  final surface = Object();
  final ended = <String>[];
  List<Map<String, dynamic>> rows = [
    notificationJson(
      3,
      target: {
        'kind': 'task',
        'id': 'final_mile-1',
        'href': '/api/v1/rider/tasks/final_mile-1',
      },
    ),
    notificationJson(2),
    notificationJson(1),
  ];
  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (path == 'rider/home') {
      final home = ops.fixture('home');
      home['data']['account_id'] = '5';
      home['data']['capabilities']['notifications'] = available;
      return home;
    }
    if (path.startsWith('rider/notifications?')) {
      final page = int.parse(Uri.parse(path).queryParameters['page']!);
      return notificationEnvelope(
        rows.skip((page - 1) * 20).take(20).toList(),
        page: page,
        total: rows.length,
        unread: rows.where((i) => i['read_at'] == null).length,
      );
    }
    if (path.startsWith('rider/commands/')) {
      if (unknown) {
        throw const AccountFailure(
          'Unknown',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      return notificationCommand(journal.value!);
    }
    if (method == 'POST') {
      final intent = journal.value!;
      final ids = (intent.body['displayed_ids'] as List).cast<String>();
      for (final row in rows) {
        if (ids.contains(row['id'])) {
          row['read_at'] = '2026-10-19T03:05:00.000Z';
        }
      }
      return notificationCommand(intent);
    }
    if (path == 'rider/tasks/final_mile-1') {
      return ops.fixture('final-mile-task');
    }
    throw StateError('Unexpected notification test request $path');
  }

  Future<void> boot({bool inbox = true}) async {
    controller.setSurfaceActive(surface, true, inbox: inbox);
    await Future<void>.delayed(Duration.zero);
  }

  void display(Iterable<String> ids) =>
      controller.setDisplayed(surface, ids, controller.revision);
  RiderNotification get first => controller.inbox.data!.first;
  void dispose() {
    if (work != null) {
      work!.dispose();
    } else {
      controller.dispose();
    }
  }
}
