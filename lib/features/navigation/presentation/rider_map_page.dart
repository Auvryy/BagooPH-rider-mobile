import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/saved_delivery_stop.dart';
import 'leaflet_delivery_map.dart';
import 'navigation_providers.dart';

/// Dedicated full Map Page for BagooPH Rider Mobile.
/// Displays an unobstructed live road map with all controls and stop
/// details unified in a clean bottom cockpit dock.
class RiderMapPage extends ConsumerStatefulWidget {
  const RiderMapPage({
    super.key,
    this.initialTask,
    this.accountId,
  });

  final OperationTask? initialTask;
  final String? accountId;

  @override
  ConsumerState<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends ConsumerState<RiderMapPage> {
  OperationTask? _localTask;

  @override
  void initState() {
    super.initState();
    _localTask = widget.initialTask;
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final workspace = widget.accountId != null
        ? ref.watch(workspaceControllerProvider(WorkspaceIdentity(widget.accountId!)))
        : null;

    final activeTask = nav.task ??
        _localTask ??
        workspace?.selectedTask ??
        workspace?.taskPage?.items.firstOrNull;
    final stop = activeTask != null ? SavedDeliveryStop.fromTask(activeTask) : null;
    final isPickup = activeTask?.stop.kind == 'seller';
    final stopKindLabel = isPickup ? 'PICKUP · SELLER STORE' : 'DELIVERY · BUYER DESTINATION';

    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) => Scaffold(
        key: const ValueKey('rider-live-map-page'),
        backgroundColor: RiderMapColors.canvas,
        body: Stack(
          children: [
            // Fullscreen Map View
            Positioned.fill(
              child: LeafletDeliveryMap(
                key: const ValueKey('rider-map-leaflet-view'),
                stop: stop,
                road: nav.road,
              ),
            ),

            // Top Minimal Floating Bar (Unobstructed View)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Material(
                        color: RiderColors.carbon.withAlpha(220),
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: const ValueKey('rider-map-back-button'),
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (activeTask != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.accent,
                            borderRadius: BorderRadius.circular(RiderRadii.pill),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            stopKindLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.carbon.withAlpha(220),
                            borderRadius: BorderRadius.circular(RiderRadii.pill),
                          ),
                          child: const Text(
                            'Road Map Overview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (nav.calculating)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.carbon.withAlpha(220),
                            borderRadius: BorderRadius.circular(RiderRadii.pill),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Calculating…',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (nav.active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.carbon.withAlpha(220),
                            borderRadius: BorderRadius.circular(RiderRadii.pill),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.navigation_rounded,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'LIVE GPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Consolidated Cockpit Menu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RiderColors.carbon.withAlpha(240),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeTask != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeTask.stop.name ?? 'Assigned stop',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (activeTask.stop.address != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      activeTask.stop.address!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Highway prioritization toggle
                            InkWell(
                              key: const ValueKey('rider-map-highway-toggle'),
                              onTap: () => nav.setPrioritizeHighways(!nav.prioritizeHighways),
                              borderRadius: BorderRadius.circular(RiderRadii.pill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: nav.prioritizeHighways
                                      ? RiderColors.accentText.withAlpha(50)
                                      : Colors.white12,
                                  borderRadius: BorderRadius.circular(RiderRadii.pill),
                                  border: Border.all(
                                    color: nav.prioritizeHighways
                                        ? RiderColors.accent
                                        : Colors.white30,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.alt_route_rounded,
                                      size: 14,
                                      color: nav.prioritizeHighways
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      nav.prioritizeHighways
                                          ? 'Highway: ON'
                                          : 'Highway: OFF',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: nav.prioritizeHighways
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (nav.message != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFFFFB3BA),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    nav.message!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFFB3BA),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        const Text(
                          'No active delivery stop',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select an assigned task or accept a delivery from the queue to start navigation.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Bottom actions row
                      Row(
                        children: [
                          // Recenter button
                          Material(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              key: const ValueKey('rider-map-recenter-button'),
                              onTap: nav.recenter,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Refresh route button
                          Material(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              key: const ValueKey('rider-map-refresh-button'),
                              onTap: () => nav.refreshRoute(force: true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Primary action: Navigate or Exit
                          if (nav.active)
                            Expanded(
                              child: Material(
                                color: RiderColors.accent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  key: const ValueKey('rider-map-stop-nav-button'),
                                  onTap: () async {
                                    await nav.stop();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: const SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Stop Live Map',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (activeTask != null)
                            Expanded(
                              child: Material(
                                color: RiderColors.accent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  key: const ValueKey('rider-map-start-nav-button'),
                                  onTap: () async {
                                    await nav.start(activeTask);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: const SizedBox(
                                    height: 50,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.navigation_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Start Live Map',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Material(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(14),
                                  child: const SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Close Map',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
