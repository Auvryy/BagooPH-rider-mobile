import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app/theme.dart';

/// Minimalist reading surface with whisper-quiet 1px border and soft ambient elevation.
/// Eliminates dark muddy shadows; creates layered depth through subtle borders and light.
class RiderSurface extends StatelessWidget {
  const RiderSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = RiderRadii.surface,
    this.color = Colors.white,
    this.accentGlow = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool accentGlow;

  @override
  Widget build(BuildContext context) {
    final isAccent = color == RiderColors.rose || accentGlow;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: isAccent ? const Color(0x33E00D42) : RiderColors.border,
        width: 1.0,
      ),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: RiderShadows.ambient),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class RiderCanvas extends StatelessWidget {
  const RiderCanvas({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Container(color: RiderColors.canvas, child: child);
}

/// Solid sculpted chrome keeps navigation and temporary controls readable over a map.
class RiderChrome extends StatelessWidget {
  const RiderChrome({
    super.key,
    required this.child,
    this.radius = RiderRadii.navigation,
    this.padding = EdgeInsets.zero,
    this.topOnly = false,
    this.color = Colors.white,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool topOnly;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: topOnly
          ? BorderRadius.vertical(top: Radius.circular(radius))
          : BorderRadius.circular(radius),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: Material(
        color: color,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Observes pointers without taking the button's gestures or semantics.
/// Provides snappy, tactile press scale down (`transform: scale(0.98)`) and crisp red focus ring.
class RiderPressFeedback extends StatefulWidget {
  const RiderPressFeedback({super.key, required this.child});
  final Widget child;
  @override
  State<RiderPressFeedback> createState() => _RiderPressFeedbackState();
}

class _RiderPressFeedbackState extends State<RiderPressFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _focused = false;
  bool get _enabled => switch (widget.child) {
    ButtonStyleButton button =>
      button.onPressed != null || button.onLongPress != null,
    IconButton button => button.onPressed != null,
    InkWell ink => ink.onTap != null || ink.onLongPress != null,
    _ => true,
  };
  void _move(double target) {
    if (!_enabled || RiderMotion.reduced(context)) return;
    _scale.animateWith(
      SpringSimulation(
        RiderMotion.touchSpring,
        _scale.value,
        target,
        _scale.velocity,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (RiderMotion.reduced(context)) {
      _scale.stop();
      _scale.value = 1;
    }
  }

  @override
  void didUpdateWidget(RiderPressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _scale.stop();
      _scale.value = 1;
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (mounted) setState(() => _focused = focused);
    },
    child: Listener(
      onPointerDown: (_) => _move(0.98),
      onPointerUp: (_) => _move(1.0),
      onPointerCancel: (_) => _move(1.0),
      child: AnimatedBuilder(
        animation: _scale,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: RiderMotion.reduced(context)
              ? 1.0
              : _scale.value.clamp(0.95, 1.02),
          transformHitTests: false,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RiderRadii.control),
                side: _focused
                    ? const BorderSide(color: RiderColors.accent, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<T?> showRiderSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  AnimationStyle? sheetAnimationStyle,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  backgroundColor: Colors.transparent,
  sheetAnimationStyle: sheetAnimationStyle ?? RiderMotion.sheetStyle(context),
  builder: (context) {
    final animation =
        ModalRoute.of(context)?.animation ??
        const AlwaysStoppedAnimation<double>(1);
    return AnimatedBuilder(
      animation: animation,
      child: RiderChrome(
        radius: RiderRadii.sheet,
        topOnly: true,
        padding: const EdgeInsets.all(6),
        child: RiderSurface(radius: RiderRadii.dialog, child: builder(context)),
      ),
      builder: (context, child) => Transform.scale(
        alignment: Alignment.bottomCenter,
        scale: RiderMotion.reduced(context)
            ? 1
            : .98 + .02 * Curves.easeOutBack.transform(animation.value),
        transformHitTests: false,
        child: child,
      ),
    );
  },
);

Future<T?> showRiderDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  animationStyle: RiderMotion.reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: RiderMotion.navigation,
          reverseDuration: RiderMotion.pressed,
          curve: Curves.easeOutCubic,
        ),
  builder: (context) {
    final animation =
        ModalRoute.of(context)?.animation ??
        const AlwaysStoppedAnimation<double>(1);
    return AnimatedBuilder(
      animation: animation,
      child: builder(context),
      builder: (context, child) => Transform.scale(
        scale: RiderMotion.reduced(context)
            ? 1
            : .96 + .04 * Curves.easeOutBack.transform(animation.value),
        transformHitTests: false,
        child: child,
      ),
    );
  },
);
