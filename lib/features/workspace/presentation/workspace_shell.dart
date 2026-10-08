import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../auth/data/account.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/tasks_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../trips/presentation/trips_page.dart';
import 'workspace_controller.dart';
import 'workspace_widgets.dart';

class RiderWorkspaceShell extends ConsumerStatefulWidget {
  const RiderWorkspaceShell({
    super.key,
    required this.account,
    this.preview = false,
  });
  final RiderAccount account;
  final bool preview;
  @override
  ConsumerState<RiderWorkspaceShell> createState() =>
      _RiderWorkspaceShellState();
}

class _RiderWorkspaceShellState extends ConsumerState<RiderWorkspaceShell>
    with WidgetsBindingObserver {
  int destination = 0;
  ProfileSection profileSection = ProfileSection.profile;
  bool foreground = true;
  static const labels = ['Tasks', 'Trips', 'Messages', 'Profile'];
  static const icons = [
    Icons.inventory_2_outlined,
    Icons.route_outlined,
    Icons.forum_outlined,
    Icons.person_outline_rounded,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => foreground = state == AppLifecycleState.resumed);
    }
  }

  void select(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      destination = index;
      if (index != 3) profileSection = ProfileSection.profile;
    });
  }

  Future<void> logout() async {
    if (widget.preview) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of Rider?'),
        content: const Text(
          'Your local drafts will be cleared after sign-out is confirmed. Parcels and cash assigned to you remain your responsibility.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-logout'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((!widget.account.approved && !widget.preview) ||
        (widget.preview && !kDebugMode)) {
      return const SizedBox.shrink();
    }
    final controller = ref.watch(
      workspaceControllerProvider(
        WorkspaceIdentity(widget.account.id, preview: widget.preview),
      ),
    );
    final session = ref.watch(authControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final typing =
        destination == 2 && MediaQuery.viewInsetsOf(context).bottom > 0;
    final rail = size.width >= 840;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final compactThread =
            destination == 2 &&
            controller.selectedConversationId != null &&
            size.width < 1000;
        final nested =
            destination == 3 && profileSection != ProfileSection.profile;
        return PopScope(
          canPop: !nested && !compactThread && destination == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            FocusScope.of(context).unfocus();
            if (nested) {
              setState(
                () => profileSection = profileSection == ProfileSection.settings
                    ? ProfileSection.profile
                    : ProfileSection.settings,
              );
            } else if (compactThread) {
              controller.selectConversation(null);
            } else if (destination != 0) {
              select(0);
            }
          },
          child: Scaffold(
            key: const ValueKey('rider-workspace'),
            body: SafeArea(
              child: Column(
                children: [
                  if (!typing) _header(session.busy),
                  if (widget.preview && !typing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: RiderColors.rose,
                      child: const Text(
                        'Demo · sample data',
                        style: TextStyle(
                          color: RiderColors.accentText,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!widget.preview && session.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: RiderColors.rose,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          session.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        if (rail && !typing)
                          SizedBox(
                            width: size.width >= 1200 ? 220 : 96,
                            child: _navigation(vertical: true),
                          ),
                        if (rail && !typing)
                          const VerticalDivider(
                            width: 1,
                            color: RiderColors.divider,
                          ),
                        Expanded(
                          child: IndexedStack(
                            index: destination,
                            children: [
                              TasksPage(
                                account: widget.account,
                                controller: controller,
                                preview: widget.preview,
                              ),
                              TripsPage(
                                controller: controller,
                                preview: widget.preview,
                              ),
                              MessagesPage(
                                controller: controller,
                                preview: widget.preview,
                                active: destination == 2 && foreground,
                              ),
                              ProfileSettingsPage(
                                account: widget.account,
                                section: profileSection,
                                preview: widget.preview,
                                onSection: (section) =>
                                    setState(() => profileSection = section),
                                onLogout: logout,
                                onRefresh: widget.preview
                                    ? () {}
                                    : () => ref
                                          .read(authControllerProvider.notifier)
                                          .refresh(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!rail && !typing) _navigation(vertical: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool busy) => Material(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Semantics(
                  image: true,
                  label: 'BagooPH Rider',
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/branding/gooriders-icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'BagooPH Rider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: RiderColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open Profile',
            onPressed: () => select(3),
            icon: WorkspaceAvatar(widget.account.name, size: 32),
          ),
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: widget.preview ? 'Exit preview' : 'Log out',
            onPressed: busy && !widget.preview ? null : logout,
            icon: Icon(
              widget.preview ? Icons.close_rounded : Icons.logout_rounded,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _navigation({required bool vertical}) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    final children = [
      for (var index = 0; index < labels.length; index++)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: vertical ? 8 : 4,
            vertical: 8,
          ),
          child: Semantics(
            selected: destination == index,
            button: true,
            label: labels[index],
            child: Tooltip(
              message: labels[index],
              child: InkWell(
                key: ValueKey('nav-${labels[index].toLowerCase()}'),
                onTap: () => select(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: destination == index
                        ? RiderColors.rose
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExcludeSemantics(
                    child: wide && vertical
                        ? Row(
                            children: [
                              Icon(
                                icons[index],
                                color: destination == index
                                    ? RiderColors.accentText
                                    : RiderColors.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  labels[index],
                                  style: TextStyle(
                                    color: destination == index
                                        ? RiderColors.accentText
                                        : RiderColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[index],
                                color: destination == index
                                    ? RiderColors.accentText
                                    : RiderColors.muted,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                labels[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: destination == index
                                      ? RiderColors.accentText
                                      : RiderColors.muted,
                                  fontWeight: destination == index
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Material(
      color: Colors.white,
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, color: RiderColors.divider),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final child in children) Expanded(child: child),
                  ],
                ),
              ],
            ),
    );
  }
}
