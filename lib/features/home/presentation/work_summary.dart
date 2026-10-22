import '../../cash/presentation/cash_page.dart';

import 'package:flutter/material.dart';

import '../../../core/ui/rider_surfaces.dart';
import '../../../app/theme.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../../workspace/presentation/workspace_widgets.dart';

class WorkSummary extends StatelessWidget {
  const WorkSummary({
    super.key,
    required this.controller,
    this.compact = false,
    this.showDuty = true,
  });
  final WorkspaceController controller;
  final bool compact;
  final bool showDuty;

  String _placement(String kind, String? id, String? name) => id == null
      ? '$kind not assigned'
      : name == null || name.trim().isEmpty
      ? '$kind name unavailable'
      : name;

  @override
  Widget build(BuildContext context) {
    final state = controller.homeData;
    final home = state.data;
    final supportingStyle = compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;
    final eligibility = switch (home?.claimDenial) {
      'PLACEMENT_UNAVAILABLE' =>
        'Your company or hub assignment needs attention.',
      'OFF_DUTY' => 'Go on duty to claim new pickups.',
      'PICKUP_CAPACITY' => 'Your pickup capacity is full.',
      'OTHER_ACTIVE_WORK' =>
        'Finish your current delivery before claiming a pickup.',
      null =>
        home == null
            ? null
            : home.canClaim
            ? 'Eligible for new pickup claims.'
            : home.operational
            ? 'New pickup claims are unavailable.'
            : 'Your work eligibility needs confirmation.',
      _ => 'Pickup availability needs confirmation.',
    };
    final freshness = switch (state.status) {
      FeatureStatus.loading => 'Checking work availability…',
      FeatureStatus.refreshing =>
        'Refreshing work · showing last checked data.',
      FeatureStatus.failed =>
        home == null
            ? 'Could not check work availability.'
            : 'Refresh failed · showing last checked data.',
      FeatureStatus.unavailable => 'Work availability unavailable.',
      FeatureStatus.ready => null,
    };
    return RiderSurface(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (home != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final placement = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: ShapeDecoration(
                        color: RiderColors.rose,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      child: const Icon(
                        Icons.warehouse_outlined,
                        size: 20,
                        color: RiderColors.accentText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _placement('Hub', home.hubId, home.hub),
                            key: const ValueKey('home-hub'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _placement('Company', home.companyId, home.company),
                            key: const ValueKey('home-company'),
                            style: supportingStyle,
                          ),
                          Text(
                            home.barangay == null ||
                                    home.barangay!.trim().isEmpty
                                ? 'Coverage not assigned'
                                : home.barangay!,
                            style: supportingStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final duty = WorkDutyControl(controller: controller);
                if (!showDuty) return placement;
                if (constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [placement, duty],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: placement),
                    const SizedBox(width: 12),
                    duty,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                WorkspaceBadge(
                  'Pickup slots: ${home.capacity['active_pickups']} of ${home.capacity['pickup_limit']} in use',
                ),
                WorkspaceBadge(
                  '${home.capacity['remaining_pickups']} slots remaining',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(eligibility!, style: supportingStyle),
            if (!home.onDuty)
              Text(
                'Existing pickups and assigned deliveries remain your responsibility.',
                style: supportingStyle,
              ),
            if (controller.operations?.writesVerified != true)
              Text(
                'Work actions are currently unavailable.',
                style: supportingStyle,
              ),
          ] else
            Text('Pickup capacity unavailable.', style: supportingStyle),
          if (freshness != null)
            Semantics(
              liveRegion: true,
              child: Text(freshness, style: supportingStyle),
            ),
          if (state.message != null) Text(state.message!),
          if (home != null) ...[
            const SizedBox(height: 12),
            Text(
              'Home checked ${dayLabel(home.observedAt)} · ${timeLabel(home.observedAt)} PHT',
              key: const ValueKey('home-checked-time'),
              style: supportingStyle,
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: RiderPressFeedback(
              child: Tooltip(
                message: 'Refresh tasks',
                child: TextButton.icon(
                  key: const ValueKey('home-refresh-tasks'),
                  onPressed: controller.canRefresh
                      ? controller.refreshAll
                      : null,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    state.status == FeatureStatus.loading ||
                            state.status == FeatureStatus.refreshing
                        ? 'Checking work…'
                        : controller.coolingDown
                        ? 'Refresh available shortly'
                        : 'Refresh work',
                  ),
                ),
              ),
            ),
          ),
          if (controller.workFailure != null &&
              controller.workFailure!.message != state.message)
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
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: controller.working || controller.coolingDown
                      ? null
                      : () => controller.checkPending(),
                  child: const Text('Check saved request'),
                ),
                if (controller.pendingIntent!.isCash)
                  TextButton(
                    onPressed: controller.working || controller.coolingDown
                        ? null
                        : () => openCash(
                            context,
                            controller,
                            accountId: controller.pendingIntent!.resource
                                .substring(5),
                          ),
                    child: const Text('Review original cash offer'),
                  )
                else
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
      ),
    );
  }
}

/// The same server-gated availability control is used in the compact Home header.
class WorkDutyControl extends StatelessWidget {
  const WorkDutyControl({super.key, required this.controller});
  final WorkspaceController controller;
  @override
  Widget build(BuildContext context) {
    final home = controller.homeData.data;
    if (home == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: ShapeDecoration(
        color: home.onDuty ? RiderColors.rose : RiderColors.controlFill,
        shape: const StadiumBorder(
          side: BorderSide(color: Colors.white, width: 1.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              home.onDuty ? 'On duty' : 'Off duty',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: home.onDuty ? RiderColors.accentText : RiderColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Duty availability',
            child: Switch(
              value: home.onDuty,
              onChanged:
                  controller.canWrite && home.capabilities['duty'] == true
                  ? controller.setDuty
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
