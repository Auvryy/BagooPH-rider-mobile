import 'package:flutter/material.dart';

import '../data/operations_models.dart';

/// Shows only instructions supplied for the currently authorized stop.
/// Buyer stops stay explicit when checkout has no saved delivery note.
class DoorstepGuide extends StatelessWidget {
  const DoorstepGuide({super.key, required this.task});

  final OperationTask task;

  @override
  Widget build(BuildContext context) {
    if (task.preview) return const SizedBox.shrink();

    final isBuyerStop = task.stop.kind == 'buyer';
    final instructions = task.stop.instructions;
    final hasInstructions = instructions?.trim().isNotEmpty == true;
    if (!isBuyerStop && !hasInstructions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          isBuyerStop ? 'Doorstep Guide' : 'Stop instructions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (hasInstructions)
          SelectableText(instructions!, key: const ValueKey('stop-notes'))
        else
          const Text(
            'No extra instructions provided.',
            key: ValueKey('stop-notes-empty'),
          ),
      ],
    );
  }
}
