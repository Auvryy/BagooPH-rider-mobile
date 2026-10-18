import '../../../core/commands/message_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart';
import '../../home/data/operations_models.dart';
import 'message_models.dart';

abstract interface class MessagesRepository {
  bool get writesVerified;
  Uri? get avatarOrigin;
  Future<bool> available();
  Future<ConversationPage> conversations({
    int page = 1,
    RiderReadCancellation? cancellation,
  });
  Future<MessageHistoryPage> history(
    String threadId, {
    int page = 1,
    RiderReadCancellation? cancellation,
  });
  Future<CommandIntent?> pending();
  Future<MessageCommandResult> send(
    ParcelConversation thread,
    String text, {
    required bool Function() mayDispatch,
  });
  Future<MessageCommandResult> acknowledge(
    ParcelConversation thread,
    String throughMessageId, {
    required bool Function() mayDispatch,
  });
  Future<MessageCommandResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  });
}

class UnavailableMessagesRepository implements MessagesRepository {
  const UnavailableMessagesRepository();
  @override
  bool get writesVerified => false;
  @override
  Uri? get avatarOrigin => null;
  @override
  Future<bool> available() async => false;
  Never _unavailable() => throw const AccountFailure(
    'Messages are unavailable for this account. Refresh or sign in again after the service is enabled.',
    code: 'MESSAGES_UNAVAILABLE',
  );
  @override
  Future<ConversationPage> conversations({
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async => _unavailable();
  @override
  Future<MessageHistoryPage> history(
    String threadId, {
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async => _unavailable();
  @override
  Future<CommandIntent?> pending() async => null;
  @override
  Future<MessageCommandResult> send(
    ParcelConversation thread,
    String text, {
    required bool Function() mayDispatch,
  }) async => _unavailable();
  @override
  Future<MessageCommandResult> acknowledge(
    ParcelConversation thread,
    String throughMessageId, {
    required bool Function() mayDispatch,
  }) async => _unavailable();
  @override
  Future<MessageCommandResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async => _unavailable();
}

/// Uses the existing first-party session and request budget. The separate secure
/// journal prevents uncertain reads/sends from replacing a parcel command.
class OperationsMessagesRepository implements MessagesRepository {
  OperationsMessagesRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.writesVerified,
    required this.isCurrent,
    required this.readHome,
    required this.avatarOrigin,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final RiderSessionApi api;
  final String accountId;
  final CommandJournal journal;
  @override
  final bool writesVerified;
  @override
  final Uri? avatarOrigin;
  final bool Function() isCurrent;
  final Future<OperationsHome> Function() readHome;
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
        cancellation != null && method == 'GET' && api is RiderReadSessionApi
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
    return home.capabilities['messages'] == true;
  }

  String _paged(String path, int page) {
    if (page < 1 || page > 10000) Wire.invalid();
    return '$path?page=$page&per_page=20';
  }

  void _actors(ParcelConversation thread, Iterable<ParcelMessage> messages) {
    for (final message in messages) {
      if (message.senderId !=
          (message.fromRider ? accountId : thread.participantId)) {
        Wire.invalid();
      }
    }
  }

  @override
  Future<ConversationPage> conversations({
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async {
    final result = ConversationPage.fromJson(
      await _request(
        _paged('rider/conversations', page),
        cancellation: cancellation,
      ),
    );
    if (result.pagination.page != page || result.pagination.perPage != 20) {
      Wire.invalid();
    }
    for (final thread in result.items) {
      _actors(thread, [if (thread.lastMessage != null) thread.lastMessage!]);
    }
    return result;
  }

  @override
  Future<MessageHistoryPage> history(
    String threadId, {
    int page = 1,
    RiderReadCancellation? cancellation,
  }) async {
    messageThreadParts(threadId);
    final result = MessageHistoryPage.fromJson(
      await _request(
        _paged('rider/conversations/$threadId/messages', page),
        cancellation: cancellation,
      ),
    );
    if (result.thread.id != threadId ||
        result.pagination.page != page ||
        result.pagination.perPage != 20) {
      Wire.invalid();
    }
    _actors(result.thread, [
      ...result.items,
      if (result.thread.lastMessage != null) result.thread.lastMessage!,
    ]);
    return result;
  }

  @override
  Future<CommandIntent?> pending() async {
    _guard();
    final intent = await journal.read();
    _guard();
    if (intent != null &&
        (intent.accountId != accountId || !intent.isMessage)) {
      Wire.invalid();
    }
    return intent;
  }

  void _dispatchGuard(bool Function() mayDispatch) {
    _guard();
    if (!writesVerified) {
      throw const AccountFailure(
        'Sending and read receipts are awaiting service verification.',
        code: 'MESSAGES_NOT_VERIFIED',
      );
    }
    if (!mayDispatch()) {
      throw const AccountFailure(
        'Return to this conversation and refresh before continuing.',
        code: 'MESSAGE_PAUSED',
      );
    }
  }

  Future<void> _revalidate(
    CommandIntent intent,
    bool Function() mayDispatch,
  ) async {
    _dispatchGuard(mayDispatch);
    if (!await available()) {
      throw const AccountFailure(
        'Messages are unavailable for this account.',
        code: 'MESSAGES_UNAVAILABLE',
      );
    }
    _dispatchGuard(mayDispatch);
    final fresh = await history(intent.resource);
    _dispatchGuard(mayDispatch);
    if (intent.action == 'message.send' && !fresh.thread.canSend) {
      throw const AccountFailure(
        'This assignment is read only. The draft stays with its original recipient.',
        status: 409,
        code: 'STALE_CONVERSATION',
      );
    }
  }

  @override
  Future<MessageCommandResult> send(
    ParcelConversation thread,
    String text, {
    required bool Function() mayDispatch,
  }) => _newIntent('message.send', thread, {
    'text': messageText(text),
  }, mayDispatch);

  @override
  Future<MessageCommandResult> acknowledge(
    ParcelConversation thread,
    String throughMessageId, {
    required bool Function() mayDispatch,
  }) => _newIntent('message.read', thread, {
    'through_message_id': Wire.id(throughMessageId),
  }, mayDispatch);

  Future<MessageCommandResult> _newIntent(
    String action,
    ParcelConversation thread,
    Map<String, dynamic> body,
    bool Function() mayDispatch,
  ) async {
    if (_writing) {
      throw const AccountFailure('A message request is already being checked.');
    }
    _writing = true;
    try {
      _dispatchGuard(mayDispatch);
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the saved message request before starting another.',
        );
      }
      final intent = CommandIntent(
        accountId: accountId,
        key: commandUuid(),
        action: action,
        resource: thread.id,
        body: body,
        createdAt: now().toUtc(),
      );
      await _revalidate(intent, mayDispatch);
      // Storage failure prevents dispatch. Never replace a saved UUID after a timeout.
      await journal.write(intent);
      _dispatchGuard(mayDispatch);
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }

  Future<MessageCommandResult> _accept(
    CommandIntent intent,
    Map<String, dynamic> data,
  ) async {
    final value = MessageCommandResult.fromJson(data, intent);
    _guard();
    await journal.clear();
    _guard();
    return value;
  }

  Future<MessageCommandResult> _dispatch(CommandIntent intent) async {
    try {
      return await _accept(
        intent,
        await _request(
          intent.path,
          method: intent.method,
          data: intent.body,
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
        'The message result is uncertain. Check the saved request before sending again.',
        unconfirmed: true,
      );
    }
  }

  @override
  Future<MessageCommandResult?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async {
    if (_writing) {
      throw const AccountFailure('A message request is already being checked.');
    }
    _writing = true;
    try {
      final intent = await pending();
      if (intent == null) return null;
      try {
        return await _accept(
          intent,
          await _request('rider/commands/${intent.key}'),
        );
      } on AccountFailure catch (error) {
        if (error.code != 'COMMAND_UNKNOWN' || error.status != 404) rethrow;
        if (!retryUnknown) return null;
        if (now().toUtc().difference(intent.createdAt) >=
            const Duration(days: 7)) {
          throw const AccountFailure(
            'The saved request is outside its retry window. Revalidate with support.',
          );
        }
        await _revalidate(intent, mayDispatch);
        return await _dispatch(intent);
      }
    } finally {
      _writing = false;
    }
  }
}
