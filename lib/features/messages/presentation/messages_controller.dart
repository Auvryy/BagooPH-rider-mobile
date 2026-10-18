import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/commands/command_intent.dart';
import '../../../core/commands/message_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/data/workspace_models.dart';
import '../data/message_models.dart';
import '../data/messages_repository.dart';

/// One account's chat state. Foreground polling is owned by WorkspaceController;
/// opening a list never acknowledges a thread or starts a second poll loop.
class MessagesController extends ChangeNotifier {
  MessagesController(this.repository, {this.onSessionEnd}) {
    if (repository is UnavailableMessagesRepository) {
      inbox = const FeatureData.unavailable(
        'Messages are not available for this account yet.',
      );
    }
  }
  final MessagesRepository repository;
  final Future<void> Function(String notice)? onSessionEnd;
  FeatureData<List<ParcelConversation>> inbox = const FeatureData.loading();
  FeatureData<ParcelConversation> detail = const FeatureData.loading();
  List<ParcelMessage> messages = const [];
  MessagePagination? inboxPagination, historyPagination;
  String? selectedId;
  String search = '';
  String? sendError, readError, notice;
  AccountFailure? failure;
  CommandIntent? pendingIntent;
  bool pendingLoaded = false, commandUnknown = false;
  bool loadingMore = false, loadingOlder = false, working = false;
  bool _refreshing = false, _verified = false;
  bool _foreground = true, _disposed = false, _accessLost = false;
  final _surfaces = <Object>{};
  final _drafts = <String, String>{};
  int _epoch = 0, _listGeneration = 0, _historyGeneration = 0;
  int historyRevision = 0;
  DateTime? _cooldownUntil;
  Timer? _cooldown;
  RiderReadCancellation? _listRead, _historyRead, _resolverRead;
  void _cancelReads() {
    _listRead?.cancel();
    _historyRead?.cancel();
    _resolverRead?.cancel();
  }

  bool get active =>
      !_disposed && !_accessLost && _foreground && _surfaces.isNotEmpty;
  bool get coolingDown => _cooldownUntil?.isAfter(DateTime.now()) ?? false;
  bool get canRefresh => active && !working && !_refreshing && !coolingDown;
  bool get hasMoreConversations => inboxPagination?.hasMore == true;
  bool get hasOlderMessages => historyPagination?.hasMore == true;
  ParcelConversation? get thread => detail.data;
  String get draft => selectedId == null ? '' : _drafts[selectedId] ?? '';
  bool get canWrite =>
      active &&
      _verified &&
      !working &&
      !coolingDown &&
      pendingLoaded &&
      pendingIntent == null &&
      repository.writesVerified &&
      detail.status == FeatureStatus.ready &&
      thread?.id == selectedId;
  bool get canSend => canWrite && thread?.canSend == true;
  bool get canRetryOriginal =>
      active &&
      _verified &&
      !working &&
      !coolingDown &&
      repository.writesVerified &&
      commandUnknown &&
      pendingIntent?.resource == selectedId &&
      (pendingIntent?.action != 'message.send' || thread?.canSend == true);
  List<ParcelConversation> get visibleConversations => (inbox.data ?? [])
      .where(
        (t) => '${t.participantName} ${t.tracking}'.toLowerCase().contains(
          search.trim().toLowerCase(),
        ),
      )
      .toList(growable: false);

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// A visible tab or a current-stop route owns a surface lease. Offstage and
  /// covered surfaces release it; a separate route cannot activate a hidden tab.
  void setSurfaceActive(Object owner, bool value) {
    if (_disposed) return;
    final wasActive = active;
    if (value) {
      _surfaces.add(owner);
    } else {
      _surfaces.remove(owner);
    }
    if (wasActive == active) return;
    _epoch++;
    _cancelReads();
    _listGeneration++;
    _historyGeneration++;
    _refreshing = loadingMore = loadingOlder = false;
    _verified = false;
    if (active) unawaited(refresh());
  }

  void setForeground(bool value) {
    if (_disposed || _foreground == value) return;
    _foreground = value;
    _epoch++;
    _cancelReads();
    _listGeneration++;
    _historyGeneration++;
    _refreshing = loadingMore = loadingOlder = false;
    _verified = false;
    if (!value) {
      inbox = const FeatureData.loading();
      detail = const FeatureData.loading();
      messages = const [];
      pendingIntent = null;
      pendingLoaded = false;
      failure = null;
      sendError = readError = notice = null;
      historyRevision++;
    } else if (active) {
      unawaited(refresh());
    }
    _changed();
  }

  void searchConversations(String value) {
    search = value;
    _changed();
  }

  bool _current(int epoch) => active && epoch == _epoch;

  Future<void> _error(Object error, {bool selected = false}) async {
    final problem = error is AccountFailure
        ? error
        : const AccountFailure(
            'Messages could not be verified. Refresh and try again.',
          );
    failure = problem;
    if (problem.retryAfterSeconds != null) {
      _cooldown?.cancel();
      final delay = Duration(seconds: problem.retryAfterSeconds!);
      _cooldownUntil = DateTime.now().add(delay);
      _cooldown = Timer(delay, () {
        _cooldownUntil = null;
        _changed();
      });
    }
    if (problem.invalidSession) {
      revoke(problem.message);
      await onSessionEnd?.call(problem.message);
    } else if (problem.code == 'MESSAGES_UNAVAILABLE') {
      capabilityUnavailable();
    } else if (selected &&
        (problem.status == 404 || problem.code == 'STALE_CONVERSATION')) {
      // Denied history also invalidates its private inbox preview. An older
      // list page must not restore that preview after authorization is lost.
      _listRead?.cancel();
      _listGeneration++;
      _refreshing = loadingMore = false;
      inboxPagination = historyPagination = null;
      final retained = inbox.data
          ?.where((item) => item.id != selectedId)
          .toList(growable: false);
      if (retained != null) {
        inbox = inbox.status == FeatureStatus.failed
            ? FeatureData.failed(inbox.message, retained)
            : FeatureData.ready(retained);
      }
      _drafts.remove(selectedId);
      detail = FeatureData.unavailable(problem.message);
      messages = const [];
      _verified = false;
      historyRevision++;
    }
  }

  void revoke(String message) {
    if (_disposed) return;
    _accessLost = true;
    _epoch++;
    _cancelReads();
    _listGeneration++;
    _historyGeneration++;
    _drafts.clear();
    messages = const [];
    selectedId = null;
    pendingIntent = null;
    pendingLoaded = _verified = false;
    inboxPagination = historyPagination = null;
    inbox = FeatureData.unavailable(message);
    detail = FeatureData.unavailable(message);
    sendError = readError = notice = null;
    historyRevision++;
    _cooldown?.cancel();
    _changed();
  }

  void capabilityUnavailable() {
    if (_disposed) return;
    _epoch++;
    _cancelReads();
    _listGeneration++;
    _historyGeneration++;
    _refreshing = loadingMore = loadingOlder = false;
    _verified = false;
    _drafts.clear();
    messages = const [];
    inboxPagination = historyPagination = null;
    pendingIntent = null;
    pendingLoaded = commandUnknown = false;
    inbox = const FeatureData.unavailable(
      'Messages are unavailable for this account.',
    );
    detail = const FeatureData.unavailable(
      'Refresh to check this conversation.',
    );
    historyRevision++;
    _changed();
  }

  Future<void> refresh({bool? available}) async {
    if (!canRefresh) return;
    final epoch = _epoch;
    final generation = ++_listGeneration;
    loadingMore = false;
    final cancellation = RiderReadCancellation();
    _listRead?.cancel();
    _listRead = cancellation;
    _refreshing = true;
    final previous = inbox.data;
    inbox = previous == null
        ? const FeatureData.loading()
        : FeatureData.refreshing(previous);
    _verified = false;
    _changed();
    try {
      final enabled = available ?? await repository.available();
      if (!_current(epoch) || generation != _listGeneration) return;
      if (!enabled) {
        _drafts.clear();
        messages = const [];
        detail = const FeatureData.unavailable(
          'Messages are unavailable for this account.',
        );
        inbox = const FeatureData.unavailable(
          'Messages are unavailable for this account. Refresh or sign in again after the service is enabled.',
        );
        historyRevision++;
        return;
      }
      final pending = await repository.pending();
      if (!_current(epoch) || generation != _listGeneration) return;
      pendingIntent = pending;
      pendingLoaded = true;
      final page = await repository.conversations(cancellation: cancellation);
      if (!_current(epoch) || generation != _listGeneration) return;
      inbox = FeatureData.ready(page.items);
      inboxPagination = page.pagination;
      failure = null;
      for (final item in page.items) {
        if (!item.canSend) _drafts.remove(item.id);
      }
      // A selected thread may be beyond page one. Its own fresh resource, not
      // absence from a partial list, decides whether access still exists.
      if (selectedId != null) await refreshThread();
    } catch (error) {
      if (_current(epoch) && generation == _listGeneration) {
        await _error(error);
        if (!_accessLost) {
          inbox = FeatureData.failed(failure!.message, previous);
        }
      }
    } finally {
      if (!_disposed && generation == _listGeneration) {
        _refreshing = false;
        _changed();
      }
    }
  }

  Future<void> loadMoreConversations() async {
    if (!active ||
        working ||
        coolingDown ||
        _refreshing ||
        loadingMore ||
        inbox.status != FeatureStatus.ready ||
        !hasMoreConversations) {
      return;
    }
    final epoch = _epoch;
    final generation = _listGeneration;
    final pageNumber = inboxPagination!.page + 1;
    final cancellation = RiderReadCancellation();
    _listRead?.cancel();
    _listRead = cancellation;
    loadingMore = true;
    _changed();
    try {
      final page = await repository.conversations(
        page: pageNumber,
        cancellation: cancellation,
      );
      if (!_current(epoch) || generation != _listGeneration) return;
      final items = {for (final item in inbox.data!) item.id: item};
      for (final item in page.items) {
        final known = items[item.id]?.lastMessage;
        items[item.id] = known == null ? item : item.withLatestMessage(known);
      }
      inbox = FeatureData.ready(List.unmodifiable(items.values));
      inboxPagination = page.pagination;
      failure = null;
    } catch (error) {
      if (_current(epoch) && generation == _listGeneration) await _error(error);
    } finally {
      if (!_disposed && generation == _listGeneration) {
        loadingMore = false;
        _changed();
      }
    }
  }

  Future<void> selectConversation(String? id) async {
    if (_disposed || _accessLost) return;
    if (id != null) messageThreadParts(id);
    _epoch++;
    _cancelReads();
    _listGeneration++;
    _historyGeneration++;
    _refreshing = loadingMore = loadingOlder = false;
    selectedId = id;
    detail = const FeatureData.loading();
    messages = const [];
    historyPagination = null;
    _verified = false;
    sendError = readError = notice = null;
    historyRevision++;
    _changed();
    if (id != null && active && !coolingDown) await refreshThread();
  }

  Future<void> refreshThread({bool older = false}) async {
    final id = selectedId;
    if (!active ||
        id == null ||
        working ||
        coolingDown ||
        (older && (loadingOlder || !hasOlderMessages))) {
      return;
    }
    final epoch = _epoch;
    final generation = older ? _historyGeneration : ++_historyGeneration;
    final cancellation = RiderReadCancellation();
    _historyRead?.cancel();
    _historyRead = cancellation;
    final pageNumber = older ? historyPagination!.page + 1 : 1;
    if (older) {
      loadingOlder = true;
    } else {
      _verified = false;
      detail = detail.data == null
          ? const FeatureData.loading()
          : FeatureData.refreshing(detail.data);
    }
    _changed();
    try {
      final page = await repository.history(
        id,
        page: pageNumber,
        cancellation: cancellation,
      );
      if (!_current(epoch) ||
          generation != _historyGeneration ||
          selectedId != id) {
        return;
      }
      if (!page.thread.canSend) _drafts.remove(id);
      final known = {for (final message in messages) message.id: message};
      for (final message in page.items) {
        // A page begun before a committed receipt may arrive afterward. Reads
        // are monotonic; an older response cannot make that message unread.
        known[message.id] = known[message.id]?.isRead == true && !message.isRead
            ? message.read()
            : message;
      }
      final sorted = known.values.toList()
        ..sort((a, b) => BigInt.parse(b.id).compareTo(BigInt.parse(a.id)));
      messages = List.unmodifiable(sorted);
      detail = FeatureData.ready(page.thread);
      historyPagination = page.pagination;
      _verified = true;
      failure = null;
      historyRevision++;
    } catch (error) {
      if (_current(epoch) &&
          generation == _historyGeneration &&
          selectedId == id) {
        final previous = detail.data;
        await _error(error, selected: true);
        if (!_accessLost && detail.status != FeatureStatus.unavailable) {
          detail = FeatureData.failed(failure!.message, previous);
          _verified = false;
        }
      }
    } finally {
      if (!_disposed && generation == _historyGeneration) {
        loadingOlder = false;
        _changed();
      }
    }
  }

  void updateDraft(String value) {
    if (!active ||
        thread?.id != selectedId ||
        thread?.canSend != true ||
        working) {
      return;
    }
    _drafts[selectedId!] = value;
    sendError = null;
    _changed();
  }

  Future<void> _restorePending() async {
    if (!active) return;
    final epoch = _epoch;
    try {
      final saved = await repository.pending();
      if (!_current(epoch)) return;
      if (saved?.key != pendingIntent?.key) commandUnknown = false;
      pendingIntent = saved;
      pendingLoaded = true;
    } catch (_) {
      if (_current(epoch)) pendingLoaded = false;
    }
  }

  void _apply(MessageCommandResult result) {
    final id = result.intent.resource;
    if (result.message != null) {
      final saved = _drafts[id];
      if (saved != null) {
        try {
          if (messageText(saved) == result.intent.body['text']) {
            _drafts.remove(id);
          }
        } on AccountFailure {
          /* A subsequently edited draft remains separate. */
        }
      }
    }
    if (!active) return;
    if (result.message != null && inbox.data != null) {
      final updated = List<ParcelConversation>.unmodifiable(
        inbox.data!.map(
          (item) =>
              item.id == id ? item.withLatestMessage(result.message!) : item,
        ),
      );
      inbox = switch (inbox.status) {
        FeatureStatus.refreshing => FeatureData.refreshing(updated),
        FeatureStatus.failed => FeatureData.failed(inbox.message, updated),
        _ => FeatureData.ready(updated),
      };
    }
    if (id != selectedId || !_verified) return;
    if (result.message != null) {
      detail = FeatureData.ready(thread!.withLatestMessage(result.message!));
      final known = {
        for (final item in messages) item.id: item,
        result.message!.id: result.message!,
      };
      messages = List.unmodifiable(
        known.values.toList()
          ..sort((a, b) => BigInt.parse(b.id).compareTo(BigInt.parse(a.id))),
      );
    } else {
      final boundary = BigInt.parse(result.throughMessageId!);
      messages = List.unmodifiable(
        messages.map(
          (message) =>
              !message.fromRider && BigInt.parse(message.id) <= boundary
              ? message.read()
              : message,
        ),
      );
    }
    historyRevision++;
  }

  Future<bool> sendDraft() async {
    if (!canSend) return false;
    final epoch = _epoch;
    final original = thread!;
    String text;
    try {
      text = messageText(draft);
    } on AccountFailure catch (error) {
      sendError = error.fields['text'] ?? error.message;
      _changed();
      return false;
    }
    working = true;
    commandUnknown = false;
    sendError = null;
    _changed();
    try {
      final result = await repository.send(
        original,
        text,
        mayDispatch: () =>
            _current(epoch) && selectedId == original.id && _verified,
      );
      if (_disposed) return false;
      _apply(result);
      if (_current(epoch)) notice = 'Message sent.';
      return true;
    } catch (error) {
      if (!_disposed && _current(epoch)) {
        await _error(error, selected: true);
        sendError = failure?.fields['text'] ?? failure?.message;
      }
      return false;
    } finally {
      if (!_disposed) {
        working = false;
        await _restorePending();
        _changed();
      }
    }
  }

  Future<void> acknowledgeDisplayed(
    String id,
    String throughMessageId,
    int revision,
  ) async {
    if (!canWrite ||
        id != selectedId ||
        revision != historyRevision ||
        !messages.any(
          (m) => m.id == throughMessageId && !m.fromRider && !m.isRead,
        )) {
      return;
    }
    final epoch = _epoch;
    working = true;
    commandUnknown = false;
    readError = null;
    _changed();
    try {
      final result = await repository.acknowledge(
        thread!,
        throughMessageId,
        mayDispatch: () =>
            _current(epoch) &&
            selectedId == id &&
            _verified &&
            revision == historyRevision,
      );
      if (!_disposed && _current(epoch)) _apply(result);
    } catch (error) {
      if (!_disposed && _current(epoch)) {
        await _error(error, selected: true);
        readError = failure?.message;
      }
    } finally {
      if (!_disposed) {
        working = false;
        await _restorePending();
        _changed();
      }
    }
  }

  Future<void> reconcile({bool retryUnknown = false}) async {
    if (!active ||
        working ||
        coolingDown ||
        (retryUnknown && !canRetryOriginal)) {
      return;
    }
    final epoch = _epoch;
    working = true;
    notice = null;
    _changed();
    try {
      final result = await repository.reconcile(
        retryUnknown: retryUnknown,
        mayDispatch: () =>
            _current(epoch) &&
            _verified &&
            pendingIntent?.resource == selectedId,
      );
      if (!_disposed && _current(epoch)) {
        commandUnknown = result == null;
        if (result == null) {
          notice = 'No saved result is visible yet. This does not confirm failure. You can retry the original request from its conversation.';
        } else {
          _apply(result);
          notice = result.message != null
              ? 'The original message was sent.'
              : 'The displayed read status was saved.';
          sendError = readError = null;
        }
      }
    } catch (error) {
      if (!_disposed && _current(epoch)) {
        await _error(error);
        notice = failure?.message;
      }
    } finally {
      if (!_disposed) {
        working = false;
        await _restorePending();
        _changed();
      }
    }
  }

  /// Resolve only returned resources, with a bounded search. A missing match
  /// stays unavailable rather than inventing a thread or participant ID.
  Future<String?> findForTask(OperationTask task) async {
    if (!active || working || coolingDown || task.preview) return null;
    final epoch = _epoch;
    final cancellation = RiderReadCancellation();
    _resolverRead?.cancel();
    _resolverRead = cancellation;
    if (!await repository.available() || !_current(epoch)) return null;
    for (var number = 1; number <= 5; number++) {
      final page = await repository.conversations(
        page: number,
        cancellation: cancellation,
      );
      if (!_current(epoch)) return null;
      for (final item in page.items) {
        if (item.taskId == task.id &&
            item.tracking == task.tracking &&
            item.assignmentReference == task.assignmentReference &&
            item.canSend) {
          final fresh = await repository.history(
            item.id,
            cancellation: cancellation,
          );
          if (!_current(epoch) || !fresh.thread.canSend) return null;
          return fresh.thread.id;
        }
      }
      if (!page.pagination.hasMore) break;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelReads();
    _cooldown?.cancel();
    _surfaces.clear();
    _drafts.clear();
    selectedId = null;
    pendingIntent = null;
    messages = const [];
    inbox = const FeatureData.loading();
    detail = const FeatureData.loading();
    super.dispose();
  }
}
