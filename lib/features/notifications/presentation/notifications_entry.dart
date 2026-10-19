import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import 'notifications_page.dart';

class NotificationsEntry extends StatefulWidget {
  const NotificationsEntry({
    super.key,
    required this.work,
    required this.active,
  });
  final WorkspaceController work;
  final bool active;
  @override
  State<NotificationsEntry> createState() => _NotificationsEntryState();
}

class _NotificationsEntryState extends State<NotificationsEntry> {
  final _surface = Object();
  ModalRoute<dynamic>? _route;
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
      widget.work.notifications.setSurfaceActive(
        _surface,
        widget.active && (_route?.isCurrent ?? true),
      );
    }
  });
  @override
  void didUpdateWidget(NotificationsEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work != widget.work) {
      oldWidget.work.notifications.setSurfaceActive(_surface, false);
    }
    if (oldWidget.work != widget.work || oldWidget.active != widget.active) {
      _sync();
    }
  }

  @override
  void dispose() {
    widget.work.notifications.setSurfaceActive(_surface, false);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.work.notifications,
    builder: (context, _) {
      final c = widget.work.notifications;
      final count = c.inbox.status == FeatureStatus.ready
          ? c.unreadCount
          : null;
      final subtitle = count == null
          ? 'View your updates'
          : count == 0
          ? 'All caught up'
          : '$count unread';
      return OutlinedButton(
        key: const ValueKey('open-notifications'),
        onPressed: widget.active
            ? () => openNotifications(context, widget.work)
            : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.all(12),
        ),
        child: Semantics(
          label: 'Notifications. $subtitle',
          excludeSemantics: true,
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, color: RiderColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: RiderColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: RiderColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const ShapeDecoration(
                    color: RiderColors.redTint,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: RiderColors.accentText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: RiderColors.muted),
            ],
          ),
        ),
      );
    },
  );
}
