import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/platform/rider_website.dart';
import '../../auth/data/account.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({
    super.key,
    required this.account,
    required this.controller,
    required this.preview,
  });
  final RiderAccount account;
  final WorkspaceController controller;
  final bool preview;
  @override
  Widget build(BuildContext context) => WorkspaceBody(
    storageKey: 'tasks-scroll',
    children: [
      WorkspaceHeading(
        'Welcome, ${account.name}.',
        'A clear handoff, every step of the way.',
        action: IconButton(
          onPressed: controller.refreshTasks,
          tooltip: 'Refresh tasks',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const WorkspaceBadge('Rider account approved', accent: true),
          WorkspaceBadge(dayLabel(DateTime.now())),
          if (!preview) const WorkspaceBadge('Work availability not connected'),
        ],
      ),
      const SizedBox(height: 28),
      Text('Your tasks', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final queue in TaskQueue.values)
            Semantics(
              selected: controller.queue == queue,
              child: OutlinedButton(
                key: ValueKey('task-queue-${queue.name}'),
                onPressed: () => controller.selectQueue(queue),
                style: OutlinedButton.styleFrom(
                  backgroundColor: controller.queue == queue
                      ? RiderColors.rose
                      : Colors.white,
                  foregroundColor: controller.queue == queue
                      ? RiderColors.accentText
                      : RiderColors.muted,
                  side: BorderSide(
                    color: controller.queue == queue
                        ? RiderColors.accentText
                        : RiderColors.divider,
                  ),
                ),
                child: Text(queue.label, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text(controller.queue.description),
      const SizedBox(height: 20),
      TextField(
        key: const ValueKey('task-search'),
        enabled: controller.taskData.data != null,
        onChanged: controller.searchTasks,
        decoration: const InputDecoration(
          labelText: 'Find a parcel',
          hintText: 'Parcel reference or stop',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 24),
      FeatureStateView<List<RiderTask>>(
        data: controller.taskData,
        icon: Icons.inventory_2_outlined,
        title: 'Tasks',
        onRetry: controller.refreshTasks,
        website: RiderWebsitePage.tasks,
        ready: (all) {
          final tasks = controller.visibleTasks;
          if (tasks.isEmpty) {
            return WorkspaceEmpty(
              all.isEmpty ? 'No tasks in this queue' : 'No matching parcels',
              all.isEmpty
                  ? 'New work appears here when it is available in your scope.'
                  : 'Try a different parcel reference or stop.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tasks.length; i++) ...[
                TaskCard(
                  task: tasks[i],
                  prominent: i == 0,
                  prominentLabel: controller.queue == TaskQueue.available
                      ? 'Available pickup'
                      : 'Next responsibility',
                  onOpen: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    backgroundColor: RiderColors.canvas,
                    builder: (_) => SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Parcel details',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            TaskCard(
                              task: tasks[i],
                              prominent: true,
                              prominentLabel:
                                  controller.queue == TaskQueue.available
                                  ? 'Available pickup'
                                  : 'Next responsibility',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              preview
                                  ? 'Sample parcel only. Pickup, handoff and delivery actions are not performed in this preview.'
                                  : 'Parcel actions become available only after the work service confirms your permission.',
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back to tasks'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: RiderColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview
                  ? 'Each queue is a separate sample scenario. No live assignment or availability is changed.'
                  : 'Account approval, logistics placement and work availability are separate checks.',
            ),
          ),
        ],
      ),
    ],
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.prominent = false,
    this.prominentLabel = 'Next responsibility',
    this.onOpen,
  });
  final RiderTask task;
  final bool prominent;
  final String prominentLabel;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => WorkspacePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            WorkspaceBadge(task.stage, accent: true),
            if (prominent) WorkspaceBadge(prominentLabel),
          ],
        ),
        const SizedBox(height: 18),
        SelectableText(
          task.tracking,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: RiderColors.accentText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.stop,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(task.address),
                ],
              ),
            ),
          ],
        ),
        if (task.cashCentavos != null) ...[
          const SizedBox(height: 18),
          Text('Recorded cash to collect: ${pesos(task.cashCentavos!)}'),
        ],
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Text('Next step', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(task.nextStep, style: Theme.of(context).textTheme.titleMedium),
        if (onOpen != null) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('View parcel'),
          ),
        ],
      ],
    ),
  );
}
