import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/main.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/onboarding_support.dart';
import 'support/test_auth_repository.dart';

void main() {
  setUp(completedIntroductionFixture);

  testWidgets('desktop device preview hides and restores the rider app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        ],
        child: DevicePreview(
          storage: DevicePreviewStorage.none(),
          builder: (_) => const BagooRiderApp(useDevicePreview: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sign-in-button')), findsOneWidget);
    expect(find.text('Rider is paused'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('Rider is paused'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sign-in-button')).hitTestable(),
      findsNothing,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Rider is paused'), findsNothing);
    expect(
      find.byKey(const ValueKey('sign-in-button')).hitTestable(),
      findsOneWidget,
    );
  });
}
