import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'rider_surfaces.dart';

/// Data model for a floating die-cut sticker in the Argon vortex or header clusters.
class ArgonStickerSpec {
  const ArgonStickerSpec({
    required this.id,
    required this.alignment,
    required this.rotationDegrees,
    required this.zIndex,
    required this.phaseOffset,
    required this.driftSpeed,
    required this.child,
    this.semanticLabel,
  });

  final String id;
  final Alignment alignment;
  final double rotationDegrees;
  final double zIndex;
  final double phaseOffset;
  final double driftSpeed;
  final Widget child;
  final String? semanticLabel;
}

/// Neo-Skeuomorphic die-cut sticker widget with a crisp 2.5px white border,
/// soft elevation shadow (`BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))`),
/// and playful rotation (`-15°` to `+18°`).
class DieCutStickerWidget extends StatelessWidget {
  const DieCutStickerWidget({
    super.key,
    required this.child,
    this.rotationDegrees = 0,
    this.backgroundColor = Colors.white,
    this.borderRadius = 999,
    this.borderWidth = 2.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.semanticLabel,
  });

  /// Speech bubble pill sticker (e.g. `"Let's roll."` or `"Every stop clear!"`).
  factory DieCutStickerWidget.speechBubble({
    Key? key,
    required String text,
    Color backgroundColor = RiderColors.accent,
    Color textColor = Colors.white,
    double rotationDegrees = 0,
    IconData? leadingIcon,
  }) {
    return DieCutStickerWidget(
      key: key,
      rotationDegrees: rotationDegrees,
      backgroundColor: backgroundColor,
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      semanticLabel: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: RiderTypography.family,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: textColor,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D tactile die-cut icon badge for courier objects (parcel box, lightning bolt,
  /// waybill tag, verified star, hub, scooter, GPS pin, COD pouch).
  factory DieCutStickerWidget.iconCutout({
    Key? key,
    required IconData icon,
    required Color fill,
    required Color iconColor,
    String? badgeText,
    double rotationDegrees = 0,
    double size = 44,
    String? semanticLabel,
  }) {
    return DieCutStickerWidget(
      key: key,
      rotationDegrees: rotationDegrees,
      backgroundColor: fill,
      borderRadius: badgeText != null ? 16 : 15,
      padding: badgeText != null
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
          : EdgeInsets.all((size - 22) / 2),
      semanticLabel: semanticLabel ?? badgeText,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: RiderTypography.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: iconColor,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  final Widget child;
  final double rotationDegrees;
  final Color backgroundColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12111827),
            blurRadius: 16,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x08111827),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final body = rotationDegrees == 0
        ? decorated
        : Transform.rotate(
            angle: rotationDegrees * (math.pi / 180.0),
            child: decorated,
          );
    if (semanticLabel == null) return ExcludeSemantics(child: body);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: body),
    );
  }
}

/// Circular Liquid Glass Orb (`72x72` default) with `ClipOval` + `BackdropFilter`
/// (blur `16.0`), translucent white fill (`0.75`), `1.5px` iridescent gradient border,
/// soft outer glow, and a crisp 4-point star / courier bag hybrid vector icon.
class LiquidGlassOrb extends StatelessWidget {
  const LiquidGlassOrb({
    super.key,
    this.size = 72,
    this.blurSigma = 16.0,
    this.onTap,
    this.rippleProgress = 0,
    this.semanticLabel = 'Bagoo Argon pulse orb',
  });

  final double size;
  final double blurSigma;
  final VoidCallback? onTap;
  final double rippleProgress;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduced = RiderMotion.reduced(context);
    final orb = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (rippleProgress > 0 && !reduced)
            Positioned(
              left: -size * 0.28 * rippleProgress,
              right: -size * 0.28 * rippleProgress,
              top: -size * 0.28 * rippleProgress,
              bottom: -size * 0.28 * rippleProgress,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: RiderColors.accent.withValues(
                        alpha: (1 - rippleProgress).clamp(0.0, 0.55),
                      ),
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: RiderColors.accent.withValues(alpha: 0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(-4, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(6, -4),
                ),
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: CustomPaint(
                  size: Size.square(size),
                  foregroundPainter: _IridescentOrbBorderPainter(
                    strokeWidth: 1.5,
                  ),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.75),
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.45),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.75),
                          const Color(0xFFFFF0F4).withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: Size.square(size * 0.46),
                        painter: const _ArgonStarBagHybridPainter(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, child: orb);
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: orb,
      ),
    );
  }
}

class _IridescentOrbBorderPainter extends CustomPainter {
  const _IridescentOrbBorderPainter({this.strokeWidth = 1.5});
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final oval = rect.deflate(inset);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [
          RiderColors.accent,
          Color(0x33E00D42),
          Color(0xFFFFFFFF),
          Color(0x33E00D42),
          RiderColors.accent,
        ],
      ).createShader(rect);
    canvas.drawOval(oval, paint);

    // Top-left liquid glass specular arc
    final specular = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawArc(
      oval.deflate(1.5),
      -math.pi * 0.85,
      math.pi * 0.65,
      false,
      specular,
    );
  }

  @override
  bool shouldRepaint(covariant _IridescentOrbBorderPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}

/// Custom vector icon combining a crisp 4-point Argon spark star with a
/// courier parcel/bag silhouette in the center of the LiquidGlassOrb.
class _ArgonStarBagHybridPainter extends CustomPainter {
  const _ArgonStarBagHybridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        RiderColors.accent,
        Color(0xFF8B0829),
      ],
    ).createShader(Offset.zero & size);

    // Rounded courier bag body at lower-center
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + h * 0.10),
        width: w * 0.68,
        height: h * 0.58,
      ),
      Radius.circular(w * 0.16),
    );
    final bagPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = shader;
    canvas.drawRRect(bagRect, bagPaint);

    // Bag handle arc at top
    final handleRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - h * 0.18),
      width: w * 0.34,
      height: h * 0.28,
    );
    canvas.drawArc(handleRect, math.pi, math.pi, false, bagPaint);

    // Crisp 4-point Argon star gleaming at the center-top of the bag
    final starCenter = Offset(center.dx, center.dy + h * 0.06);
    final outerR = w * 0.28;
    final innerR = w * 0.09;
    final starPath = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * (math.pi / 4);
      final r = i.isEven ? outerR : innerR;
      final pt = Offset(
        starCenter.dx + math.cos(angle) * r,
        starCenter.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();
    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = shader;
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Editorial Typography Core (`Zone B`) with animated `2px` horizontal strikethrough
/// (`CustomPainter`) across the struck word and a spring-pop reveal of the replacement word.
class AnimatedStrikeText extends StatelessWidget {
  const AnimatedStrikeText({
    super.key,
    this.line1 = 'Go beyond the',
    this.struckWord = 'ordinary',
    this.replacementWord = 'every route',
    this.line3 = 'to deliver every parcel right',
    this.headlineOpacity = 1.0,
    this.strikeProgress = 1.0,
    this.revealScale = 1.0,
  });

  final String line1;
  final String struckWord;
  final String replacementWord;
  final String line3;
  final double headlineOpacity;
  final double strikeProgress;
  final double revealScale;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: RiderTypography.family,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.6,
      color: RiderColors.ink,
    );
    final mutedStyle = baseStyle.copyWith(color: RiderColors.slateMuted);

    return Opacity(
      opacity: headlineOpacity.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(line1, textAlign: TextAlign.center, style: baseStyle),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              CustomPaint(
                foregroundPainter: _AnimatedStrikePainter(
                  progress: strikeProgress.clamp(0.0, 1.0),
                  color: RiderColors.accent,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    struckWord,
                    style: baseStyle.copyWith(
                      color: RiderColors.ink.withValues(alpha: 0.52),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: revealScale.clamp(0.0, 1.25),
                child: Opacity(
                  opacity: revealScale.clamp(0.0, 1.0),
                  child: Text(
                    replacementWord,
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.w800,
                      color: RiderColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(line3, textAlign: TextAlign.center, style: mutedStyle),
        ],
      ),
    );
  }
}

class _AnimatedStrikePainter extends CustomPainter {
  const _AnimatedStrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height * 0.54;
    final start = Offset(0, y);
    final end = Offset(size.width * progress, y);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedStrikePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Sleek pill-shaped CTA button (`height: 56px`, `borderRadius: 999`) with solid
/// brand fill, subtle inner top highlight (`Colors.white24`), and spring press feedback.
class ArgonPillButton extends StatelessWidget {
  const ArgonPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.widthFactor,
    this.backgroundColor = RiderColors.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? widthFactor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final pill = RiderPressFeedback(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: onPressed == null
              ? const []
              : [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
          ),
          child: CustomPaint(
            foregroundPainter: const _TopInnerHighlightPainter(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: RiderTypography.family,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 19, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (widthFactor == null) return pill;
    return FractionallySizedBox(widthFactor: widthFactor, child: pill);
  }
}

class _TopInnerHighlightPainter extends CustomPainter {
  const _TopInnerHighlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final y = -8.0;
    if (size.width > 16) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact Argon aesthetic banner with a floating `LiquidGlassOrb` and
/// die-cut courier stickers used across existing app screens.
class ArgonPageCluster extends StatelessWidget {
  const ArgonPageCluster({
    super.key,
    required this.pillText,
    required this.secondaryStickerText,
    required this.primaryIcon,
    this.secondaryIcon = Icons.verified_rounded,
    this.trailingAction,
  });

  final String pillText;
  final String secondaryStickerText;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const LiquidGlassOrb(
          size: 40,
          blurSigma: 12,
          semanticLabel: 'Bagoo Argon badge',
        ),
        DieCutStickerWidget.speechBubble(
          text: pillText,
          backgroundColor: RiderColors.accent,
          rotationDegrees: 0,
          leadingIcon: primaryIcon,
        ),
        DieCutStickerWidget.speechBubble(
          text: secondaryStickerText,
          backgroundColor: const Color(0xFFFFFDF7),
          textColor: RiderColors.ink,
          rotationDegrees: 0,
          leadingIcon: secondaryIcon,
        ),
        ?trailingAction,
      ],
    );
  }
}
