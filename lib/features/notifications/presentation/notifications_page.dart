import '../../cash/presentation/cash_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../company/presentation/company_page.dart';
import '../../home/data/operations_repository.dart';
import '../../home/presentation/stop_mode_page.dart';
import '../../navigation/presentation/navigation_providers.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/notification_models.dart';
import 'notification_resource_page.dart';
import 'notifications_controller.dart';
import 'notification_format.dart';

Future<void> openNotifications(
  BuildContext context,
  WorkspaceController work,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        ref.listen(
          authControllerProvider.select(
            (s) => (
              id: s.user?.id,
              approved: s.user?.approved,
              version: s.user?.operationsApiVersion,
              initialized: !s.initializing,
            ),
          ),
          (previous, next) {
            if (previous == null || !previous.initialized || previous == next) {
              return;
            }
            work.notifications.revoke(
              'Please sign in again to view notifications.',
            );
            work.closeTask();
            final route = ModalRoute.of(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted || route == null || !route.isActive) return;
              final navigator = Navigator.of(context);
              navigator.popUntil((candidate) => identical(candidate, route));
              navigator.removeRoute(route);
            });
          },
        );
        return NotificationsPage(work: work);
      },
    ),
  ),
);

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key, required this.work});
  final WorkspaceController work;
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with WidgetsBindingObserver {
  final _surface = Object();
  final _viewport = GlobalKey();
  final _detail = GlobalKey();
  final _anchors = <String, GlobalKey>{};
  final _scroll = ScrollController();
  Set<String> _visible = {};
  int _measuredRevision = -1;
  ModalRoute<dynamic>? _route;
  bool _foreground = true, _scheduled = false;
  NotificationsController get c => widget.work.notifications;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_scheduleMeasure);
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
    _sync();
  }

  void _routeChanged(AnimationStatus _) => _sync();
  void _sync() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      c.setSurfaceActive(
        _surface,
        _foreground && (_route?.isCurrent ?? true),
        inbox: true,
      );
    }
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    c.setForeground(_foreground);
    _sync();
  }

  void _scheduleMeasure() {
    if (_scheduled) return;
    _scheduled = true;
    final revision = c.revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          !_foreground ||
          !(_route?.isCurrent ?? true) ||
          revision != c.revision) {
        return;
      }
      final box = _viewport.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      final bounds = box.localToGlobal(Offset.zero) & box.size;
      final visible = <String>{};
      if (c.selected case final item?) {
        final detail = _detail.currentContext?.findRenderObject();
        if (detail is RenderBox &&
            detail.hasSize &&
            detail.attached &&
            bounds.overlaps(detail.localToGlobal(Offset.zero) & detail.size)) {
          visible.add(item.id);
        }
      } else {
        for (final item in c.inbox.data ?? <RiderNotification>[]) {
          final row = _anchors[item.id]?.currentContext?.findRenderObject();
          if (row is! RenderBox || !row.hasSize || !row.attached) continue;
          final rect = row.localToGlobal(Offset.zero) & row.size;
          if (rect.top >= bounds.top &&
              rect.bottom <= bounds.bottom &&
              rect.left >= bounds.left &&
              rect.right <= bounds.right) {
            visible.add(item.id);
          }
        }
      }
      c.setDisplayed(_surface, visible, revision);
      if (!setEquals(_visible, visible) || _measuredRevision != revision) {
        setState(() {
          _visible = visible;
          _measuredRevision = revision;
        });
      }
    });
  }

  void _select(RiderNotification? item) {
    c.select(item);
    _visible = {};
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _openTarget() async {
    final item = c.selected;
    final destination = await c.resolveSelected();
    if (!mounted ||
        !_foreground ||
        !(_route?.isCurrent ?? true) ||
        destination == null ||
        item?.id != c.selected?.id) {
      return;
    }
    switch (destination) {
      case NotificationTaskDestination(:final task):
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => StopModePage(
              initialTask: OperationsRepository.asRiderTask(task),
              controller: widget.work,
              navigation: ref.read(navigationProvider),
            ),
          ),
        );
      case NotificationCashDestination(:final cash):
        await openCash(context, widget.work, accountId: cash.id);
      case NotificationAccountDestination():
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => NotificationResourcePage(
              controller: c,
              target: item!.target!,
              initial: destination,
            ),
          ),
        );
      case NotificationCompanyDestination(
        :final accountId,
        :final applicationId,
      ):
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => RiderCompanyPage(
              accountId: accountId,
              applicationId: applicationId,
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    c.setSurfaceActive(_surface, false);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      _scheduleMeasure();
      final selected = c.selected;
      final items = c.inbox.data ?? <RiderNotification>[];
      _anchors.removeWhere((id, _) => !items.any((item) => item.id == id));
      return PopScope(
        canPop: selected == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && selected != null) _select(null);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(selected == null ? 'Inbox' : 'Your update'),
            leading: IconButton(
              tooltip: selected == null
                  ? 'Back to Home'
                  : 'Back to notifications',
              onPressed: () => selected == null
                  ? Navigator.of(context).maybePop()
                  : _select(null),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              if (selected == null)
                IconButton(
                  key: const ValueKey('read-visible-notifications'),
                  tooltip: 'Mark visible notifications as read',
                  onPressed: c.canWrite && c.displayedUnreadIds.isNotEmpty
                      ? () => c.acknowledgeDisplayed(
                          c.displayedUnreadIds,
                          c.revision,
                        )
                      : null,
                  icon: const Icon(Icons.done_all_rounded),
                ),
              IconButton(
                tooltip: 'Refresh notifications',
                onPressed: c.canRefresh ? c.refresh : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SizedBox(
                    key: _viewport,
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: CustomScrollView(
                      controller: _scroll,
                      key: const ValueKey('notifications-scroll'),
                      slivers: [
                        if (selected == null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Updates for your work',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      c.unreadCount == null
                                          ? 'Unread count unavailable until refreshed'
                                          : '${c.unreadCount} unread notifications',
                                      style: const TextStyle(
                                        color: RiderColors.muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Use the check button to mark only on-screen notifications as read.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: RiderColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (c.inbox.status == FeatureStatus.refreshing)
                          const SliverToBoxAdapter(
                            child: LinearProgressIndicator(
                              semanticsLabel: 'Refreshing notifications',
                            ),
                          ),
                        if (c.pendingIntent != null)
                          SliverToBoxAdapter(
                            child: _message(
                              'A read request needs checking',
                              'Its original notification list is saved. Check its result before starting another read.',
                              actions: [
                                OutlinedButton(
                                  onPressed:
                                      c.inboxActive &&
                                          !c.working &&
                                          !c.coolingDown
                                      ? c.reconcile
                                      : null,
                                  child: const Text('Check saved read'),
                                ),
                                if (c.commandUnknown)
                                  OutlinedButton(
                                    onPressed: c.canRetryOriginal
                                        ? () => c.reconcile(retryUnknown: true)
                                        : null,
                                    child: const Text('Retry original read'),
                                  ),
                              ],
                            ),
                          ),
                        if (c.readError != null)
                          SliverToBoxAdapter(
                            child: _message(
                              'Read status not confirmed',
                              c.readError!,
                            ),
                          ),
                        if (c.notice != null)
                          SliverToBoxAdapter(
                            child: _message('Read status', c.notice!),
                          ),
                        if (c.inbox.status == FeatureStatus.failed ||
                            c.inbox.status == FeatureStatus.unavailable)
                          SliverToBoxAdapter(
                            child: _message(
                              c.inbox.status == FeatureStatus.failed
                                  ? 'Could not refresh'
                                  : 'Notifications unavailable',
                              c.inbox.message ?? 'Try again later.',
                            ),
                          ),
                        if (c.inbox.status == FeatureStatus.loading && c.active)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: 'Loading notifications',
                                ),
                              ),
                            ),
                          ),
                        if (selected != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: RiderSurface(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  key: _detail,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      selected.unread
                                          ? 'Unread update'
                                          : 'Read update',
                                      style: const TextStyle(
                                        color: RiderColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      selected.heading,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notificationTime(selected.recordedAt),
                                      style: const TextStyle(
                                        color: RiderColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (selected.body?.isNotEmpty == true) ...[
                                      const SizedBox(height: 24),
                                      Text(
                                        selected.body!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      key: const ValueKey(
                                        'read-one-notification',
                                      ),
                                      onPressed:
                                          c.canWrite &&
                                              c.displayedUnreadIds.contains(
                                                selected.id,
                                              )
                                          ? () => c.acknowledgeDisplayed([
                                              selected.id,
                                            ], c.revision)
                                          : null,
                                      icon: Icon(
                                        selected.unread
                                            ? Icons.check_rounded
                                            : Icons.done_all_rounded,
                                      ),
                                      label: Text(
                                        selected.unread
                                            ? 'Mark as read'
                                            : 'Read status saved',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (selected.target != null)
                                      OutlinedButton.icon(
                                        key: const ValueKey(
                                          'open-notification-target',
                                        ),
                                        onPressed:
                                            c.inboxActive &&
                                                !c.resolving &&
                                                !c.working &&
                                                !c.coolingDown &&
                                                c.inbox.status ==
                                                    FeatureStatus.ready
                                            ? _openTarget
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                        ),
                                        label: Text(
                                          c.resolving
                                              ? 'Checking access…'
                                              : switch (selected.target!.kind) {
                                                  'task' => 'Open current task',
                                                  'cash' => 'View cash record',
                                                  _ => 'View account status',
                                                },
                                        ),
                                      )
                                    else
                                      const Text(
                                        'No current in-app destination is available for this update.',
                                        style: TextStyle(
                                          color: RiderColors.muted,
                                        ),
                                      ),
                                    if (c.targetError != null) ...[
                                      const SizedBox(height: 16),
                                      Semantics(
                                        liveRegion: true,
                                        child: Text(c.targetError!),
                                      ),
                                    ],
                                    if (!c.repository.writesVerified) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Read status updates are waiting for service verification.',
                                        style: TextStyle(
                                          color: RiderColors.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (selected == null &&
                            items.isEmpty &&
                            c.inbox.status == FeatureStatus.ready)
                          SliverToBoxAdapter(
                            child: _message(
                              c.unreadCount == 0
                                  ? 'You’re all caught up'
                                  : 'No notifications loaded',
                              'Refresh to check for the latest updates.',
                            ),
                          ),
                        if (selected == null)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RepaintBoundary(
                                    key: _anchors.putIfAbsent(
                                      item.id,
                                      GlobalKey.new,
                                    ),
                                    child: TextButton(
                                      key: ValueKey('notification-${item.id}'),
                                      onPressed: c.working
                                          ? null
                                          : () => _select(item),
                                      style: TextButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        backgroundColor: RiderColors.surface,
                                        padding: const EdgeInsets.all(16),
                                        shape: RoundedSuperellipseBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: const BorderSide(
                                            color: RiderColors.border,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ExcludeSemantics(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: ShapeDecoration(
                                                color: item.unread
                                                    ? RiderColors.redTint
                                                    : RiderColors.controlFill,
                                                shape:
                                                    RoundedSuperellipseBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                              ),
                                              child: Icon(
                                                item.unread
                                                    ? Icons
                                                          .notifications_outlined
                                                    : Icons.done_all_rounded,
                                                size: 20,
                                                color: item.unread
                                                    ? RiderColors.accent
                                                    : RiderColors.muted,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.unread
                                                      ? 'Unread'
                                                      : 'Read',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: RiderColors.muted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.heading,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: RiderColors.ink,
                                                    fontWeight: item.unread
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (item.body?.isNotEmpty ==
                                                    true) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    item.body!,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: RiderColors.body,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 12),
                                                Text(
                                                  notificationTime(
                                                    item.recordedAt,
                                                  ),
                                                  style: const TextStyle(
                                                    color: RiderColors.muted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (selected == null && c.moreError != null)
                          SliverToBoxAdapter(
                            child: _message(
                              'Could not load more',
                              c.moreError!,
                            ),
                          ),
                        if (selected == null && c.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: OutlinedButton(
                                onPressed:
                                    !c.loadingMore &&
                                        !c.working &&
                                        !c.coolingDown
                                    ? c.loadMore
                                    : null,
                                child: Text(
                                  c.loadingMore
                                      ? 'Loading…'
                                      : 'Load more notifications',
                                ),
                              ),
                            ),
                          ),
                        if (selected == null &&
                            items.length >= NotificationsController.maxLoaded &&
                            c.pagination?.hasMore == true)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Showing the latest 200 loaded notifications. Refresh to check the newest updates.',
                              ),
                            ),
                          ),
                        if (selected == null &&
                            items.isNotEmpty &&
                            !c.repository.writesVerified)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Read status updates are waiting for service verification.',
                                style: TextStyle(color: RiderColors.muted),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _message(
    String title,
    String text, {
    List<Widget> actions = const [],
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: RiderSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(text),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    ),
  );
}
