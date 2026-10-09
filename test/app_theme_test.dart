import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Color hex(String value) =>
    Color(int.parse(value.substring(1), radix: 16) | 0xFF000000);
void main() {
  test(
    'existing app theme follows the accepted mobile color and shape tokens',
    () {
      final tokens =
          jsonDecode(File('docs/design/tokens.json').readAsStringSync()) as Map;
      final light = tokens['light'] as Map;
      final geometry = tokens['geometry'] as Map;
      final radii = geometry['radii'] as Map;
      final theme = buildRiderTheme();
      expect(theme.scaffoldBackgroundColor, hex(light['canvas']));
      expect(theme.colorScheme.primary, hex(light['accent']));
      expect(
        theme.textTheme.bodyLarge?.fontFamily,
        (tokens['font_families'] as Map)[defaultTargetPlatform.name],
      );
      expect(RiderRadii.surface, radii['surface']);
      expect(RiderRadii.group, radii['group']);
      expect(RiderRadii.control, radii['control']);
      expect(RiderRadii.dialog, radii['dialog']);
      expect(RiderRadii.sheet, radii['sheet']);
      expect(RiderRadii.media, radii['map']);
      final field =
          theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
      expect(field.borderRadius.topLeft.x, radii['control']);
      expect(field.borderSide, BorderSide.none);
      expect(field, isA<RiderInputBorder>());
      expect(theme.inputDecorationTheme.fillColor, hex(light['control_fill']));
      final dialog = theme.dialogTheme.shape! as RoundedSuperellipseBorder;
      expect(
        dialog.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        radii['dialog'],
      );
      expect(
        theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(geometry['primary_height']),
      );
      expect(
        theme.outlinedButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(geometry['target_min']),
      );
    },
  );

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
