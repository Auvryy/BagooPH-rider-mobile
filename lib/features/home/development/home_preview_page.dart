import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/ui/brand_logo.dart';
import 'home_preview_data.dart';

/// An isolated layout preview: no auth provider, token store or API client.
class HomePreviewPage extends StatefulWidget {
  const HomePreviewPage({super.key});

  @override
  State<HomePreviewPage> createState() => _HomePreviewPageState();
}

class _HomePreviewPageState extends State<HomePreviewPage> {
  HomePreviewQueue _queue = HomePreviewQueue.available;

  @override
  Widget build(BuildContext context) {
    final tasks = homePreviewTasks[_queue]!;
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('home-preview'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const ValueKey('exit-home-preview'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Exit demo'),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RiderColors.rose,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RiderColors.divider),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo mode · sample data',
                          style: TextStyle(
                            color: RiderColors.accentText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Explore the Home layout without signing in. '
                          'Each filter shows a separate sample scenario.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Hi, Demo Rider.',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Your next stop starts here.'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final queue in HomePreviewQueue.values)
                        Semantics(
                          selected: queue == _queue,
                          child: OutlinedButton(
                            key: ValueKey('preview-queue-${queue.name}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: queue == _queue
                                  ? RiderColors.accentText
                                  : RiderColors.ink,
                              backgroundColor: queue == _queue
                                  ? RiderColors.rose
                                  : Colors.white,
                              side: BorderSide(
                                color: queue == _queue
                                    ? RiderColors.accentText
                                    : RiderColors.border,
                              ),
                            ),
                            onPressed: () => setState(() => _queue = queue),
                            child: Text(
                              queue.label,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(_queue.label, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_queue.description),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final task in tasks)
                            SizedBox(
                              width: width,
                              child: _PreviewTaskCard(task: task),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sample tasks are for layout review. '
                    'Pickup, scanning and delivery actions are not performed here.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewTaskCard extends StatelessWidget {
  const _PreviewTaskCard({required this.task});
  final HomePreviewTask task;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: RiderColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.tracking, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Text(
          task.stage,
          style: const TextStyle(
            color: RiderColors.accentText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, color: RiderColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.stop,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(task.address),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text('Next step: ${task.nextStep}'),
      ],
    ),
  );
}
