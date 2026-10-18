import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../../core/platform/rider_website.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart' show WebsiteButton;
import '../data/message_models.dart';
import 'messages_controller.dart';

bool messagesUseSplitView(double width, TextScaler scaler) =>
    width >= 920 && scaler.scale(14) < 22;

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    required this.controller,
    required this.preview,
    required this.active,
    this.threadOnly = false,
    this.onBack,
  });
  final WorkspaceController controller;
  final bool preview, active, threadOnly;
  final VoidCallback? onBack;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with WidgetsBindingObserver {
  final _surface = Object();
  final _search = TextEditingController();
  ModalRoute<dynamic>? _route;
  bool _foreground = true;
  MessagesController get chat => widget.controller.messages;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
      _route = route;
      _route?.secondaryAnimation?.addStatusListener(_routeChanged);
    }
    _syncSurface();
  }

  void _routeChanged(AnimationStatus _) => _syncSurface();
  void _syncSurface() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        chat.setSurfaceActive(
          _surface,
          widget.active && _foreground && (_route?.isCurrent ?? true),
        );
      }
    });
  }

  @override
  void didUpdateWidget(MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.messages.setSurfaceActive(_surface, false);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.controller != widget.controller) {
      _syncSurface();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    chat.setForeground(_foreground);
    _syncSurface();
  }

  @override
  void dispose() {
    chat.setSurfaceActive(_surface, false);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: widget.active && _foreground,
    child: ListenableBuilder(
      listenable: chat,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final split =
              !widget.threadOnly &&
              messagesUseSplitView(
                constraints.maxWidth,
                MediaQuery.textScalerOf(context),
              );
          final selected = chat.selectedId;
          final list = _ConversationList(controller: chat, search: _search);
          final detail = selected == null
              ? const _MessageState(
                  icon: Icons.forum_outlined,
                  title: 'Choose a conversation',
                  message: 'Open a parcel chat to contact its seller or buyer.',
                )
              : _ThreadPane(
                  key: ValueKey(selected),
                  controller: chat,
                  active: widget.active && _foreground,
                  preview: widget.preview,
                  showBack: !split,
                  onBack:
                      widget.onBack ??
                      () {
                        FocusScope.of(context).unfocus();
                        unawaited(chat.selectConversation(null));
                      },
                );
          if (!split) {
            return selected == null && !widget.threadOnly ? list : detail;
          }
          return Row(
            children: [
              SizedBox(width: 352, child: list),
              const VerticalDivider(width: 1, color: RiderColors.border),
              Expanded(child: detail),
            ],
          );
        },
      ),
    ),
  );
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.controller, required this.search});
  final MessagesController controller;
  final TextEditingController search;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final rows = c.visibleConversations;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: c.refresh,
          child: CustomScrollView(
            key: const PageStorageKey('conversation-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Messages',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          _RefreshButton(
                            onPressed: c.canRefresh ? c.refresh : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A direct line for your pickups and deliveries.',
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const ValueKey('conversation-search'),
                        controller: search,
                        onChanged: c.searchConversations,
                        decoration: const InputDecoration(
                          labelText: 'Search loaded conversations',
                          hintText: 'Name or parcel reference',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      if (c.inboxPagination != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${c.inbox.data?.length ?? 0} of ${c.inboxPagination!.total} conversations loaded',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (c.inbox.status == FeatureStatus.refreshing) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(
                          semanticsLabel: 'Refreshing conversations',
                        ),
                      ],
                      if (c.pendingIntent != null) ...[
                        const SizedBox(height: 16),
                        _PendingRequest(controller: c),
                      ],
                      if (c.failure != null && c.inbox.data != null) ...[
                        const SizedBox(height: 12),
                        _InlineNotice(c.failure!.message),
                        TextButton(
                          onPressed: c.canRefresh ? c.refresh : null,
                          child: const Text('Try again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (c.inbox.data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: c.inbox.status == FeatureStatus.loading
                      ? const _MessagesLoading()
                      : _MessageState(
                          icon: Icons.forum_outlined,
                          title: 'Messages unavailable',
                          message:
                              c.inbox.message ??
                              'Refresh to check your parcel conversations.',
                          action: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: c.canRefresh ? c.refresh : null,
                                child: const Text('Refresh'),
                              ),
                              const WebsiteButton(
                                page: RiderWebsitePage.messages,
                              ),
                            ],
                          ),
                        ),
                )
              else if (rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: c.search.trim().isEmpty
                        ? 'No parcel conversations'
                        : 'No matching conversations',
                    message: c.search.trim().isEmpty
                        ? 'Chats appear when a pickup or delivery is assigned to you.'
                        : 'Try another name or load more conversations.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ConversationRow(
                        thread: rows[index],
                        controller: c,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.hasMoreConversations)
                        OutlinedButton(
                          key: const ValueKey('conversations-more'),
                          onPressed:
                              c.loadingMore ||
                                  c.coolingDown ||
                                  c.working ||
                                  c.inbox.status != FeatureStatus.ready
                              ? null
                              : c.loadMoreConversations,
                          child: Text(
                            c.loadingMore
                                ? 'Loading…'
                                : 'Load more conversations',
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Refresh for new messages. Only the chat you view can be marked read.',
                        style: TextStyle(
                          fontSize: 12,
                          color: RiderColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.thread, required this.controller});
  final ParcelConversation thread;
  final MessagesController controller;
  @override
  Widget build(BuildContext context) => Material(
    color: thread.id == controller.selectedId
        ? RiderColors.rose
        : RiderColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: RiderColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('conversation-${thread.id}'),
      onTap: () => unawaited(controller.selectConversation(thread.id)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChatAvatar(
              thread: thread,
              origin: controller.repository.avatarOrigin,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.participantName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.phaseLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: RiderColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.tracking,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    thread.lastMessage?.text ??
                        'Start this parcel conversation.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!thread.canSend) ...[
                    const SizedBox(height: 8),
                    const Text('Read only', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (thread.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Semantics(
                label: '${thread.unreadCount} unread messages',
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: RiderColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      thread.unreadCount > 99 ? '99+' : '${thread.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ThreadPane extends StatefulWidget {
  const _ThreadPane({
    super.key,
    required this.controller,
    required this.active,
    required this.preview,
    required this.onBack,
    required this.showBack,
  });
  final MessagesController controller;
  final bool active, preview, showBack;
  final VoidCallback onBack;
  @override
  State<_ThreadPane> createState() => _ThreadPaneState();
}

class _ThreadPaneState extends State<_ThreadPane> {
  late final draft = TextEditingController(text: widget.controller.draft);
  final scroll = ScrollController();
  final viewport = GlobalKey();
  final anchors = <String, GlobalKey>{};
  bool _scheduled = false;
  String? _attempt;
  String? _newest;
  MessagesController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    scroll.addListener(_onScroll);
    _scheduleRead();
  }

  void _onScroll() {
    _scheduleRead();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_ThreadPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newest = c.messages.firstOrNull?.id;
    if (_newest != null &&
        newest != _newest &&
        scroll.hasClients &&
        scroll.offset > 80) {
      final box = viewport.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final visible = box.localToGlobal(Offset.zero) & box.size;
        for (final key in anchors.values) {
          final anchor = key.currentContext?.findRenderObject();
          if (anchor is! RenderBox || !anchor.attached || !anchor.hasSize) {
            continue;
          }
          final y = anchor.localToGlobal(Offset.zero).dy;
          if (y < visible.top || y + anchor.size.height > visible.bottom) {
            continue;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !scroll.hasClients) return;
            final moved = key.currentContext?.findRenderObject();
            if (moved is! RenderBox || !moved.attached || !moved.hasSize) {
              return;
            }
            final offset =
                scroll.offset + y - moved.localToGlobal(Offset.zero).dy;
            scroll.jumpTo(
              offset.clamp(
                scroll.position.minScrollExtent,
                scroll.position.maxScrollExtent,
              ),
            );
          });
          break;
        }
      }
    }
    _newest = newest;
    if (draft.text != c.draft) {
      draft.value = TextEditingValue(
        text: c.draft,
        selection: TextSelection.collapsed(offset: c.draft.length),
      );
    }
    _scheduleRead();
  }

  @override
  void dispose() {
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _scheduleRead() {
    if (_scheduled || !widget.active || !c.canWrite) return;
    _scheduled = true;
    final revision = c.historyRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          !widget.active ||
          !c.canWrite ||
          revision != c.historyRevision ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      final render = viewport.currentContext?.findRenderObject();
      if (render is! RenderBox || !render.hasSize) return;
      final visible = render.localToGlobal(Offset.zero) & render.size;
      String? boundary;
      for (final message in c.messages) {
        if (message.fromRider || message.isRead) continue;
        final anchor = anchors[message.id]?.currentContext?.findRenderObject();
        if (anchor is! RenderBox || !anchor.hasSize || !anchor.attached) {
          continue;
        }
        final rect = anchor.localToGlobal(Offset.zero) & anchor.size;
        if (rect.top >= visible.top &&
            rect.bottom <= visible.bottom &&
            rect.left >= visible.left &&
            rect.right <= visible.right) {
          if (boundary == null ||
              BigInt.parse(message.id) > BigInt.parse(boundary)) {
            boundary = message.id;
          }
        }
      }
      if (boundary == null || _attempt == boundary) return;
      _attempt = boundary;
      unawaited(c.acknowledgeDisplayed(c.selectedId!, boundary, revision));
    });
  }

  Future<void> _contextInfo(ParcelConversation thread) async {
    final refresh = await showRiderDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(thread.participantName),
        content: SingleChildScrollView(
          child: Text(
            '${thread.phaseLabel}\n${thread.tracking}\n${thread.assignmentReference ?? 'Assignment reference unavailable'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: c.working || c.coolingDown
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Refresh conversation'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (refresh == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c.canRefresh) unawaited(c.refresh());
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxHeight < 420 ||
          MediaQuery.textScalerOf(context).scale(14) >= 22;
      final narrowLarge =
          constraints.maxWidth < 460 &&
          MediaQuery.textScalerOf(context).scale(14) >= 22;
      final thread = c.thread;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: RiderColors.surface,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: compact ? 4 : 12,
              ),
              child: Row(
                children: [
                  if (widget.showBack)
                    IconButton(
                      key: const ValueKey('conversation-back'),
                      tooltip: 'Back to conversations',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  if (!compact &&
                      constraints.maxWidth >= 600 &&
                      thread != null) ...[
                    _ChatAvatar(
                      thread: thread,
                      origin: c.repository.avatarOrigin,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread?.participantName ?? 'Parcel conversation',
                          maxLines: compact && !narrowLarge ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if ((!compact ||
                                (narrowLarge &&
                                    constraints.maxHeight >= 500)) &&
                            thread != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            narrowLarge
                                ? thread.phaseLabel
                                : '${thread.tracking} · ${thread.phaseLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (thread != null)
                    IconButton(
                      tooltip: 'Parcel and participant details',
                      onPressed: () => _contextInfo(thread),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  if (!narrowLarge)
                    _RefreshButton(onPressed: c.canRefresh ? c.refresh : null),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: RiderColors.border),
          Expanded(
            child: thread == null
                ? c.detail.status == FeatureStatus.loading
                      ? const _MessagesLoading()
                      : _MessageState(
                          icon: Icons.lock_outline_rounded,
                          title: 'Conversation unavailable',
                          message:
                              c.detail.message ??
                              'Refresh to check this conversation.',
                          action: TextButton(
                            onPressed: c.canRefresh ? c.refresh : null,
                            child: const Text('Refresh'),
                          ),
                        )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRect(
                          key: viewport,
                          child: ListView.builder(
                            key: PageStorageKey('messages-${c.selectedId}'),
                            controller: scroll,
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            itemCount: c.messages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == c.messages.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    children: [
                                      if (c.hasOlderMessages)
                                        TextButton(
                                          key: const ValueKey('messages-older'),
                                          onPressed:
                                              c.loadingOlder ||
                                                  c.working ||
                                                  c.coolingDown
                                              ? null
                                              : () => c.refreshThread(
                                                  older: true,
                                                ),
                                          child: Text(
                                            c.loadingOlder
                                                ? 'Loading…'
                                                : 'Load earlier messages',
                                          ),
                                        ),
                                      if (c.messages.isEmpty)
                                        const _MessageState(
                                          icon:
                                              Icons.chat_bubble_outline_rounded,
                                          title: 'Start the conversation',
                                          message: 'Keep updates about this parcel clear and brief.',
                                        ),
                                    ],
                                  ),
                                );
                              }
                              final message = c.messages[index];
                              return _MessageBubble(
                                message: message,
                                readAnchor: anchors.putIfAbsent(
                                  message.id,
                                  GlobalKey.new,
                                ),
                                preview: widget.preview,
                              );
                            },
                          ),
                        ),
                      ),
                      if (c.detail.status == FeatureStatus.refreshing)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            semanticsLabel: 'Refreshing conversation',
                          ),
                        ),
                      if (scroll.hasClients && scroll.offset > 80)
                        Positioned(
                          right: 16,
                          bottom: 8,
                          child: FilledButton.tonalIcon(
                            onPressed: () => scroll.jumpTo(0),
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                            ),
                            label: const Text('Latest'),
                          ),
                        ),
                    ],
                  ),
          ),
          if (thread != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * .45,
              ),
              child: Material(
                color: RiderColors.surface,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.pendingIntent != null)
                        _PendingRequest(controller: c),
                      if (c.notice != null) _InlineNotice(c.notice!),
                      if (c.detail.status == FeatureStatus.failed)
                        _InlineNotice(c.detail.message!),
                      if (c.readError != null) ...[
                        _InlineNotice(
                          'Read status was not confirmed. ${c.readError}',
                        ),
                        if (c.pendingIntent == null)
                          TextButton(
                            onPressed: c.canWrite
                                ? () {
                                    _attempt = null;
                                    _scheduleRead();
                                    WidgetsBinding.instance
                                        .ensureVisualUpdate();
                                  }
                                : null,
                            child: const Text('Retry displayed read status'),
                          ),
                      ],
                      if (!thread.canSend)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'This assignment is read only. New messages are unavailable.',
                          ),
                        )
                      else ...[
                        if (!c.repository.writesVerified)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Chat sending and read receipts are waiting for service verification.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('message-draft'),
                                controller: draft,
                                onChanged: c.updateDraft,
                                enabled:
                                    widget.active &&
                                    !c.working &&
                                    c.pendingIntent == null,
                                minLines: 1,
                                maxLines: compact ? 1 : 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  labelText: widget.preview
                                      ? 'Preview message'
                                      : 'Message',
                                  hintText: 'Write a parcel update',
                                  errorText: c.sendError,
                                  errorMaxLines: 4,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RiderPressFeedback(
                              child: IconButton.filled(
                                key: const ValueKey('send-message'),
                                tooltip: c.working
                                    ? 'Checking message request'
                                    : widget.preview
                                    ? 'Preview send'
                                    : 'Send message',
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed:
                                    c.canSend && c.draft.trim().isNotEmpty
                                    ? () => unawaited(c.sendDraft())
                                    : null,
                                icon: c.working
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.readAnchor,
    required this.preview,
  });
  final ParcelMessage message;
  final GlobalKey readAnchor;
  final bool preview;
  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromRider ? Alignment.centerRight : Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        key: ValueKey('message-${message.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.fromRider ? RiderColors.rose : RiderColors.surface,
          border: Border.all(color: RiderColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.fromRider ? 16 : 4),
            bottomRight: Radius.circular(message.fromRider ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              key: readAnchor,
              preview && message.fromRider
                  ? 'Preview · not sent'
                  : '${dayLabel(message.recordedAt)} · ${timeLabel(message.recordedAt)} PHT${message.fromRider
                        ? message.isRead
                              ? ' · Read'
                              : ' · Sent'
                        : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: RiderColors.ink,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.thread,
    required this.origin,
    this.size = 44,
  });
  final ParcelConversation thread;
  final Uri? origin;
  final double size;
  @override
  Widget build(BuildContext context) {
    final initials = thread.participantName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final fallback = Container(
      alignment: Alignment.center,
      color: RiderColors.controlFill,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: RiderColors.ink,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: thread.avatarPath == null || origin == null
              ? fallback
              : Image.network(
                  origin!.resolve(thread.avatarPath!).toString(),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                  loadingBuilder: (_, child, loading) =>
                      loading == null ? child : fallback,
                ),
        ),
      ),
    );
  }
}

class _PendingRequest extends StatelessWidget {
  const _PendingRequest({required this.controller});
  final MessagesController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final read = c.pendingIntent?.action == 'message.read';
    return RiderSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            read
                ? 'A read receipt needs checking.'
                : 'A message request needs checking.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            read
                ? 'Checking this receipt keeps its original displayed boundary.'
                : 'Keep its original recipient and text until the result is confirmed.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                key: const ValueKey('message-reconcile'),
                onPressed: c.working || c.coolingDown ? null : c.reconcile,
                child: const Text('Check saved request'),
              ),
              if (c.pendingIntent?.resource != c.selectedId)
                TextButton(
                  onPressed: () =>
                      c.selectConversation(c.pendingIntent!.resource),
                  child: const Text('Open original conversation'),
                ),
              if (c.commandUnknown)
                TextButton(
                  key: const ValueKey('message-retry-original'),
                  onPressed: c.canRetryOriginal
                      ? () => c.reconcile(retryUnknown: true)
                      : null,
                  child: const Text('Retry original request'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Refresh messages',
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    onPressed: onPressed,
    icon: const Icon(Icons.refresh_rounded),
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 32, color: RiderColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    ),
  );
}

class _MessagesLoading extends StatelessWidget {
  const _MessagesLoading();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading messages',
    child: const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
