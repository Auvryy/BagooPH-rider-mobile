import 'package:bagoo_rider_mobile/features/auth/presentation/widgets/auth_field.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is AuthField && widget.label == label,
  ),
  matching: find.byType(TextFormField),
);

Future<void> openApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  double keyboard = 0,
  String route = '/',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.defaultRouteNameTestValue = route;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  await tester.pumpWidget(const BagooRiderApp());
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    final font = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
  });
  testWidgets('login gives local field feedback and an honest preview result', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.byKey(const ValueKey('sign-in-button')));
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(field('Email address'), 'rider@example.com');
    await tester.enterText(field('Password'), 'preview-password');
    final passwordText = find.descendant(
      of: field('Password'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordText).obscureText, isTrue);
    await tapVisible(tester, find.byTooltip('Show password'));
    expect(tester.widget<EditableText>(passwordText).obscureText, isFalse);
    await tapVisible(tester, find.byKey(const ValueKey('sign-in-button')));
    expect(find.text('Sign-in preview'), findsOneWidget);
    expect(
      find.textContaining('your details are not sent anywhere'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Back to preview'));
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login links open registration and recovery without a fake account',
    (tester) async {
      await openApp(tester);
      await tapVisible(tester, find.text('Forgot password?'));
      expect(
        find.textContaining('does not send recovery emails'),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('Back to preview'));
      await tapVisible(tester, find.byKey(const ValueKey('open-register')));
      expect(find.text('Let’s get to know you.'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Back to sign in'));
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all registration steps are explorable and preserve local entries',
    (tester) async {
      await openApp(tester, route: '/register');
      expect(find.text('Let’s get to know you.'), findsOneWidget);
      await tester.enterText(field('Full name'), 'Preview Rider');
      await tapVisible(tester, find.byKey(const ValueKey('registration-next')));
      expect(find.text('Your delivery vehicle.'), findsOneWidget);
      // Advancing a long form brings the new step's heading into view.
      expect(
        tester.getTopLeft(find.text('Your delivery vehicle.')).dy,
        lessThan(844),
      );
      await tapVisible(tester, find.text('Scooter'));
      await tester.enterText(
        field('Plate or registration number'),
        'PREVIEW-123',
      );
      await tapVisible(tester, find.byKey(const ValueKey('registration-next')));
      expect(find.text('A few final details.'), findsOneWidget);
      expect(find.text('Government ID'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-back-step')),
      );
      expect(
        tester
            .widget<TextFormField>(field('Plate or registration number'))
            .controller!
            .text,
        'PREVIEW-123',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-back-step')),
      );
      expect(
        tester.widget<TextFormField>(field('Full name')).controller!.text,
        'Preview Rider',
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-step-2')),
      );
      await tester.enterText(field('Create password'), 'preview-password');
      await tester.enterText(field('Confirm password'), 'preview-password');
      await tapVisible(tester, find.byKey(const ValueKey('registration-next')));
      expect(find.text('Registration preview'), findsOneWidget);
      expect(find.textContaining('No account is created'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'document names survive Back; cancel and oversized files keep the choice',
    (tester) async {
      final original = FileSelectorPlatform.instance;
      final picker = _FilePicker();
      FileSelectorPlatform.instance = picker;
      addTearDown(() => FileSelectorPlatform.instance = original);
      await openApp(tester, route: '/register');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-step-2')),
      );

      Finder documentButton(String label) => find.descendant(
        of: find.byKey(const ValueKey('identity-document')),
        matching: find.widgetWithText(OutlinedButton, label),
      );
      picker.nextFile = XFile.fromData(Uint8List(8), path: 'preview-id.pdf');
      await tapVisible(tester, documentButton('Choose document'));
      expect(find.text('preview-id.pdf'), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-step-1')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('registration-step-2')),
      );
      expect(find.text('preview-id.pdf'), findsOneWidget);
      picker.nextFile = null;
      await tapVisible(tester, documentButton('Replace document'));
      expect(find.text('preview-id.pdf'), findsOneWidget);
      picker.nextFile = XFile.fromData(
        Uint8List(5 * 1024 * 1024 + 1),
        path: 'too-large.pdf',
      );
      await tapVisible(tester, documentButton('Replace document'));
      expect(find.textContaining('Choose a file up to 5 MB'), findsOneWidget);
      expect(find.text('preview-id.pdf'), findsOneWidget);
      await tapVisible(tester, find.text('Remove'));
      expect(find.text('preview-id.pdf'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'both pages fit ${size.width} wide at ${scale}x text',
        (tester) async {
          await openApp(tester, size: size, scale: scale, keyboard: 180);
          expect(tester.takeException(), isNull);
          await tapVisible(tester, find.byKey(const ValueKey('open-register')));
          expect(tester.takeException(), isNull);
          for (final step in [1, 2, 0]) {
            await tapVisible(
              tester,
              find.byKey(ValueKey('registration-step-$step')),
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.byKey(const ValueKey('registration-next')),
            );
            await tester.pumpAndSettle();
            final primary = tester.getRect(
              find.byKey(const ValueKey('registration-next')),
            );
            expect(primary.height, greaterThanOrEqualTo(52));
            expect(primary.bottom, lessThanOrEqualTo(size.height - 180));
            expect(primary.left, greaterThanOrEqualTo(0));
            expect(primary.right, lessThanOrEqualTo(size.width));
          }
        },
        variant: TargetPlatformVariant({
          size.width >= 768 ? TargetPlatform.linux : TargetPlatform.android,
        }),
      );
    }
  }
}

class _FilePicker extends FileSelectorPlatform {
  XFile? nextFile;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => nextFile;
}
