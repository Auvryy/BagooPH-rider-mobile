import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../home/data/operations_models.dart';
import '../data/saved_delivery_stop.dart';
import 'leaflet_delivery_map.dart';
import 'navigation_controller.dart';

/// Fullscreen navigation view optimized for vehicle handlebar mounting.
/// Provides extra-large touch targets, high contrast legibility for riding,
/// highway prioritization controls, and live route tracking.
class FullscreenNavigationPage extends StatelessWidget {
  const FullscreenNavigationPage({
    super.key,
    required this.navigation,
    required this.task,
    required this.stop,
  });

  final NavigationController navigation;
  final OperationTask task;
  final SavedDeliveryStop stop;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: navigation,
    builder: (context, _) {
      final nav = navigation;
      if (!nav.active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.of(context).pop();
          }
        });
      }

      final isPickup = task.stop.kind == 'seller';
      final stopKindLabel = isPickup ? 'PICKUP · SELLER STORE' : 'DELIVERY · BUYER DESTINATION';

      return Scaffold(
        key: const ValueKey('fullscreen-navigation-page'),
        backgroundColor: RiderMapColors.canvas,
        body: Stack(
          children: [
            // Fullscreen Map
            Positioned.fill(
              child: LeafletDeliveryMap(
                key: const ValueKey('fullscreen-delivery-map'),
                stop: stop,
                road: nav.road,
              ),
            ),

            // Top Handlebar Guidance Card
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RiderColors.carbon.withAlpha(235),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: RiderColors.accent,
                              borderRadius: BorderRadius.circular(RiderRadii.pill),
                            ),
                            child: Text(
                              stopKindLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // National highway toggle chip
                          InkWell(
                            key: const ValueKey('handlebar-highways-toggle'),
                            onTap: () => nav.setPrioritizeHighways(!nav.prioritizeHighways),
                            borderRadius: BorderRadius.circular(RiderRadii.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
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
                      const SizedBox(height: 10),
                      Text(
                        task.stop.name ?? 'Assigned stop',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.stop.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.stop.address!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (nav.message != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          nav.message!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFFB3BA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Handlebar Floating Controls (extra-large touch targets)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Recenter button
                      Material(
                        color: RiderColors.carbon.withAlpha(230),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          key: const ValueKey('handlebar-recenter'),
                          onTap: nav.recenter,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Exit fullscreen button
                      Expanded(
                        child: Material(
                          color: RiderColors.carbon.withAlpha(230),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            key: const ValueKey('handlebar-exit-fullscreen'),
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              height: 56,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fullscreen_exit_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Exit Fullscreen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Stop navigation button
                      Material(
                        color: RiderColors.accent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          key: const ValueKey('handlebar-stop-navigation'),
                          onTap: () async {
                            await nav.stop();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
