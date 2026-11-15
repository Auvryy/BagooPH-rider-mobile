import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/operations_models.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/saved_delivery_stop.dart';
import 'leaflet_delivery_map.dart';
import 'home_location_controller.dart';
import 'navigation_providers.dart';

/// Dedicated full Map Page for BagooPH Rider Mobile.
/// Displays an unobstructed live road map with all controls and stop
/// details unified in a clean bottom cockpit dock.
class RiderMapPage extends ConsumerStatefulWidget {
  const RiderMapPage({
    super.key,
    this.initialTask,
    this.accountId,
    this.active = true,
  });

  final OperationTask? initialTask;
  final String? accountId;
  final bool active;

  @override
  ConsumerState<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends ConsumerState<RiderMapPage>
    with WidgetsBindingObserver {
  OperationTask? _localTask;
  int _recenterVersion = 0;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _localTask = widget.initialTask;
    WidgetsBinding.instance.addObserver(this);
    _syncForegroundLocation();
  }

  void _syncForegroundLocation() {
    if (!widget.active || !_foreground) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active || !_foreground) return;
      final nav = ref.read(navigationProvider);
      if (!nav.active) {
        ref.read(homeLocationProvider).setVisible(true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant RiderMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active && _foreground) {
        _syncForegroundLocation();
      } else if (!widget.active) {
        ref.read(homeLocationProvider).setVisible(false, notify: false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final resumed = state == AppLifecycleState.resumed;
    if (_foreground != resumed) {
      setState(() => _foreground = resumed);
    }
    if (!widget.active) return;
    if (resumed) {
      _syncForegroundLocation();
    } else {
      ref.read(homeLocationProvider).setVisible(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final homeLoc = ref.watch(homeLocationProvider);
    final workspace = widget.accountId != null
        ? ref.watch(
            workspaceControllerProvider(WorkspaceIdentity(widget.accountId!)),
          )
        : null;

    final activeTask =
        nav.task ??
        _localTask ??
        workspace?.selectedTask ??
        workspace?.taskPage?.items.firstOrNull;
    final stop = activeTask != null
        ? SavedDeliveryStop.fromTask(activeTask)
        : null;
    final isPickup = activeTask?.stop.kind == 'seller';
    final stopKindLabel = isPickup
        ? 'PICKUP · SELLER STORE'
        : 'DELIVERY · BUYER DESTINATION';

    return ListenableBuilder(
      listenable: Listenable.merge([nav, homeLoc]),
      builder: (context, _) {
        final riderPoint = nav.active ? nav.fix?.point : homeLoc.fix?.point;
        final activeRoad = nav.active
            ? nav.road
            : (activeTask != null && nav.previewStopKey == activeTask.id
                  ? nav.previewRoad
                  : null);
        final statusMessage =
            nav.message ??
            nav.previewMessage ??
            (!nav.active && riderPoint == null ? homeLoc.message : null);
        if (widget.active && _foreground && !nav.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !widget.active || !_foreground || nav.active) return;
            homeLoc.setVisible(true);
            if (activeTask != null && stop != null && riderPoint != null) {
              unawaited(nav.syncPreview(origin: riderPoint, task: activeTask));
            }
          });
        }
        return TickerMode(
          enabled: widget.active,
          child: Scaffold(
        key: const ValueKey('rider-live-map-page'),
        backgroundColor: RiderColors.canvas,
        body: Stack(
          children: [
            // Fullscreen Map View
            Positioned.fill(
              child: LeafletDeliveryMap(
                key: const ValueKey('rider-map-leaflet-view'),
                stop: stop,
                road: activeRoad,
                riderPoint: riderPoint,
                standby: stop == null,
                recenterVersion: _recenterVersion,
                onUserPan: nav.pan,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Material(
                        color: RiderColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            RiderRadii.control,
                          ),
                          side: const BorderSide(color: RiderColors.border),
                        ),
                        child: InkWell(
                          key: const ValueKey('rider-map-back-button'),
                          borderRadius: BorderRadius.circular(
                            RiderRadii.control,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: RiderColors.ink,
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
                            borderRadius: BorderRadius.circular(
                              RiderRadii.control,
                            ),
                            boxShadow: RiderShadows.ambient,
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
                            color: RiderColors.surface,
                            borderRadius: BorderRadius.circular(
                              RiderRadii.control,
                            ),
                            border: Border.all(color: RiderColors.border),
                            boxShadow: RiderShadows.ambient,
                          ),
                          child: const Text(
                            'Road Map Overview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: RiderColors.ink,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (nav.calculating ||
                          nav.previewCalculating ||
                          (!nav.active && homeLoc.locating))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.surface,
                            borderRadius: BorderRadius.circular(
                              RiderRadii.control,
                            ),
                            border: Border.all(color: RiderColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: RiderColors.accent,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Calculating…',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: RiderColors.ink,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (nav.active || activeRoad != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: RiderColors.surface,
                            borderRadius: BorderRadius.circular(
                              RiderRadii.control,
                            ),
                            border: Border.all(color: RiderColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.navigation_rounded,
                                size: 13,
                                color: RiderColors.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                nav.active ? 'LIVE GPS' : 'ROAD ROUTE',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: RiderColors.accentText,
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
                    color: RiderColors.surface,
                    borderRadius: BorderRadius.circular(RiderRadii.surface),
                    border: Border.all(color: RiderColors.border),
                    boxShadow: RiderShadows.ambient,
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
                                      color: RiderColors.ink,
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
                                        color: RiderColors.muted,
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
                              onTap: () => nav.setPrioritizeHighways(
                                !nav.prioritizeHighways,
                              ),
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: nav.prioritizeHighways
                                      ? RiderColors.rose
                                      : RiderColors.controlFill,
                                  borderRadius: BorderRadius.circular(
                                    RiderRadii.control,
                                  ),
                                  border: Border.all(
                                    color: nav.prioritizeHighways
                                        ? RiderColors.accent
                                        : RiderColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.alt_route_rounded,
                                      size: 14,
                                      color: nav.prioritizeHighways
                                          ? RiderColors.accentText
                                          : RiderColors.muted,
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
                                            ? RiderColors.accentText
                                            : RiderColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (statusMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: RiderColors.rose,
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              border: Border.all(color: RiderColors.accent),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: RiderColors.accentText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusMessage,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: RiderColors.accentText,
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
                            color: RiderColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select an assigned task or accept a delivery from the queue to start navigation.',
                          style: TextStyle(
                            fontSize: 13,
                            color: RiderColors.muted,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Bottom actions row
                      Row(
                        children: [
                          // Recenter button
                          Material(
                            color: RiderColors.controlFill,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              side: const BorderSide(color: RiderColors.border),
                            ),
                            child: InkWell(
                              key: const ValueKey('rider-map-recenter-button'),
                              onTap: () {
                                nav.recenter();
                                setState(() => _recenterVersion++);
                                if (!nav.active &&
                                    homeLoc.supported &&
                                    homeLoc.fix == null) {
                                  unawaited(
                                    homeLoc.locate(requestPermission: true),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: RiderColors.ink,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Refresh route button
                          Material(
                            color: RiderColors.controlFill,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              side: const BorderSide(color: RiderColors.border),
                            ),
                            child: InkWell(
                              key: const ValueKey('rider-map-refresh-button'),
                              onTap: () {
                                if (nav.active) {
                                  unawaited(nav.refreshRoute(force: true));
                                } else {
                                  if (homeLoc.supported) {
                                    unawaited(
                                      homeLoc.locate(requestPermission: true),
                                    );
                                  }
                                  if (activeTask != null) {
                                    unawaited(
                                      nav.syncPreview(
                                        origin: homeLoc.fix?.point,
                                        task: activeTask,
                                        force: true,
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                RiderRadii.control,
                              ),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: RiderColors.ink,
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
                                borderRadius: BorderRadius.circular(
                                  RiderRadii.control,
                                ),
                                child: InkWell(
                                  key: const ValueKey(
                                    'rider-map-stop-nav-button',
                                  ),
                                  onTap: () async {
                                    await nav.stop();
                                  },
                                  borderRadius: BorderRadius.circular(
                                    RiderRadii.control,
                                  ),
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
                                borderRadius: BorderRadius.circular(
                                  RiderRadii.control,
                                ),
                                child: InkWell(
                                  key: const ValueKey(
                                    'rider-map-start-nav-button',
                                  ),
                                  onTap: () async {
                                    await nav.start(activeTask);
                                  },
                                  borderRadius: BorderRadius.circular(
                                    RiderRadii.control,
                                  ),
                                  child: const SizedBox(
                                    height: 50,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                color: RiderColors.controlFill,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    RiderRadii.control,
                                  ),
                                  side: const BorderSide(
                                    color: RiderColors.border,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(
                                    RiderRadii.control,
                                  ),
                                  child: const SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Close Map',
                                        style: TextStyle(
                                          color: RiderColors.ink,
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
      },
    );
  }
}
