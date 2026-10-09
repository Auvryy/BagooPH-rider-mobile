import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/ui/rider_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final effects in [
    const MediaQueryData(),
    const MediaQueryData(disableAnimations: true),
    const MediaQueryData(highContrast: true),
    const MediaQueryData(accessibleNavigation: true),
  ]) {
    testWidgets('glass preserves content with effects $effects', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRiderTheme(),
          home: MediaQuery(
            data: effects,
            child: const RiderGlass(child: Text('Readable navigation')),
          ),
        ),
      );
      final fallback =
          effects.disableAnimations ||
          effects.highContrast ||
          effects.accessibleNavigation;
      expect(
        find.byType(BackdropFilter),
        fallback ? findsNothing : findsOneWidget,
      );
      expect(find.text('Readable navigation'), findsOneWidget);
      final clip = tester.widget<ClipPath>(find.byType(ClipPath).first);
      expect(
        (clip.clipper! as ShapeBorderClipper).shape,
        isA<RoundedSuperellipseBorder>(),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'press feedback preserves hit size and dispatches once $reduced',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                child: RiderPressFeedback(
                  child: FilledButton(
                    key: const ValueKey('action'),
                    onPressed: () => calls++,
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ),
          ),
        );
        final button = find.byKey(const ValueKey('action'));
        final before = tester.getSize(button);
        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        final transform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(RiderPressFeedback),
                matching: find.byType(Transform),
              )
              .first,
        );
        final scale = transform.transform.entry(0, 0);
        expect(scale, reduced ? 1 : lessThan(1));
        expect(tester.getSize(button), before);
        expect(before.height, greaterThanOrEqualTo(48));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('disabled actions do not animate or dispatch', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: const Center(
          child: RiderPressFeedback(
            child: FilledButton(onPressed: null, child: Text('Unavailable')),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Unavailable')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(RiderPressFeedback),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.entry(0, 0), 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets(
      'dialog keeps editable labels and returns its result $reduced',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    child: const Text('Open dialog'),
                    onPressed: () async {
                      result = await showRiderDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Enter a code'),
                          content: const TextField(
                            decoration: InputDecoration(
                              labelText: 'Verification code',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open dialog'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Example');
        await tester.pumpAndSettle();
        expect(find.text('Verification code'), findsOneWidget);
        expect(find.text('Example'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(result, true);
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('scrolling has momentum and reduced effects use clamping', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Builder(
              builder: (context) {
                expect(
                  const RiderScrollBehavior().getScrollPhysics(context),
                  reduced
                      ? isA<ClampingScrollPhysics>()
                      : isA<BouncingScrollPhysics>(),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }
  });
}
