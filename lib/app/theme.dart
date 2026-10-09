import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

abstract final class RiderColors {
  static const accent = Color(0xFFE00D42);
  static const accentPressed = Color(0xFFA1052B);
  static const accentText = Color(0xFFC20836);
  static const canvas = Color(0xFFF7F7FA);
  static const rose = Color(0xFFFFF2F4);
  static const ink = Color(0xFF0F172A);
  static const body = Color(0xFF1E293B);
  static const muted = Color(0xFF475569);
  static const border = Color(0xFFE3E5EB);
  static const controlFill = Color(0xFFEEF0F4);
  static const divider = Color(0xFFE2E8F0);
}

abstract final class RiderRadii {
  static const surface = 24.0;
  static const group = 24.0;
  static const control = 16.0;
  static const media = 20.0;
  static const dialog = 28.0;
  static const sheet = 32.0;
  static const selection = 18.0;
  static const navigation = 32.0;
  static const brand = 8.0;
}

abstract final class RiderMotion {
  static const pressed = Duration(milliseconds: 160);
  static const navigation = Duration(milliseconds: 320);
  static const sheet = Duration(milliseconds: 380);
  static const touchSpring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 26,
  );
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(duration: sheet, reverseDuration: sheet);
}

abstract final class RiderTypography {
  static String family(TargetPlatform platform) => switch (platform) {
    TargetPlatform.linux => 'sans-serif',
    TargetPlatform.windows => 'Segoe UI',
    TargetPlatform.iOS || TargetPlatform.macOS => '.SF UI Text',
    _ => 'Roboto',
  };
}

class RiderScrollBehavior extends MaterialScrollBehavior {
  const RiderScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      RiderMotion.reduced(context)
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
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
  RoundedSuperellipseBorder get _shape =>
      RoundedSuperellipseBorder(side: borderSide, borderRadius: borderRadius);
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
          begin: const Offset(.08, 0),
          end: Offset.zero,
        ).animate(animation.drive(CurveTween(curve: Curves.easeOutBack))),
        child: child,
      ),
    );
  }
}

ThemeData buildRiderTheme({bool highContrast = false}) {
  const shape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
  );
  final family = RiderTypography.family(defaultTargetPlatform);
  final restingSide = highContrast
      ? const BorderSide(color: RiderColors.accentText, width: 1.5)
      : BorderSide.none;
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
    fontFamilyFallback: const ['Plus Jakarta Sans'],
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
        fontWeight: FontWeight.w600,
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
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RiderRadii.sheet),
        ),
      ),
      showDragHandle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: RiderColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: RiderColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: RiderColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: RiderColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: RiderColors.body),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 10 / 7,
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
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RiderColors.controlFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: shape,
        backgroundColor: RiderColors.accent,
        foregroundColor: Colors.white,
      ).copyWith(side: focusSide),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: shape,
        side: BorderSide.none,
        backgroundColor: RiderColors.controlFill,
        foregroundColor: RiderColors.ink,
      ).copyWith(side: focusSide),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: RiderColors.accentText,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        foregroundColor: RiderColors.muted,
      ).copyWith(side: focusSide),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide.none),
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
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      side: BorderSide.none,
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RiderColors.accent
            : RiderColors.controlFill,
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.dialog)),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: const DatePickerThemeData(
      shape: RoundedSuperellipseBorder(
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
