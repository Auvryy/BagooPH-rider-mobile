import '../../../core/commands/notification_validation.dart';
import '../../../core/network/rider_api_client.dart';
import '../../auth/data/account.dart';
import '../../home/data/command_journal.dart';
import '../../home/data/operations_models.dart';
import 'notification_models.dart';

abstract interface class NotificationsRepository {
  bool get writesVerified;
  Future<bool> available();
  Future<NotificationPage> page({
    int page = 1,
    RiderReadCancellation? cancellation,
  });
  Future<CommandIntent?> pending();
  Future<NotificationReadResult> acknowledge(
    List<String> ids, {
    required bool Function() mayDispatch,
  });
  Future<NotificationReadResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  });
  Future<NotificationDestination> resolve(
    NotificationTarget target, {
    required RiderReadCancellation cancellation,
  });
}

class UnavailableNotificationsRepository implements NotificationsRepository {
  const UnavailableNotificationsRepository();
  @override
  bool get writesVerified => false;
  @override
  Future<bool> available() async => false;
  Never _unavailable() => throw const AccountFailure(
    'Notifications are unavailable for this account.',
    code: 'NOTIFICATIONS_UNAVAILABLE',
  );
  @override
  Future<NotificationPage> page({
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async => _unavailable();
  @override
  Future<CommandIntent?> pending() async => null;
  @override
  Future<NotificationReadResult> acknowledge(
    List<String> ids, {
    required bool Function() mayDispatch,
  }) async => _unavailable();
  @override
  Future<NotificationReadResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async => _unavailable();
  @override
  Future<NotificationDestination> resolve(
    NotificationTarget target, {
    required RiderReadCancellation cancellation,
  }) async => _unavailable();
}

/// Shares the existing authenticated session/budget. No provider client or href
/// supplied by a notification can receive first-party credentials.
class OperationsNotificationsRepository implements NotificationsRepository {
  OperationsNotificationsRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.isCurrent,
    required this.readHome,
    required this.writesVerified,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RiderSessionApi api;
  final String accountId;
  final CommandJournal journal;
  final bool Function() isCurrent;
  final Future<OperationsHome> Function() readHome;
  @override
  final bool writesVerified;
  final DateTime Function() now;
  bool _writing = false;

  void _guard() {
    if (!isCurrent()) {
      throw const AccountFailure('Please sign in again.', status: 401);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
    RiderReadCancellation? cancellation,
  }) async {
    _guard();
    final response =
        method == 'GET' && cancellation != null && api is RiderReadSessionApi
        ? await (api as RiderReadSessionApi).authenticatedRead(
            path,
            cancellation: cancellation,
          )
        : await api.authenticatedRequest(
            path,
            method: method,
            data: data,
            headers: headers,
          );
    if (cancellation?.cancelled == true) {
      throw const AccountFailure(
        'This read was cancelled.',
        code: 'REQUEST_CANCELLED',
      );
    }
    _guard();
    return Wire.object(response['data']);
  }

  @override
  Future<bool> available() async {
    _guard();
    final home = await readHome();
    _guard();
    if (home.accountId != accountId) Wire.invalid();
    return home.capabilities['notifications'] == true;
  }

  @override
  Future<NotificationPage> page({
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async {
    if (page < 1 || page > 10000) Wire.invalid();
    final result = NotificationPage.fromJson(
      await _request(
        'rider/notifications?page=$page&per_page=20',
        cancellation: cancellation,
      ),
    );
    if (result.page != page || result.perPage != 20) Wire.invalid();
    return result;
  }

  @override
  Future<CommandIntent?> pending() async {
    _guard();
    final saved = await journal.read();
    _guard();
    if (saved != null &&
        (saved.accountId != accountId || !saved.isNotification)) {
      Wire.invalid();
    }
    return saved;
  }

  void _dispatchGuard(bool Function() mayDispatch) {
    _guard();
    if (!writesVerified) {
      throw const AccountFailure(
        'Read acknowledgements are awaiting service verification.',
        code: 'NOTIFICATIONS_NOT_VERIFIED',
      );
    }
    if (!mayDispatch()) {
      throw const AccountFailure(
        'Return to Notifications and refresh before continuing.',
        code: 'NOTIFICATIONS_PAUSED',
      );
    }
  }

  Future<void> _revalidate(bool Function() mayDispatch) async {
    _dispatchGuard(mayDispatch);
    if (!await available()) {
      throw const AccountFailure(
        'Notifications are unavailable for this account.',
        code: 'NOTIFICATIONS_UNAVAILABLE',
      );
    }
    _dispatchGuard(mayDispatch);
  }

  @override
  Future<NotificationReadResult> acknowledge(
    List<String> ids, {
    required bool Function() mayDispatch,
  }) async {
    if (_writing) {
      throw const AccountFailure('A read request is already being checked.');
    }
    _writing = true;
    try {
      _dispatchGuard(mayDispatch);
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the saved read request before starting another.',
        );
      }
      final intent = CommandIntent(
        accountId: accountId,
        key: commandUuid(),
        action: 'notification.read',
        resource: 'notifications',
        body: {'displayed_ids': notificationIds(ids)},
        createdAt: now().toUtc(),
      );
      await _revalidate(mayDispatch);
      await journal.write(intent);
      _dispatchGuard(mayDispatch);
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }

  Future<NotificationReadResult> _accept(
    CommandIntent intent,
    Map<String, dynamic> data,
  ) async {
    final result = NotificationReadResult.fromJson(data, intent);
    _guard();
    await journal.clear();
    _guard();
    return result;
  }

  Future<NotificationReadResult> _dispatch(CommandIntent intent) async {
    try {
      final single = (intent.body['displayed_ids'] as List).length == 1;
      return await _accept(
        intent,
        await _request(
          intent.path,
          method: 'POST',
          data: single ? <String, dynamic>{} : intent.body,
          headers: {
            'Idempotency-Key': intent.key,
            'X-Request-ID': commandUuid(),
          },
        ),
      );
    } on AccountFailure catch (error) {
      if (!error.unconfirmed &&
          [404, 409, 422].contains(error.status) &&
          !['IDEMPOTENCY_CONFLICT', 'COMMAND_EXPIRED'].contains(error.code)) {
        _guard();
        await journal.clear();
      }
      rethrow;
    } catch (_) {
      throw const AccountFailure(
        'The read result is uncertain. Check the saved request before trying again.',
        unconfirmed: true,
      );
    }
  }

  @override
  Future<NotificationReadResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async {
    if (_writing) {
      throw const AccountFailure('A read request is already being checked.');
    }
    _writing = true;
    try {
      final saved = await pending();
      if (saved == null) return null;
      try {
        return await _accept(
          saved,
          await _request('rider/commands/${saved.key}'),
        );
      } on AccountFailure catch (error) {
        if (error.status != 404 || error.code != 'COMMAND_UNKNOWN') rethrow;
        if (!retryUnknown) return null;
        if (now().toUtc().difference(saved.createdAt) >=
            const Duration(days: 7)) {
          throw const AccountFailure(
            'The saved request is outside its retry window. Revalidate with support.',
          );
        }
        await _revalidate(mayDispatch);
        return await _dispatch(saved);
      }
    } finally {
      _writing = false;
    }
  }

  @override
  Future<NotificationDestination> resolve(
    NotificationTarget target, {
    required RiderReadCancellation cancellation,
  }) async {
    final result = await _request(target.path, cancellation: cancellation);
    switch (target.kind) {
      case 'task':
        final task = OperationTask.fromJson(result);
        if (task.id != target.id || task.preview) Wire.invalid();
        return NotificationTaskDestination(task);
      case 'cash':
        final cash = NotificationCash.fromJson(result);
        if (cash.id != target.id) Wire.invalid();
        return NotificationCashDestination(cash);
      case 'account':
        final account = RiderAccount.fromJson(result);
        if (account.id != target.id || account.id != accountId) Wire.invalid();
        if (!account.approved || account.operationsApiVersion != 1) {
          throw const AccountFailure(
            'Your account access changed. Please sign in again.',
            status: 403,
          );
        }
        return NotificationAccountDestination(account);
      default:
        Wire.invalid();
    }
  }
}
