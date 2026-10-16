import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/argon_widgets.dart';
import '../../../core/ui/brand_logo.dart';

/// Tracks whether the user has completed or dismissed the initial Argon onboarding
/// greeting in the current app session.
class OnboardingSeenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markSeen() => state = true;
  void reset() => state = false;
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);

/// Production-ready 60fps interactive "Bagoo Argon" onboarding screen combining
/// Neo-Skeuomorphic die-cut courier stickers, a 72x72 LiquidGlassOrb, animated
/// editorial strikethrough typography, and 4-stage spring physics choreography.
class RiderOnboardingPage extends ConsumerStatefulWidget {
  const RiderOnboardingPage({
    super.key,
    this.onContinue,
    this.onApply,
    this.enableContinuousDriftInTests = false,
    this.ambientTimeOverride,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onApply;
  final bool enableContinuousDriftInTests;
  final double? ambientTimeOverride;

  /// The 6 curated, uncluttered courier-themed die-cut stickers arranged with
  /// generous breathing room around the central 72x72 LiquidGlassOrb.
  static List<ArgonStickerSpec> buildStickers() => [
    ArgonStickerSpec(
      id: 'speech-roll',
      alignment: const Alignment(-0.55, -0.68),
      rotationDegrees: 0,
      zIndex: 1.25,
      phaseOffset: 0.0,
      driftSpeed: 1.6,
      semanticLabel: "Let's roll.",
      child: DieCutStickerWidget.speechBubble(
        key: const ValueKey('sticker-speech-roll'),
        text: "Let's roll.",
        backgroundColor: RiderColors.accent,
        textColor: Colors.white,
        rotationDegrees: 0,
        leadingIcon: Icons.bolt_rounded,
      ),
    ),
    ArgonStickerSpec(
      id: 'speech-clear',
      alignment: const Alignment(0.55, -0.68),
      rotationDegrees: 0,
      zIndex: 1.20,
      phaseOffset: 1.1,
      driftSpeed: 1.8,
      semanticLabel: 'Every stop clear!',
      child: DieCutStickerWidget.speechBubble(
        key: const ValueKey('sticker-speech-clear'),
        text: 'Every stop clear!',
        backgroundColor: RiderColors.surface,
        textColor: RiderColors.ink,
        rotationDegrees: 0,
        leadingIcon: Icons.verified_rounded,
      ),
    ),
    ArgonStickerSpec(
      id: 'flash-dispatch',
      alignment: const Alignment(-0.58, -0.15),
      rotationDegrees: 0,
      zIndex: 1.15,
      phaseOffset: 0.6,
      driftSpeed: 1.7,
      semanticLabel: 'Express route priority',
      child: DieCutStickerWidget.iconCutout(
        key: const ValueKey('sticker-flash-dispatch'),
        icon: Icons.flash_on_rounded,
        fill: RiderColors.redTint,
        iconColor: RiderColors.accent,
        badgeText: 'EXPRESS',
        rotationDegrees: 0,
      ),
    ),
    ArgonStickerSpec(
      id: 'waybill-tag',
      alignment: const Alignment(0.58, -0.15),
      rotationDegrees: 0,
      zIndex: 1.15,
      phaseOffset: 1.7,
      driftSpeed: 1.5,
      semanticLabel: 'Waybill verified tag',
      child: DieCutStickerWidget.iconCutout(
        key: const ValueKey('sticker-waybill-tag'),
        icon: Icons.local_offer_rounded,
        fill: RiderColors.surface,
        iconColor: RiderColors.carbon,
        badgeText: 'WAYBILL OK',
        rotationDegrees: 0,
      ),
    ),
    ArgonStickerSpec(
      id: 'delivery-scooter',
      alignment: const Alignment(-0.35, 0.32),
      rotationDegrees: 0,
      zIndex: 1.10,
      phaseOffset: 2.5,
      driftSpeed: 1.9,
      semanticLabel: 'Delivery scooter',
      child: DieCutStickerWidget.iconCutout(
        key: const ValueKey('sticker-delivery-scooter'),
        icon: Icons.two_wheeler_rounded,
        fill: RiderColors.surface,
        iconColor: RiderColors.ink,
        rotationDegrees: 0,
      ),
    ),
    ArgonStickerSpec(
      id: 'route-pin',
      alignment: const Alignment(0.35, 0.32),
      rotationDegrees: 0,
      zIndex: 1.10,
      phaseOffset: 3.2,
      driftSpeed: 1.8,
      semanticLabel: 'Live Stop Mode GPS pin',
      child: DieCutStickerWidget.iconCutout(
        key: const ValueKey('sticker-route-pin'),
        icon: Icons.location_on_rounded,
        fill: RiderColors.redTint,
        iconColor: RiderColors.accent,
        rotationDegrees: 0,
      ),
    ),
  ];

  @override
  ConsumerState<RiderOnboardingPage> createState() =>
      _RiderOnboardingPageState();
}

class _RiderOnboardingPageState extends ConsumerState<RiderOnboardingPage>
     with TickerProviderStateMixin {
  static final List<ArgonStickerSpec> _stickers =
      RiderOnboardingPage.buildStickers();

  /// Stage 1, 2, 4 master choreography timeline (`0ms – 1300ms`).
  late final AnimationController _choreography;

  /// Stage 3 continuous sinusoidal zero-gravity drift clock.
  late final AnimationController _ambientDrift;

  /// Spring-driven 2D magnetic touch/drag parallax controllers.
  late final AnimationController _parallaxX;
  late final AnimationController _parallaxY;

  /// Spring-driven radial scatter pulse when tapping the 72x72 LiquidGlassOrb.
  late final AnimationController _scatterPulse;

  bool get _isTestBinding =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _choreography = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _ambientDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _parallaxX = AnimationController.unbounded(vsync: this, value: 0);
    _parallaxY = AnimationController.unbounded(vsync: this, value: 0);
    _scatterPulse = AnimationController.unbounded(vsync: this, value: 0);

    _choreography.forward();
    if (!_isTestBinding || widget.enableContinuousDriftInTests) {
      _ambientDrift.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (RiderMotion.reduced(context)) {
      _choreography.value = 1.0;
      _ambientDrift.stop();
      _parallaxX.value = 0;
      _parallaxY.value = 0;
      _scatterPulse.value = 0;
    }
  }

  @override
  void dispose() {
    _choreography.dispose();
    _ambientDrift.dispose();
    _parallaxX.dispose();
    _parallaxY.dispose();
    _scatterPulse.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size vortexSize) {
    if (RiderMotion.reduced(context)) return;
    final dx = (_parallaxX.value + details.delta.dx * 0.55).clamp(-36.0, 36.0);
    final dy = (_parallaxY.value + details.delta.dy * 0.55).clamp(-28.0, 28.0);
    _parallaxX.value = dx;
    _parallaxY.value = dy;
  }

  void _onPanEnd(DragEndDetails _) {
    if (RiderMotion.reduced(context)) return;
    const spring = SpringDescription(mass: 1, stiffness: 240, damping: 18);
    _parallaxX.animateWith(
      SpringSimulation(spring, _parallaxX.value, 0, _parallaxX.velocity),
    );
    _parallaxY.animateWith(
      SpringSimulation(spring, _parallaxY.value, 0, _parallaxY.velocity),
    );
  }

  /// Tapping the central 72x72 LiquidGlassOrb scatters stickers outward by 15px
  /// before springing back via `SpringSimulation`.
  void _triggerOrbScatter() {
    if (RiderMotion.reduced(context)) return;
    _scatterPulse.value = 1.0;
    const spring = SpringDescription(mass: 1, stiffness: 260, damping: 14);
    _scatterPulse.animateWith(SpringSimulation(spring, 1.0, 0.0, -4.2));
  }

  void _completeToLogin() {
    ref.read(onboardingSeenProvider.notifier).markSeen();
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openRegister() {
    ref.read(onboardingSeenProvider.notifier).markSeen();
    if (widget.onApply != null) {
      widget.onApply!();
      return;
    }
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    final reduced = RiderMotion.reduced(context);
    final merged = Listenable.merge([
      _choreography,
      _ambientDrift,
      _parallaxX,
      _parallaxY,
      _scatterPulse,
    ]);

    return Scaffold(
      key: const ValueKey('rider-onboarding-page'),
      backgroundColor: RiderColors.pureWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight =
                constraints.maxHeight < 620 ||
                MediaQuery.textScalerOf(context).scale(16) > 20;

            return AnimatedBuilder(
              animation: merged,
              builder: (context, _) {
                final t = reduced ? 1.0 : _choreography.value;

                // Stage 1 (0ms - 600ms): Iridescent Splash Transition from bottom-left to center
                final splashProgress = Curves.easeOutCubic.transform(
                  (t / (600 / 1300)).clamp(0.0, 1.0),
                );

                // Stage 4 (800ms - 1300ms): Typographic Strike & Reveal
                final headlineOpacity = Curves.easeOut.transform(
                  ((t - (800 / 1300)) / (250 / 1300)).clamp(0.0, 1.0),
                );
                final strikeProgress = Curves.easeInOutCubic.transform(
                  ((t - (1000 / 1300)) / (180 / 1300)).clamp(0.0, 1.0),
                );
                final rawReveal = ((t - (1060 / 1300)) / (240 / 1300)).clamp(
                  0.0,
                  1.0,
                );
                final revealScale = reduced
                    ? 1.0
                    : Curves.easeOutBack.transform(rawReveal);

                final ambientSeconds =
                    widget.ambientTimeOverride ??
                    (_ambientDrift.value * 2 * math.pi);

                final zoneA = _buildZoneAVortex(
                  context: context,
                  splashProgress: splashProgress,
                  masterTime: t,
                  ambientSeconds: ambientSeconds,
                  reduced: reduced,
                );
                final zoneB = _buildZoneBTypography(
                  headlineOpacity: headlineOpacity,
                  strikeProgress: strikeProgress,
                  revealScale: revealScale,
                );
                final zoneC = _buildZoneCActions(
                  context: context,
                  entranceOpacity: headlineOpacity,
                );

                if (compactHeight) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topBar(context),
                            const SizedBox(height: 12),
                            SizedBox(height: 310, child: zoneA),
                            const SizedBox(height: 16),
                            zoneB,
                            const SizedBox(height: 20),
                            zoneC,
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Standard 3-Zone Top-to-Bottom Stack / Flex Architecture (55% / 25% / 20%)
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone A: Top 55% of screen — Floating Sticker Vortex + Central 72x72 LiquidGlassOrb
                        Expanded(
                          flex: 55,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(child: zoneA),
                              Positioned(
                                top: 12,
                                left: 20,
                                right: 20,
                                child: _topBar(context),
                              ),
                            ],
                          ),
                        ),
                        // Zone B: Middle 25% of screen — Editorial Typography Core
                        Expanded(
                          flex: 25,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Center(child: zoneB),
                          ),
                        ),
                        // Zone C: Bottom 20% of screen — Bottom Action Bar
                        Expanded(
                          flex: 20,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Center(child: zoneC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const BrandLogo(),
        DieCutStickerWidget.speechBubble(
          text: 'COURIER V4',
          backgroundColor: RiderColors.redTint,
          textColor: RiderColors.accentText,
          rotationDegrees: 0,
        ),
      ],
    );
  }

  /// Zone A (Top 55%): Funnel-shaped constellation of courier stickers
  /// cascading toward the central 72x72 LiquidGlassOrb.
  Widget _buildZoneAVortex({
    required BuildContext context,
    required double splashProgress,
    required double masterTime,
    required double ambientSeconds,
    required bool reduced,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final orbAnchor = Offset(width * 0.50, height * 0.80);

        // Stage 1 off-center bottom-left splash origin morphing to orbAnchor
        final splashOrigin = Offset(width * 0.14, height * 1.18);
        final currentOrbCenter = Offset.lerp(
          splashOrigin,
          orbAnchor,
          splashProgress,
        )!;
        final orbScale = reduced ? 1.0 : (2.25 - 1.25 * splashProgress);

        return GestureDetector(
          key: const ValueKey('onboarding-sticker-vortex'),
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) =>
              _onPanUpdate(details, Size(width, height)),
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle funnel guide lines / ambient aura behind the stickers
              Positioned(
                left: orbAnchor.dx - 120,
                top: orbAnchor.dy - 140,
                child: IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          RiderColors.accent.withValues(alpha: 0.06),
                          RiderColors.accent.withValues(alpha: 0.015),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Curated E-Commerce / Courier Stickers (Stage 2 Cascade + Stage 3 Drift)
              for (var i = 0; i < _stickers.length; i++)
                _buildAnimatedSticker(
                  spec: _stickers[i],
                  index: i,
                  vortexSize: Size(width, height),
                  orbAnchor: orbAnchor,
                  masterTime: masterTime,
                  ambientSeconds: ambientSeconds,
                  reduced: reduced,
                ),

              // Central Anchor (Bottom of Vortex): 72x72 circular LiquidGlassOrb
              Positioned(
                left: currentOrbCenter.dx - 36,
                top: currentOrbCenter.dy - 36,
                child: Transform.scale(
                  scale: orbScale,
                  child: LiquidGlassOrb(
                    key: const ValueKey('onboarding-liquid-orb'),
                    size: 72,
                    blurSigma: 16.0,
                    rippleProgress: _scatterPulse.value.clamp(0.0, 1.0),
                    onTap: _triggerOrbScatter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSticker({
    required ArgonStickerSpec spec,
    required int index,
    required Size vortexSize,
    required Offset orbAnchor,
    required double masterTime,
    required double ambientSeconds,
    required bool reduced,
  }) {
    // Stage 2 (300ms – 1100ms): Staggered eruption from behind the central orb
    final staggerStart = (300 + index * 48) / 1300;
    final staggerEnd = (760 + index * 52).clamp(300, 1100) / 1300;
    final rawCascade = ((masterTime - staggerStart) /
            (staggerEnd - staggerStart))
        .clamp(0.0, 1.0);
    final cascadeCurve = reduced
        ? 1.0
        : Curves.easeOutBack.transform(rawCascade);

    // Target funnel coordinate inside Zone A
    final targetX =
        vortexSize.width * 0.5 +
        spec.alignment.x * (vortexSize.width * 0.38);
    final targetY =
        vortexSize.height * 0.46 +
        spec.alignment.y * (vortexSize.height * 0.34);
    final targetOffset = Offset(targetX, targetY);

    final eruptedOffset = Offset.lerp(orbAnchor, targetOffset, cascadeCurve)!;

    // Stage 3: Ambient Zero-Gravity Drift (Y-axis ±4px, rotation 0°)
    final phase = ambientSeconds * spec.driftSpeed + spec.phaseOffset;
    final bobY = reduced ? 0.0 : math.sin(phase) * 4.0;

    // Interactive 2D Magnetic Parallax + Orb Tap Scatter (15px radial impulse)
    final parallaxOffset = Offset(
      _parallaxX.value * spec.zIndex,
      _parallaxY.value * spec.zIndex,
    );
    final radialVector = targetOffset - orbAnchor;
    final radialDistance = radialVector.distance;
    final unitRadial = radialDistance > 1
        ? radialVector / radialDistance
        : const Offset(0, -1);
    final scatterOffset = unitRadial * (15.0 * _scatterPulse.value);

    final finalCenter =
        eruptedOffset + Offset(0, bobY) + parallaxOffset + scatterOffset;

    return Positioned(
      left: finalCenter.dx - 54,
      top: finalCenter.dy - 24,
      child: Opacity(
        opacity: rawCascade.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.35 + 0.65 * cascadeCurve).clamp(0.0, 1.25),
          child: Center(child: spec.child),
        ),
      ),
    );
  }

  /// Zone B (Middle 25%): Editorial Typography Core (`Plus Jakarta Sans`, 26sp, w600, 1.25)
  Widget _buildZoneBTypography({
    required double headlineOpacity,
    required double strikeProgress,
    required double revealScale,
  }) {
    return AnimatedStrikeText(
      key: const ValueKey('onboarding-editorial-text'),
      line1: 'Go beyond the',
      struckWord: 'ordinary',
      replacementWord: 'every route',
      line3: 'to deliver every parcel right',
      headlineOpacity: headlineOpacity,
      strikeProgress: strikeProgress,
      revealScale: revealScale,
    );
  }

  /// Zone C (Bottom 20%): Pill-shaped CTA button (`height: 56px`, `width: 75%`, `borderRadius: 999`)
  Widget _buildZoneCActions({
    required BuildContext context,
    required double entranceOpacity,
  }) {
    return Opacity(
      opacity: entranceOpacity.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArgonPillButton(
            key: const ValueKey('onboarding-cta'),
            label: 'Start Rider Shift',
            icon: Icons.arrow_forward_rounded,
            widthFactor: 0.75,
            onPressed: _completeToLogin,
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('onboarding-apply-link'),
            onPressed: _openRegister,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              foregroundColor: RiderColors.muted,
            ),
            child: const Text(
              'New to BagooPH? Apply as a rider',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
