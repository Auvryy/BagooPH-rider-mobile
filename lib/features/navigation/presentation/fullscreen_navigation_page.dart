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

            // Top Minimal Floating Status Bar (Unobstructed View)
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
                      // Back / Exit button
                      Material(
                        color: RiderColors.carbon.withAlpha(220),
                        shape: const CircleBorder(),
                        child: InkWell(
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
                      // Stop kind badge
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
                      ),
                      const Spacer(),
                      // Calculation or live indicator
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
                      // Stop Title and Highway Toggle Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          // Highway Toggle Chip
                          InkWell(
                            key: const ValueKey('handlebar-highways-toggle'),
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

                      const SizedBox(height: 14),

                      // Handlebar Action Controls Row
                      Row(
                        children: [
                          // Recenter button
                          Material(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              key: const ValueKey('handlebar-recenter'),
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

                          // Exit fullscreen button
                          Expanded(
                            child: Material(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                key: const ValueKey('handlebar-exit-fullscreen'),
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(14),
                                child: const SizedBox(
                                  height: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fullscreen_exit_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Exit Fullscreen',
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
                          ),
                          const SizedBox(width: 10),

                          // Stop navigation button
                          Material(
                            color: RiderColors.accent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              key: const ValueKey('handlebar-stop-navigation'),
                              onTap: () async {
                                await nav.stop();
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 26,
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
      );
    },
  );
}
