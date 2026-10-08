import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/platform/rider_website.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    required this.controller,
    required this.preview,
    required this.active,
  });
  final WorkspaceController controller;
  final bool preview, active;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.conversationData.data == null) {
      return WorkspaceBody(
        children: [
          const WorkspaceHeading(
            'Messages',
            'Coordinate with the right person for this parcel.',
          ),
          FeatureStateView<List<RiderConversation>>(
            data: c.conversationData,
            icon: Icons.forum_outlined,
            title: 'Messages',
            onRetry: c.refreshConversations,
            website: RiderWebsitePage.messages,
            ready: (_) => const SizedBox.shrink(),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 &&
            MediaQuery.textScalerOf(context).scale(14) < 24;
        final selected = c.selectedConversation;
        final contacts = ListView(
          key: const PageStorageKey('conversation-list'),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh conversations',
                  onPressed: c.sending ? null : c.refreshConversations,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${c.conversationData.data!.length} parcel conversations'),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('conversation-search'),
              controller: search,
              onChanged: c.searchConversations,
              decoration: const InputDecoration(
                labelText: 'Find a conversation',
                hintText: 'Name or parcel reference',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20),
            if (c.conversationData.status == FeatureStatus.refreshing)
              const LinearProgressIndicator(
                semanticsLabel: 'Refreshing conversations',
              ),
            if (c.conversationData.status == FeatureStatus.failed) ...[
              Text(c.conversationData.message!),
              TextButton(
                onPressed: c.refreshConversations,
                child: const Text('Try again'),
              ),
            ],
            if (c.visibleConversations.isEmpty)
              WorkspaceEmpty(
                c.conversationData.data!.isEmpty
                    ? 'No parcel conversations'
                    : 'No matching conversations',
                c.conversationData.data!.isEmpty
                    ? 'Conversations appear for your assigned pickups and deliveries.'
                    : 'Try another name or parcel reference.',
              ),
            for (final thread in c.visibleConversations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: thread.id == c.selectedConversationId
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    key: ValueKey('conversation-${thread.id}'),
                    onTap: c.sending
                        ? null
                        : () => c.selectConversation(thread.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkspaceAvatar(thread.participant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  thread.participant,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  thread.phaseLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  thread.messages.isEmpty
                                      ? 'No messages recorded'
                                      : thread.messages.last.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  thread.tracking,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (!thread.canSend) ...[
                                  const SizedBox(height: 8),
                                  const WorkspaceBadge('Read only'),
                                ],
                              ],
                            ),
                          ),
                          if (thread.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              label: '${thread.unreadCount} unread messages',
                              child: WorkspaceBadge(
                                '${thread.unreadCount}',
                                accent: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Refresh for new messages. Drafts stay while you switch conversations.',
              ),
            ),
          ],
        );
        final detail = selected == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: WorkspaceEmpty(
                    'Choose a conversation',
                    'Select the seller or buyer linked to your parcel.',
                  ),
                ),
              )
            : _ConversationThread(
                key: ValueKey(
                  '${selected.id}:${selected.phase}:${selected.canSend}',
                ),
                controller: c,
                thread: selected,
                preview: widget.preview,
                active: widget.active,
                compact: !wide,
              );
        if (!wide) return selected == null ? contacts : detail;
        return Row(
          children: [
            SizedBox(width: 320, child: contacts),
            const VerticalDivider(width: 1, color: RiderColors.divider),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _ConversationThread extends StatefulWidget {
  const _ConversationThread({
    super.key,
    required this.controller,
    required this.thread,
    required this.preview,
    required this.active,
    required this.compact,
  });
  final WorkspaceController controller;
  final RiderConversation thread;
  final bool preview, active, compact;
  @override
  State<_ConversationThread> createState() => _ConversationThreadState();
}

class _ConversationThreadState extends State<_ConversationThread> {
  late final TextEditingController draft;
  final scroll = ScrollController();
  String? _readAttempt;
  @override
  void initState() {
    super.initState();
    draft = TextEditingController(text: widget.controller.draft);
    scroll.addListener(scheduleRead);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
        scheduleRead();
      }
    });
    scheduleRead();
  }

  @override
  void didUpdateWidget(_ConversationThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    scheduleRead();
  }

  void scheduleRead() {
    final thread = widget.thread;
    if (!widget.active ||
        thread.unreadCount == 0 ||
        widget.controller.acknowledging ||
        widget.controller.conversationData.status != FeatureStatus.ready) {
      return;
    }
    final latest = thread.messages.isEmpty ? '' : thread.messages.last.id;
    if (_readAttempt == latest || thread.messages.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.active &&
          !widget.controller.acknowledging &&
          scroll.hasClients &&
          scroll.position.maxScrollExtent - scroll.offset < 32 &&
          _readAttempt != latest) {
        _readAttempt = latest;
        unawaited(
          widget.controller.acknowledgeVisibleConversation(
            thread.id,
            phase: thread.phase,
            throughMessageId: latest,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final atBottom =
        !scroll.hasClients ||
        scroll.position.maxScrollExtent - scroll.offset < 40;
    if (await widget.controller.sendDraft() && mounted) {
      draft.clear();
      if (atBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients) {
            scroll.jumpTo(scroll.position.maxScrollExtent);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final c = widget.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 600 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final canSend =
            thread.canSend && c.conversationData.status == FeatureStatus.ready;
        final input = TextField(
          key: const ValueKey('message-draft'),
          controller: draft,
          onChanged: c.updateDraft,
          enabled: !c.sending,
          minLines: 1,
          maxLines: compact ? 1 : 3,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: widget.preview ? 'Preview message' : 'Message',
            hintText: 'Coordinate this parcel',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            counterText: compact ? '' : null,
            isDense: compact,
            contentPadding: compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : null,
          ),
        );
        final sendButton = compact
            ? IconButton.filled(
                key: const ValueKey('send-message'),
                tooltip: widget.preview ? 'Preview send' : 'Send message',
                onPressed: c.sending || !canSend || c.draft.trim().isEmpty
                    ? null
                    : send,
                icon: const Icon(Icons.send_outlined, size: 22),
              )
            : FilledButton.icon(
                key: const ValueKey('send-message'),
                onPressed: c.sending || !canSend || c.draft.trim().isEmpty
                    ? null
                    : send,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  c.sending
                      ? 'Please wait…'
                      : widget.preview
                      ? 'Preview send'
                      : 'Send message',
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: compact ? 6 : 12,
                ),
                child: Row(
                  children: [
                    if (widget.compact)
                      IconButton(
                        key: const ValueKey('conversation-back'),
                        tooltip: 'Back to conversations',
                        onPressed: c.sending
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                c.selectConversation(null);
                              },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    WorkspaceAvatar(
                      thread.participant,
                      size: compact ? 32 : 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.participant,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${thread.tracking} · ${thread.phaseLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (compact)
                      Tooltip(
                        message: '${thread.tracking} · ${thread.phaseLabel}',
                        child: const Icon(Icons.inventory_2_outlined, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: RiderColors.divider),
            Expanded(
              child: ListView(
                controller: scroll,
                key: PageStorageKey('messages-${thread.id}:${thread.phase}'),
                padding: const EdgeInsets.all(20),
                children: [
                  for (final message in thread.messages)
                    Align(
                      alignment: message.fromRider
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: message.fromRider
                                ? RiderColors.rose
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message.localPreview
                                    ? 'Preview · not sent'
                                    : timeLabel(message.recordedAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (c.readError != null) ...[
                    Text(c.readError!),
                    TextButton(
                      onPressed: () => c.acknowledgeVisibleConversation(
                        thread.id,
                        phase: thread.phase,
                        throughMessageId: thread.messages.last.id,
                      ),
                      child: const Text('Retry read status'),
                    ),
                  ],
                  if (c.sendError != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        c.sendError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (c.conversationData.status != FeatureStatus.ready)
                    const Text(
                      'Refresh the conversation before sending a message.',
                    ),
                ],
              ),
            ),
            Material(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: !thread.canSend
                    ? const Text(
                        'This assignment is read only. New messages are unavailable.',
                      )
                    : compact
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: input),
                          const SizedBox(width: 8),
                          sendButton,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          input,
                          Align(
                            alignment: Alignment.centerRight,
                            child: sendButton,
                          ),
                          if (widget.preview)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Preview messages stay on this device and are not delivered.',
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
