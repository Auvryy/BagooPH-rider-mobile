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
    backgroundColor: RiderColors.canvas,
    body: RiderCanvas(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 1024 &&
                MediaQuery.textScalerOf(context).scale(16) <= 23;
            final inset = constraints.maxWidth < 360 ? 14.0 : 20.0;
            final cardPad = constraints.maxWidth < 420 ? 14.0 : 28.0;
            final form = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: registering ? 720 : 460),
              child: RiderSurface(
                color: RiderColors.neumorphicSurface,
                radius: RiderRadii.surface,
                padding: EdgeInsets.all(cardPad),
                child: child,
              ),
            );
            return SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(inset, 18, inset, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiderSurface(
                        color: RiderColors.neumorphicSurface,
                        radius: RiderRadii.pill,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            const BrandLogo(),
                            if (registering)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: RiderColors.rose,
                                  borderRadius:
                                      BorderRadius.circular(RiderRadii.pill),
                                  border: Border.all(
                                    color: RiderColors.outline,
                                  ),
                                ),
                                child: const Text(
                                  'REGISTRATION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: RiderColors.accentText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: wide ? 36 : 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BrandStory(registering: registering),
                            ),
                            const SizedBox(width: 48),
                            Expanded(flex: registering ? 2 : 1, child: form),
                          ],
                        )
                      else
                        Center(child: form),
                      const SizedBox(height: 20),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: ShapeDecoration(
                              color: RiderColors.controlFill,
                              shape: const StadiumBorder(
                                side: BorderSide(color: Colors.white),
                              ),
                            ),
                            child: const Text(
                              'Your rider account is reviewed before work becomes available.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: RiderColors.muted,
                              ),
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
    ),
  );
}

class _BrandStory extends StatelessWidget {
  const _BrandStory({required this.registering});
  final bool registering;

  @override
  Widget build(BuildContext context) => RiderSurface(
    color: RiderColors.neumorphicSurface,
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
              rotationDegrees: 0,
              leadingIcon: Icons.bolt_rounded,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          registering
              ? 'Your next chapter\nstarts here.'
              : 'Every parcel.\nA clear next step.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          registering
              ? 'One rider workspace for pickups, deliveries and every handoff in between.'
              : 'See your work, find the right stop and keep every handoff in view.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        for (final item in [
          (Icons.inventory_2_outlined, 'Your parcels', 'Live waybill queue'),
          (Icons.near_me_outlined, 'Your next stop', 'Turn-by-turn dispatch'),
          (Icons.task_alt_rounded, 'Your next action', 'Verified custody pod'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: ShapeDecoration(
                color: RiderColors.controlFill,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(RiderRadii.control),
                  side: const BorderSide(color: Colors.white, width: 1.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: RiderColors.rose,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(
                      item.$1,
                      size: 20,
                      color: RiderColors.accentText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: RiderColors.ink,
                          ),
                        ),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: RiderColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

