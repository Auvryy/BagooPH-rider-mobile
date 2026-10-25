import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DESIGN_SYSTEM.md defines the One Red #E00D42 standard and Plus Jakarta Sans', () {
    final spec = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(spec, contains('#E00D42'));
    expect(spec, contains('Plus Jakarta Sans'));

    final theme = buildRiderTheme();
    expect(RiderColors.accent, const Color(0xFFE00D42));
    expect(RiderTypography.family, 'Plus Jakarta Sans');
    expect(theme.scaffoldBackgroundColor, RiderColors.canvas);
    expect(theme.colorScheme.primary, const Color(0xFFE00D42));
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Plus Jakarta Sans');
    expect(RiderRadii.surface, 8.0);
    expect(RiderRadii.group, 8.0);
    expect(RiderRadii.control, 8.0);
    expect(RiderRadii.dialog, 12.0);
    expect(RiderRadii.sheet, 12.0);
    expect(RiderRadii.media, 8.0);
    expect(RiderRadii.pill, 999.0);
    final field =
        theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
    expect(field.borderRadius.topLeft.x, RiderRadii.control);
    expect(field.borderSide.color, RiderColors.border);
    expect(field, isA<RiderInputBorder>());
    expect(theme.inputDecorationTheme.fillColor, RiderColors.controlFill);
    final dialog = theme.dialogTheme.shape! as RoundedRectangleBorder;
    expect(
      dialog.borderRadius.resolve(TextDirection.ltr).topLeft.x,
      RiderRadii.dialog,
    );
    expect(
      theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
      greaterThanOrEqualTo(56),
    );
    expect(
      theme.outlinedButtonTheme.style!.minimumSize!.resolve({})!.height,
      greaterThanOrEqualTo(48),
    );
  });

  test(
    'focus, validation and high contrast remain visible without dark borders',
    () {
      final fields = buildRiderTheme().inputDecorationTheme;
      expect(fields.focusedBorder!.borderSide.color, RiderColors.accentText);
      expect(fields.focusedBorder!.borderSide.width, greaterThanOrEqualTo(2));
      expect(fields.errorBorder!.borderSide.style, BorderStyle.solid);
      expect(
        buildRiderTheme(highContrast: true)
            .inputDecorationTheme
            .enabledBorder!
            .borderSide
            .color,
        RiderColors.accentText,
      );
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'navigation and sheet motion respect reduced effects $reduced',
      (tester) async {
        final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
        const transition = RiderPageTransitionsBuilder();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Builder(
                builder: (context) {
                  final sheet = RiderMotion.sheetStyle(context);
                  expect(
                    sheet.duration,
                    reduced ? Duration.zero : RiderMotion.sheet,
                  );
                  return KeyedSubtree(
                    key: const ValueKey('motion-content'),
                    child: transition.buildTransitions(
                      route,
                      context,
                      const AlwaysStoppedAnimation<double>(.5),
                      const AlwaysStoppedAnimation<double>(0),
                      const Text('Readable content'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        final root = find.byKey(const ValueKey('motion-content'));
        expect(
          find.descendant(of: root, matching: find.byType(SlideTransition)),
          reduced ? findsNothing : findsOneWidget,
        );
        expect(transition.transitionDuration, RiderMotion.navigation);
        expect(find.text('Readable content'), findsOneWidget);
      },
    );
  }
}
