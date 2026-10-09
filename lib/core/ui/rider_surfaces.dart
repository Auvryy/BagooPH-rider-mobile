import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app/theme.dart';

/// Opaque reading surface; depth never depends on a dark outline.
class RiderSurface extends StatelessWidget {
  const RiderSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = RiderRadii.surface,
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      shadows: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 24,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: color,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class RiderCanvas extends StatelessWidget {
  const RiderCanvas({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [RiderColors.canvas, Color(0xFFEDEFF4)],
      ),
    ),
    child: child,
  );
}

/// Blur is clipped to floating chrome, never applied to reading content.
class RiderGlass extends StatelessWidget {
  const RiderGlass({
    super.key,
    required this.child,
    this.radius = RiderRadii.navigation,
    this.padding = EdgeInsets.zero,
    this.topOnly = false,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool topOnly;
  @override
  Widget build(BuildContext context) {
    final opaque =
        RiderMotion.reduced(context) || MediaQuery.highContrastOf(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: topOnly
          ? BorderRadius.vertical(top: Radius.circular(radius))
          : BorderRadius.circular(radius),
    );
    Widget layer = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: opaque ? Colors.white : null,
        gradient: opaque
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xEFFFFFFF), Color(0xB8FFFFFF)],
              ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!opaque) {
      layer = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: layer,
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: layer,
      ),
    );
  }
}

/// Observes pointers without taking the button's gestures or semantics.
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
      onPointerDown: (_) => _move(.975),
      onPointerUp: (_) => _move(1),
      onPointerCancel: (_) => _move(1),
      child: AnimatedBuilder(
        animation: _scale,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: RiderMotion.reduced(context)
              ? 1
              : _scale.value.clamp(.95, 1.02),
          transformHitTests: false,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(RiderRadii.control),
                side: _focused
                    ? const BorderSide(color: RiderColors.accentText, width: 2)
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
      child: RiderGlass(
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
