import 'package:flutter/material.dart';

import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class WorkSummary extends StatelessWidget {
  const WorkSummary({
    super.key,
    required this.controller,
    this.compact = false,
  });
  final WorkspaceController controller;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final home = controller.homeData.data;
    final eligibility = switch (home?.claimDenial) {
      'PLACEMENT_UNAVAILABLE' => 'Your hub assignment needs attention.',
      'OFF_DUTY' => 'Go on duty to claim new pickups.',
      'PICKUP_CAPACITY' => 'Your pickup capacity is full.',
      'OTHER_ACTIVE_WORK' =>
        'Finish your current delivery before claiming a pickup.',
      null =>
        home == null
            ? null
            : '${home.capacity['active_pickups']} of ${home.capacity['pickup_limit']} pickup slots in use',
      _ => 'Pickup availability needs confirmation.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (home != null) ...[
          if (compact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.warehouse_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        home.hub ?? 'Hub not assigned',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (home.barangay != null)
                        Text(
                          home.barangay!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      home.onDuty ? 'On duty' : 'Off duty',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Semantics(
                      label: 'Duty availability',
                      child: Switch(
                        value: home.onDuty,
                        onChanged:
                            controller.canWrite &&
                                home.capabilities['duty'] == true
                            ? controller.setDuty
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
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
          if (!compact)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(home.onDuty ? 'On duty' : 'Off duty'),
              subtitle: Text(eligibility ?? 'Work eligibility unavailable'),
              value: home.onDuty,
              onChanged:
                  controller.canWrite && home.capabilities['duty'] == true
                  ? controller.setDuty
                  : null,
            ),
          if (compact && eligibility != null)
            Text(eligibility, style: Theme.of(context).textTheme.bodySmall),
          if (controller.homeData.status != FeatureStatus.ready)
            const Text('Work data needs refresh before starting an action.'),
          if (controller.operations?.writesVerified != true)
            Text(
              compact
                  ? 'Work actions are currently unavailable.'
                  : 'Work actions are awaiting deployment verification.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
