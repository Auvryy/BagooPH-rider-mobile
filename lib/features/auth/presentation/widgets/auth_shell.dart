import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/argon_widgets.dart';
import '../../../../core/ui/brand_logo.dart';
import '../../../../core/ui/rider_surfaces.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    required this.registering,
    this.scrollController,
  });
  final Widget child;
  final bool registering;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 1024 &&
              MediaQuery.textScalerOf(context).scale(16) <= 23;
          final inset = constraints.maxWidth < 360 ? 20.0 : 28.0;
          final form = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: registering ? 680 : 440),
            child: child,
          );
          return SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(inset, 24, inset, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        const BrandLogo(),
                        DieCutStickerWidget.speechBubble(
                          text: registering ? 'APPLY NOW' : 'COURIER SHIFT',
                          backgroundColor: RiderColors.rose,
                          textColor: RiderColors.accentText,
                          rotationDegrees: -3,
                          leadingIcon: Icons.two_wheeler_rounded,
                        ),
                      ],
                    ),
                    SizedBox(height: wide ? 48 : 32),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _BrandStory(registering: registering),
                          ),
                          const SizedBox(width: 72),
                          Expanded(flex: registering ? 2 : 1, child: form),
                        ],
                      )
                    else
                      Center(child: form),
                    const SizedBox(height: 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: const Text(
                          'Your rider account is reviewed before work becomes available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: RiderColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _BrandStory extends StatelessWidget {
  const _BrandStory({required this.registering});
  final bool registering;

  @override
  Widget build(BuildContext context) => RiderSurface(
    color: RiderColors.rose,
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const LiquidGlassOrb(size: 56, blurSigma: 14),
            DieCutStickerWidget.speechBubble(
              text: "Let's roll.",
              backgroundColor: RiderColors.accent,
              rotationDegrees: -6,
              leadingIcon: Icons.bolt_rounded,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          registering
              ? 'Your next chapter\nstarts here.'
              : 'Every parcel.\nA clear next step.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        Text(
          registering
              ? 'One rider workspace for pickups, deliveries and every handoff in between.'
              : 'See your work, find the right stop and keep every handoff in view.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),
        for (final item in [
          (Icons.inventory_2_outlined, 'Your parcels'),
          (Icons.near_me_outlined, 'Your next stop'),
          (Icons.task_alt_rounded, 'Your next action'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(item.$1, size: 22, color: RiderColors.accentText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
