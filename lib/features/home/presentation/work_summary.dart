import 'package:flutter/material.dart';

import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class WorkSummary extends StatelessWidget {
  const WorkSummary({super.key, required this.controller});
  final WorkspaceController controller;
  @override
  Widget build(BuildContext context) {
    final home = controller.homeData.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (home != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WorkspaceBadge(home.hub ?? 'Hub not assigned'),
              if (home.barangay != null) WorkspaceBadge(home.barangay!),
              WorkspaceBadge(
                'Available ${home.counts['available']} · Pickups ${home.counts['pickup']} · Delivery ${home.counts['final_mile']}',
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(home.onDuty ? 'On duty' : 'Off duty'),
            subtitle: Text(
              home.claimDenial ??
                  '${home.capacity['remaining_pickups']} pickup places remaining',
            ),
            value: home.onDuty,
            onChanged: controller.canWrite && home.capabilities['duty'] == true
                ? controller.setDuty
                : null,
          ),
          if (controller.homeData.status != FeatureStatus.ready)
            const Text('Work data needs refresh before starting an action.'),
          if (controller.operations?.writesVerified != true)
            const Text('Work actions are awaiting deployment verification.'),
        ] else
          Text(controller.homeData.message ?? 'Loading work availability…'),
        if (controller.workFailure != null)
          Text(
            controller.workFailure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (controller.workNotice != null) Text(controller.workNotice!),
        if (controller.pendingIntent != null) ...[
          const Text(
            'A saved work request needs checking before another can start.',
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: controller.working || controller.coolingDown
                    ? null
                    : () => controller.checkPending(),
                child: const Text('Check saved request'),
              ),
              TextButton(
                onPressed: controller.working || controller.coolingDown
                    ? null
                    : () => controller.checkPending(retryUnknown: true),
                child: const Text('Retry original request'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
