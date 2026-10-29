import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../auth/data/account.dart';
import '../../cash/presentation/cash_page.dart';
import '../../cash/presentation/financial_summary.dart';
import '../../handover/presentation/handover_entry.dart';
import '../../navigation/presentation/leaflet_delivery_map.dart';
import '../../navigation/data/saved_delivery_stop.dart';
import '../../navigation/presentation/navigation_providers.dart';
import '../../notifications/presentation/notifications_entry.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/operations_repository.dart';
import 'home_task_panel.dart';
import 'tasks_page.dart';
import 'work_summary.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({
    super.key,
    required this.account,
    required this.controller,
    this.active = true,
  });
  final RiderAccount account;
  final WorkspaceController controller;
  final bool active;
  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _searchVisible = ValueNotifier(false);
  final _searchFocus = FocusNode();
  bool _foreground = true;
  bool _sampleExpanded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _searchVisible.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Widget _tasks({bool sliver = false, Widget? header}) => HomeTaskPanel(
    controller: widget.controller,
    asSliver: sliver,
    scrollController: sliver ? _scroll : null,
    selectedFooter: widget.controller.selectedTask == null ? null : _map(),
    header: header,
    searchVisibility: _searchVisible,
    searchFocusNode: _searchFocus,
    onSelect: (task) => unawaited(widget.controller.openTask(task)),
    onDetails: (task) => TasksPage(
      account: widget.account,
      controller: widget.controller,
      preview: false,
      navigation: ref.read(navigationProvider),
    ).openParcel(context, OperationsRepository.asRiderTask(task)),
  );
  Widget _map() {
    final task = widget.controller.selectedTask;
    final stop = SavedDeliveryStop.fromTask(task);
    return RiderSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                stop == null ? Icons.map_outlined : Icons.location_on_outlined,
                size: 18,
                color: RiderColors.accentText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task == null
                      ? 'Map illustration'
                      : task.preview
                      ? 'Pickup preview'
                      : 'Current stop',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (task != null) ...[
            const SizedBox(height: 8),
            Text(task.stop.name ?? stopKindLabel(task.stop.kind)),
            if (stop == null) ...[
              const SizedBox(height: 6),
              const Text(
                'No location pin is saved for this stop. Use the recorded address in parcel details.',
                style: TextStyle(
                  fontSize: 12,
                  color: RiderColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ],
          if (stop != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 280, child: _mapView(stop: stop)),
            const SizedBox(height: 10),
            const Text(
              'Saved parcel location. This is not live rider tracking or a calculated road route.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: RiderColors.muted,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('home-sample-toggle'),
                onPressed: () =>
                    setState(() => _sampleExpanded = !_sampleExpanded),
                icon: Icon(
                  _sampleExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  _sampleExpanded ? 'Hide sample map' : 'Show sample map',
                ),
              ),
            ),
            if (_sampleExpanded) ...[
              SizedBox(height: 280, child: _mapView()),
              const SizedBox(height: 10),
              const Text(
                'Sample rider → Sample delivery point',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Illustration only. This is not a live rider or an assigned parcel.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: RiderColors.muted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _mapView({SavedDeliveryStop? stop}) => _foreground
      ? LeafletDeliveryMap(key: const ValueKey('home-leaflet-map'), stop: stop)
      : const Center(child: Text('Map paused while the app is hidden.'));
  Widget _assignment() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WorkSummary(
        controller: widget.controller,
        compact: true,
        showDuty: false,
      ),
      if (widget.controller.homeData.data?.shift case final shift?) ...[
        if (shift.id != null || !shift.canClose) ...[
          const SizedBox(height: 12),
          RiderShiftSummaryPanel(
            shift: shift,
            onCash: () => unawaited(openCash(context, widget.controller)),
          ),
        ],
      ],
      HandoverEntry(
        home: widget.controller.homeData.data,
        accountId: widget.account.id,
        enabled: widget.controller.homeData.status == FeatureStatus.ready,
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (!widget.active || ModalRoute.isCurrentOf(context) == false) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 1000 &&
              constraints.maxHeight >= 600 &&
              MediaQuery.textScalerOf(context).scale(14) <= 21;
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${widget.account.name}.',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.account.approved &&
                    widget.controller.homeData.data == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Rider account approved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: RiderColors.muted,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: WorkDutyControl(controller: widget.controller),
                ),
                const SizedBox(height: 8),
                NotificationsEntry(
                  work: widget.controller,
                  active: widget.active && _foreground,
                ),
              ],
            ),
          );
          if (wide) {
            return Column(
              children: [
                header,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _tasks()),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _assignment(),
                                if (widget.controller.selectedTask == null) ...[
                                  const SizedBox(height: 16),
                                  _map(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return CustomScrollView(
            key: const ValueKey('home-page-scroll'),
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: header),
              _tasks(sliver: true),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _assignment(),
                ),
              ),
              if (widget.controller.selectedTask == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: _map(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
