import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ui/argon_widgets.dart';
import '../../../core/ui/brand_logo.dart';

/// Tracks whether the user has completed or dismissed the initial onboarding
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

/// Production-ready 60fps interactive onboarding screen featuring a minimalist
/// vector delivery route (Origin Hub pin, Stop pin, glowing crimson path, and
/// animated courier motorcycle), a 72x72 LiquidGlassOrb anchor, animated
/// editorial strikethrough typography, and spring physics micro-interactions.
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

  @override
  ConsumerState<RiderOnboardingPage> createState() =>
      _RiderOnboardingPageState();
}

class _RiderOnboardingPageState extends ConsumerState<RiderOnboardingPage>
    with TickerProviderStateMixin {
  /// Stage 1, 2, 4 master choreography timeline (`0ms – 1300ms`).
  late final AnimationController _choreography;

  /// Stage 3 continuous cruising loop clock.
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
      duration: const Duration(seconds: 10),
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

  /// Tapping the 72x72 LiquidGlassOrb triggers a tactile pulse across the route.
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

                final zoneA = _buildZoneAMapRoute(
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

                // Standard 3-Zone Architecture (55% / 25% / 20%)
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone A: Top 55% of screen — Minimalist Map Route + Motor + Pins + LiquidGlassOrb
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
    return const Align(
      alignment: Alignment.centerLeft,
      child: BrandLogo(),
    );
  }

  /// Zone A: Interactive Minimalist Map Route Canvas with Origin Hub Pin, Stop Pin,
  /// glowing crimson delivery polyline, and animated courier motorcycle.
  Widget _buildZoneAMapRoute({
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

        final startPin = Offset(width * 0.18, height * 0.28);
        final endPin = Offset(width * 0.82, height * 0.68);

        final routePath = Path()
          ..moveTo(startPin.dx, startPin.dy)
          ..cubicTo(
            width * 0.38,
            height * 0.12,
            width * 0.44,
            height * 0.86,
            endPin.dx,
            endPin.dy,
          );

        final metric = routePath.computeMetrics().first;
        final totalLength = metric.length;

        // Dynamic route drawing progress (0.0 to 1.0)
        final drawProgress = reduced
            ? 1.0
            : Curves.easeInOutCubic.transform(
                (masterTime / (850 / 1300)).clamp(0.0, 1.0),
              );
        final drawnPath = metric.extractPath(0.0, totalLength * drawProgress);

        // Motorcycle position along the route
        final motorProgress = reduced
            ? 0.72
            : (masterTime < 0.75
                ? (masterTime / 0.75).clamp(0.0, 0.72)
                : (0.18 + 0.64 * ((math.sin(ambientSeconds * 1.2) + 1.0) / 2.0)));

        final tangent = metric.getTangentForOffset(totalLength * motorProgress);
        final motorPos =
            tangent?.position ?? Offset.lerp(startPin, endPin, motorProgress)!;
        final motorAngle = tangent?.angle ?? 0.0;

        final parallax = Offset(_parallaxX.value, _parallaxY.value);
        final pulse = _scatterPulse.value;

        // Central LiquidGlassOrb anchor position
        final orbAnchor = Offset(width * 0.50, height * 0.82);
        final splashOrigin = Offset(width * 0.14, height * 1.18);
        final currentOrbCenter = Offset.lerp(
          splashOrigin,
          orbAnchor,
          splashProgress,
        )!;
        final orbScale = reduced ? 1.0 : (2.25 - 1.25 * splashProgress);

        return GestureDetector(
          key: const ValueKey('onboarding-map-canvas'),
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) =>
              _onPanUpdate(details, Size(width, height)),
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Vector Map Canvas: grid lines, streets, and dynamic glowing crimson path
              Positioned.fill(
                child: CustomPaint(
                  painter: _RiderMapRoutePainter(
                    drawnPath: drawnPath,
                    fullPath: routePath,
                    startPin: startPin,
                    endPin: endPin,
                    parallax: parallax,
                    pulse: pulse,
                    reduced: reduced,
                  ),
                ),
              ),

              // 2. Hub A Pin (Origin)
              Positioned(
                left: startPin.dx + parallax.dx - 40,
                top: startPin.dy + parallax.dy - 34,
                child: _buildHubPin(),
              ),

              // 3. Stop 1 Pin (Destination)
              Positioned(
                left: endPin.dx + parallax.dx - 44,
                top: endPin.dy + parallax.dy - 34,
                child: _buildDestinationPin(),
              ),

              // 4. Animated Courier Motorcycle Marker
              Positioned(
                left: motorPos.dx + parallax.dx - 24,
                top: motorPos.dy + parallax.dy - 24,
                child: _buildMotorMarker(
                  motorAngle: motorAngle,
                  reduced: reduced,
                  pulse: pulse,
                ),
              ),

              // 5. Central 72x72 LiquidGlassOrb anchor control
              Positioned(
                left: currentOrbCenter.dx + parallax.dx * 0.4 - 36,
                top: currentOrbCenter.dy + parallax.dy * 0.4 - 36,
                child: Transform.scale(
                  scale: orbScale,
                  child: LiquidGlassOrb(
                    key: const ValueKey('onboarding-liquid-orb'),
                    size: 72,
                    blurSigma: 16.0,
                    rippleProgress: pulse.clamp(0.0, 1.0),
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

  Widget _buildHubPin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RiderRadii.pill),
        border: Border.all(color: RiderColors.outline, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10111827),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: RiderColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'HUB A',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: RiderColors.ink,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RiderColors.ink,
        borderRadius: BorderRadius.circular(RiderRadii.pill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18111827),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: RiderColors.accent,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'STOP 1',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorMarker({
    required double motorAngle,
    required bool reduced,
    required double pulse,
  }) {
    return Semantics(
      label: 'Courier motorcycle on route',
      child: Transform.rotate(
        angle: reduced ? 0.0 : motorAngle,
        child: Container(
          key: const ValueKey('onboarding-motor-marker'),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: RiderColors.accent, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: RiderColors.accent.withValues(alpha: 0.24 + 0.16 * pulse),
                blurRadius: 14 + 8 * pulse,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: RiderColors.accent,
                  ),
                ),
              ),
              const Icon(
                Icons.two_wheeler_rounded,
                color: RiderColors.accent,
                size: 24,
              ),
            ],
          ),
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

/// Minimalist vector painter drawing architectural map grids, road avenues,
/// and the glowing crimson polyline path.
class _RiderMapRoutePainter extends CustomPainter {
  const _RiderMapRoutePainter({
    required this.drawnPath,
    required this.fullPath,
    required this.startPin,
    required this.endPin,
    required this.parallax,
    required this.pulse,
    required this.reduced,
  });

  final Path drawnPath;
  final Path fullPath;
  final Offset startPin;
  final Offset endPin;
  final Offset parallax;
  final double pulse;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(parallax.dx * 0.45, parallax.dy * 0.45);

    // 1. Minimalist architectural road network grid
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 44.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Secondary avenue contours in light slate
    final avenuePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final avenue1 = Path()
      ..moveTo(0, size.height * 0.22)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.18,
        size.width * 0.70,
        size.height * 0.35,
        size.width,
        size.height * 0.30,
      );
    canvas.drawPath(avenue1, avenuePaint);

    final avenue2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.65,
        size.width * 0.60,
        size.height * 0.85,
        size.width,
        size.height * 0.78,
      );
    canvas.drawPath(avenue2, avenuePaint);

    canvas.restore();

    canvas.save();
    canvas.translate(parallax.dx, parallax.dy);

    // 3. Prospective / dashed track of the delivery route
    final prospectivePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, prospectivePaint);

    // 4. Glowing ambient halo behind the active route
    final glowPaint = Paint()
      ..color = const Color(0x28E00D42)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(drawnPath, glowPaint);

    // 5. Crisp Primary Crimson Delivery Polyline
    final routePaint = Paint()
      ..color = RiderColors.accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(drawnPath, routePaint);

    // 6. Pulse ripples at Hub and Destination
    if (!reduced && pulse > 0) {
      final ripplePaint = Paint()
        ..color = RiderColors.accent.withValues(alpha: (1.0 - pulse) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(startPin, 12 + 24 * pulse, ripplePaint);
      canvas.drawCircle(endPin, 12 + 24 * pulse, ripplePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RiderMapRoutePainter oldDelegate) => true;
}
