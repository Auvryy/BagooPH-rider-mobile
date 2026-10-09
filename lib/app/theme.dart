import 'package:flutter/material.dart';

abstract final class RiderColors {
  static const accent = Color(0xFFE00D42);
  static const accentPressed = Color(0xFFA1052B);
  static const accentText = Color(0xFFC20836);
  static const canvas = Color(0xFFF7F7FA);
  static const rose = Color(0xFFFFF2F4);
  static const ink = Color(0xFF0F172A);
  static const body = Color(0xFF1E293B);
  static const muted = Color(0xFF475569);
  static const border = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
}

abstract final class RiderRadii {
  static const surface = 20.0;
  static const group = 20.0;
  static const control = 12.0;
  static const media = 16.0;
  static const dialog = 24.0;
  static const sheet = 28.0;
  static const selection = 12.0;
  static const brand = 8.0;
}

abstract final class RiderMotion {
  static const pressed = Duration(milliseconds: 120);
  static const navigation = Duration(milliseconds: 200);
  static const sheet = Duration(milliseconds: 240);
  static AnimationStyle sheetStyle(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(duration: sheet, reverseDuration: sheet);
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
    if (MediaQuery.disableAnimationsOf(context) || route.isFirst) return child;
    final curve = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .015),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

ThemeData buildRiderTheme() {
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
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
    visualDensity: VisualDensity.standard,
    fontFamily: 'Plus Jakarta Sans',
    colorScheme: scheme,
    scaffoldBackgroundColor: RiderColors.canvas,
    dividerTheme: const DividerThemeData(
      color: RiderColors.divider,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RiderColors.canvas,
      foregroundColor: RiderColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
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
      shape: RoundedRectangleBorder(
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
        fontSize: 24,
        height: 4 / 3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
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
        fontWeight: FontWeight.w500,
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(fontSize: 15, color: RiderColors.muted),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
        borderSide: BorderSide(color: RiderColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
        borderSide: BorderSide(color: RiderColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RiderRadii.control)),
        borderSide: BorderSide(color: RiderColors.accentText, width: 2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: shape,
        backgroundColor: RiderColors.accent,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: shape,
        side: const BorderSide(color: RiderColors.border),
        foregroundColor: RiderColors.ink,
      ),
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
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RiderRadii.control),
      ),
      side: const BorderSide(color: RiderColors.border, width: 1.5),
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
