import 'package:flutter/material.dart';

abstract final class RiderColors {
  /// Primary Brand Accent (The ONLY Color)
  static const accent = Color(0xFFE00D42);

  /// Soft Red Tint (Subtle Highlights): rgba(224, 13, 66, 0.08)
  static const redTint = Color(0x14E00D42);
  static const rose = Color(0x14E00D42);
  static const accentGlow = Color(0x29E00D42);
  static const accentPressed = Color(0xFFC20836);
  static const accentText = Color(0xFFE00D42);

  /// Canvas & Surfaces
  static const canvas = Color(0xFFFAFAFA);
  static const pureWhite = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const carbon = Color(0xFF090A0F);
  static const neumorphicSurface = Color(0xFFFFFFFF);
  static const neumorphicRecessed = Color(0xFFF1F5F9);
  static const creamSticker = Color(0xFFFFFFFF);

  /// Typography Ink
  static const ink = Color(0xFF18181B);
  static const body = Color(0xFF18181B);
  static const slate = Color(0xFF62626B);
  static const muted = Color(0xFF62626B);
  static const slateMuted = Color(0xFF94A3B8);

  /// Borders & Dividers: Whisper-quiet 1px borders
  static const border = Color(0xFFDEDEE3);
  static const outline = Color(0xFFDEDEE3);
  static const borderSubtle = Color(0x12111827);
  static const controlFill = Color(0xFFF1F5F9);
  static const divider = Color(0xFFDEDEE3);
}

/// Geographic display surfaces. These do not change the app's light/red theme.
abstract final class RiderMapColors {
  static const canvas = Color(0xFF141B23);
  static const surface = Color(0xF01C2632);
  static const border = Color(0xFF3B4654);
  static const ink = Color(0xFFFAFAFA);
  static const muted = Color(0xFFB9C5D3);
  static const route = Color(0xFFF34370);
  static const routeOutline = Color(0xFFFFE6EE);
  static const markerShadow = Color(0x44000000);
}

abstract final class RiderShadows {
  /// Small neutral shadow beneath bordered surfaces.
  static const ambient = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D111827),
      blurRadius: 3,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Layered depth without dark drop shadows: subtle 1px border + soft ambient elevation
  static const neumorphicElevated = ambient;

  /// Subtle elevation; active state is carried by the border and label.
  static const neumorphicAccent = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D18181B),
      blurRadius: 3,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Floating dock shadow for the bottom navigation capsule
  static const floatingDock = <BoxShadow>[
    BoxShadow(
      color: Color(0x12111827),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
    BoxShadow(color: Color(0x14E00D42), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

abstract final class RiderRadii {
  static const surface = 8.0;
  static const group = 8.0;
  static const control = 8.0;
  static const media = 8.0;
  static const dialog = 12.0;
  static const sheet = 12.0;
  static const selection = 8.0;
  static const pill = 999.0;
  static const navigation = 999.0;
  static const brand = 8.0;
}

abstract final class RiderMotion {
  /// Spring-like easing: cubic-bezier(0.16, 1, 0.3, 1) for natural deceleration
  static const easeOutSpring = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Snappy timing: 150ms–250ms for press and navigation
  static const pressed = Duration(milliseconds: 180);
  static const navigation = Duration(milliseconds: 250);

  /// Sheet/modal reveal: 300ms–450ms
  static const sheet = Duration(milliseconds: 320);

  static const touchSpring = SpringDescription(
    mass: 0.8,
    stiffness: 380,
    damping: 24,
  );
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: sheet,
          reverseDuration: Duration(milliseconds: 240),
          curve: easeOutSpring,
        );
}

abstract final class RiderTypography {
  static const family = 'Plus Jakarta Sans';
}

class RiderScrollBehavior extends MaterialScrollBehavior {
  const RiderScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      RiderMotion.reduced(context)
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics();
}

/// Filled fields keep the same continuous contour as surfaces and controls.
/// Persistent external labels and native floating labels are both supported.
class RiderInputBorder extends OutlineInputBorder {
  const RiderInputBorder({
    super.borderSide = BorderSide.none,
    super.borderRadius = const BorderRadius.all(
      Radius.circular(RiderRadii.control),
    ),
  });
  RoundedRectangleBorder get _shape =>
      RoundedRectangleBorder(side: borderSide, borderRadius: borderRadius);
  @override
  RiderInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => RiderInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
  );
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);
  @override
  bool get preferPaintInterior => false;
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    canvas.save();
    if (gapStart != null && gapExtent > 0 && gapPercentage > 0) {
      final width = (gapExtent + gapPadding * 2) * gapPercentage;
      final left = textDirection == TextDirection.rtl
          ? rect.right - gapStart - width + gapPadding
          : rect.left + gapStart - gapPadding;
      final gap = Rect.fromLTWH(left, rect.top - 3, width, 6);
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rect.inflate(3)),
          Path()..addRect(gap),
        ),
      );
    }
    _shape.paint(canvas, rect, textDirection: textDirection);
    canvas.restore();
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is RiderInputBorder
      ? RiderInputBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        )
      : super.lerpFrom(a, t);
  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is RiderInputBorder ? b.lerpFrom(this, t) : super.lerpTo(b, t);
}

class RiderPageTransitionsBuilder extends PageTransitionsBuilder {
  const RiderPageTransitionsBuilder();
  @override
  Duration get transitionDuration => RiderMotion.navigation;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (RiderMotion.reduced(context) || route.isFirst) return child;
    final curve = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.06, 0),
          end: Offset.zero,
        ).animate(animation.drive(CurveTween(curve: Curves.easeOutCubic))),
        child: child,
      ),
    );
  }
}

ThemeData buildRiderTheme({bool highContrast = false}) {
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
  );
  const family = RiderTypography.family;
  final restingSide = highContrast
      ? const BorderSide(color: RiderColors.accentText, width: 1.5)
      : const BorderSide(color: RiderColors.border);
  final focusSide = WidgetStateProperty.resolveWith<BorderSide>(
    (states) => states.contains(WidgetState.focused)
        ? const BorderSide(color: RiderColors.accentText, width: 2)
        : BorderSide.none,
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: RiderColors.accent,
    primary: RiderColors.accent,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: RiderColors.ink,
    error: const Color(0xFFBE123C),
  );
  return ThemeData(
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.standard,
    fontFamily: family,
    fontFamilyFallback: const ['sans-serif'],
    colorScheme: scheme,
    scaffoldBackgroundColor: RiderColors.canvas,
    dividerTheme: const DividerThemeData(
      color: RiderColors.divider,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: RiderColors.canvas,
      foregroundColor: RiderColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: family,
        fontSize: 20,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: RiderColors.ink,
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const RiderPageTransitionsBuilder(),
      },
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RiderRadii.sheet),
        ),
      ),
      showDragHandle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        height: 1.16,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: RiderColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.75,
        color: RiderColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: RiderColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: RiderColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: RiderColors.body),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: RiderColors.muted,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        color: RiderColors.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RiderColors.controlFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(fontSize: 15, color: RiderColors.muted),
      border: RiderInputBorder(borderSide: restingSide),
      enabledBorder: RiderInputBorder(borderSide: restingSide),
      disabledBorder: const RiderInputBorder(),
      focusedBorder: const RiderInputBorder(
        borderSide: BorderSide(color: RiderColors.accentText, width: 2),
      ),
      errorBorder: const RiderInputBorder(
        borderSide: BorderSide(color: Color(0xFFBE123C)),
      ),
      focusedErrorBorder: const RiderInputBorder(
        borderSide: BorderSide(color: Color(0xFFBE123C), width: 2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: shape,
        elevation: 0,
        backgroundColor: RiderColors.accent,
        foregroundColor: Colors.white,
      ).copyWith(side: focusSide),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: shape,
            side: const BorderSide(color: RiderColors.border),
            backgroundColor: RiderColors.surface,
            foregroundColor: RiderColors.ink,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: RiderColors.accentText, width: 2)
                  : const BorderSide(color: RiderColors.border),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: RiderColors.accentText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        foregroundColor: RiderColors.ink,
      ).copyWith(side: focusSide),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(
          BorderSide(color: RiderColors.border),
        ),
        shape: const WidgetStatePropertyAll(shape),
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : RiderColors.controlFill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? RiderColors.accentText
              : RiderColors.muted,
        ),
      ),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide.none,
      shape: shape,
      backgroundColor: RiderColors.controlFill,
      selectedColor: RiderColors.rose,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      side: BorderSide.none,
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RiderColors.accent
            : RiderColors.controlFill,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : RiderColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RiderColors.accent
            : RiderColors.controlFill,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.dialog)),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: const DatePickerThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.dialog)),
      ),
      backgroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
  );
}
