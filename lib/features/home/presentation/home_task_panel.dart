import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/ui/rider_surfaces.dart';
import '../../../core/platform/rider_website.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../data/operations_models.dart';
import '../data/operations_repository.dart';
import 'task_stage_label.dart';
import 'task_payment_instruction.dart';

export 'task_stage_label.dart' show taskStageLabel;

String stopKindLabel(String? kind) => switch (kind) {
  'seller' => 'Seller pickup',
  'origin_hub' => 'Origin hub',
  'destination_hub' => 'Destination hub',
  'buyer' => 'Buyer stop',
  _ => 'Current stop',
};
IconData stopKindIcon(String? kind) => switch (kind) {
  'seller' => Icons.storefront_rounded,
  'origin_hub' || 'destination_hub' => Icons.warehouse_outlined,
  'buyer' => Icons.person_pin_circle_outlined,
  _ => Icons.location_on_outlined,
};

class HomeTaskPanel extends StatefulWidget {
  const HomeTaskPanel({
    super.key,
    required this.controller,
    required this.onSelect,
    required this.onDetails,
    this.scrollController,
    this.asSliver = false,
    this.onQueueChanged,
    this.onShowStop,
    this.header,
    this.searchVisibility,
    this.searchFocusNode,
  });
  final WorkspaceController controller;
  final ValueChanged<RiderTask> onSelect;
  final ValueChanged<OperationTask> onDetails;
  final ScrollController? scrollController;
  final bool asSliver;
  final Widget? header;
  final ValueNotifier<bool>? searchVisibility;
  final FocusNode? searchFocusNode;
  final VoidCallback? onShowStop;
  final ValueChanged<TaskQueue>? onQueueChanged;
  @override
  State<HomeTaskPanel> createState() => _HomeTaskPanelState();
}

class _HomeTaskPanelState extends State<HomeTaskPanel> {
  bool _searching = false;
  final _search = TextEditingController();
  final _ownScroll = ScrollController();
  String? _lastSelection;
  ScrollController get _scroll => widget.scrollController ?? _ownScroll;
  WorkspaceController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    _search.text = widget.controller.taskSearch;
    _searching =
        (widget.searchVisibility?.value ?? false) || _search.text.isNotEmpty;
  }

  @override
  void dispose() {
    _search.dispose();
    _ownScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedTask;
    final waitingForFailedHome =
        controller.homeData.status == FeatureStatus.failed &&
        controller.homeData.data == null &&
        controller.taskData.data == null;
    if (selected?.id != _lastSelection) {
      _lastSelection = selected?.id;
      if (selected != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
        });
      }
    }
    final slivers = <Widget>[
      if (widget.header != null) SliverToBoxAdapter(child: widget.header),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search tasks',
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      widget.searchVisibility?.value = _searching;
                    }),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              if (selected != null) ...[
                const SizedBox(height: 16),
                _SelectedStop(
                  task: selected,
                  onDetails: () => widget.onDetails(selected),
                  onShowStop: widget.onShowStop,
                  onClear: controller.closeTask,
                ),
              ],
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack =
                      constraints.maxWidth < 330 ||
                      MediaQuery.textScalerOf(context).scale(13) > 20;
                  Widget choice(TaskQueue queue) {
                    final key = switch (queue) {
                      TaskQueue.available => 'available',
                      TaskQueue.pickups => 'pickup',
                      TaskQueue.delivery => 'final_mile',
                    };
                    final count = controller.homeData.data?.counts[key];
                    final countLabel = count == null
                        ? 'count unavailable'
                        : controller.homeData.status == FeatureStatus.ready
                        ? '$count tasks'
                        : 'last checked $count tasks';
                    final active = controller.queue == queue;
                    final label = Text(
                      queue.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: stack ? TextAlign.start : TextAlign.center,
                    );
                    final badge = Text(
                      count?.toString() ?? '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    );
                    return Semantics(
                      selected: active,
                      button: true,
                      label: '${queue.label}, $countLabel',
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              RiderRadii.control,
                            ),
                            side: BorderSide(
                              color: active
                                  ? RiderColors.accent
                                  : RiderColors.border,
                              width: 1.5,
                            ),
                          ),
                          shadows: active
                              ? RiderShadows.neumorphicAccent
                              : RiderShadows.neumorphicElevated,
                        ),
                        child: RiderPressFeedback(
                          child: TextButton(
                            key: ValueKey('task-queue-${queue.name}'),
                            onPressed: () {
                              controller.selectQueue(queue);
                              _search.clear();
                              if (_scroll.hasClients) _scroll.jumpTo(0);
                              widget.onQueueChanged?.call(queue);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: active
                                  ? RiderColors.accentText
                                  : RiderColors.muted,
                              backgroundColor: active
                                  ? RiderColors.controlFill
                                  : RiderColors.neumorphicSurface,
                              minimumSize: const Size(0, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  RiderRadii.control,
                                ),
                              ),
                            ),
                            child: stack
                                ? Row(
                                    children: [
                                      Expanded(child: label),
                                      badge,
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      badge,
                                      const SizedBox(height: 6),
                                      label,
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  }

                  return stack
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final queue in TaskQueue.values)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: choice(queue),
                              ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final queue in TaskQueue.values)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: queue == TaskQueue.delivery ? 0 : 8,
                                  ),
                                  child: choice(queue),
                                ),
                              ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              if (controller.homeData.data != null &&
                  controller.homeData.status != FeatureStatus.ready)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Queue counts are from the last Home check.'),
                ),
              if (_searching)
                TextField(
                  controller: _search,
                  focusNode: widget.searchFocusNode,
                  key: const ValueKey('task-search'),
                  enabled: controller.taskData.data != null,
                  onChanged: controller.searchTasks,
                  decoration: const InputDecoration(
                    hintText: 'Find a parcel or stop',
                    labelText: 'Search tasks',
                    prefixIcon: Icon(Icons.search_rounded),
                    helperText: 'Searches loaded tasks in this queue',
                    helperMaxLines: 2,
                  ),
                ),
              if (controller.selectingTask)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Refreshing selected stop',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                controller.queue.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (controller.loadMoreFailure != null) ...[
                Text(
                  'Could not load more tasks. Your loaded tasks are kept.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverToBoxAdapter(
          child: FeatureStateView<List<RiderTask>>(
            data: waitingForFailedHome
                ? const FeatureData.failed(
                    'Check work availability to load this queue.',
                  )
                : controller.taskData,
            icon: Icons.inventory_2_outlined,
            title: 'Tasks',
            website: RiderWebsitePage.tasks,
            onRetry: controller.refreshAll,
            ready: (all) {
              final tasks = controller.visibleTasks;
              if (tasks.isEmpty) {
                return WorkspaceEmpty(
                  all.isEmpty
                      ? 'No tasks in this queue'
                      : 'No matching parcels',
                  all.isEmpty
                      ? 'Refresh when new work is available in your scope.'
                      : 'Try a different parcel reference or stop.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final task in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HomeTaskRow(
                        task: selected?.id == task.id
                            ? OperationsRepository.asRiderTask(selected!)
                            : task,
                        selected: selected?.id == task.id,
                        onSelect: () => widget.onSelect(task),
                      ),
                    ),
                  if (controller.taskPage?.hasNext == true)
                    TextButton(
                      onPressed:
                          controller.loadingMore ||
                              controller.coolingDown ||
                              controller.taskData.status != FeatureStatus.ready
                          ? null
                          : controller.loadMoreTasks,
                      child: Text(
                        controller.loadingMore ? 'Loading…' : 'Load more tasks',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ];
    if (widget.asSliver) return SliverMainAxisGroup(slivers: slivers);
    return CustomScrollView(
      controller: _scroll,
      key: const PageStorageKey('home-task-panel-scroll'),
      slivers: slivers,
    );
  }
}

class HomeTaskRow extends StatelessWidget {
  const HomeTaskRow({
    super.key,
    required this.task,
    required this.selected,
    required this.onSelect,
  });
  final RiderTask task;
  final bool selected;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) => RiderSurface(
    radius: RiderRadii.selection,
    color: selected ? RiderColors.rose : RiderColors.neumorphicSurface,
    child: InkWell(
      key: ValueKey('home-task-${task.id}'),
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? RiderColors.accent : RiderColors.rose,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                stopKindIcon(task.operation?.stop.kind),
                color: selected ? Colors.white : RiderColors.accentText,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.stop,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        task.tracking,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        taskStageLabel(task.operation?.stage ?? task.stage),
                        style: const TextStyle(
                          fontSize: 11,
                          color: RiderColors.muted,
                        ),
                      ),
                      if (selected)
                        const Text(
                          'Selected stop',
                          style: TextStyle(
                            fontSize: 11,
                            color: RiderColors.accentText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: RiderColors.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SelectedStop extends StatelessWidget {
  const _SelectedStop({
    required this.task,
    required this.onDetails,
    required this.onClear,
    this.onShowStop,
  });
  final OperationTask task;
  final VoidCallback onDetails, onClear;
  final VoidCallback? onShowStop;
  @override
  Widget build(BuildContext context) => RiderSurface(
    color: RiderColors.neumorphicSurface,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stopKindLabel(task.stop.kind),
                style: const TextStyle(
                  color: RiderColors.accentText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Clear selected stop',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
        SelectableText(
          task.tracking,
          key: const ValueKey('home-selected-reference'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          children: [
            WorkspaceBadge(
              taskStageLabel(task.stage),
              key: const ValueKey('home-selected-stage'),
              accent: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          task.stop.name ?? 'Stop name unavailable',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(task.stop.address ?? 'Address unavailable'),
        const SizedBox(height: 10),
        Text(
          task.nextInstruction,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TaskPaymentInstruction(task: task),
        if (task.stop.latitude == null || task.stop.longitude == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Address only · no saved map pin',
              style: TextStyle(fontSize: 12, color: RiderColors.muted),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.icon(
              key: const ValueKey('home-selected-details'),
              onPressed: onDetails,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(task.preview ? 'View pickup' : 'Work this stop'),
            ),
            if (task.stop.latitude != null && task.stop.longitude != null)
              TextButton.icon(
                onPressed: onShowStop,
                icon: const Icon(Icons.location_searching_rounded, size: 18),
                label: const Text('Show stop'),
              ),
          ],
        ),
      ],
    ),
  );
}
