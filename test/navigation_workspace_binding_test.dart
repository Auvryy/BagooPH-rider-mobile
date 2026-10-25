import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'home_dashboard_test.dart' as dashboard;
import 'home_read_recovery_test.dart';
import 'navigation_test.dart' as support;
import 'support/test_auth_repository.dart';

void main() {
  setUp(() {
    final platform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = platform);
  });

  for (final cause in ['hidden task', 'lost Home capability', 'logout']) {
    test(
      'persistent navigation provider stops after $cause without a Home widget',
      () async {
        final h = RecoveryHarness();
        final routes = support.Routes();
        final auth = TestAuthRepository()..account = dashboard.account;
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            workspaceRepositoryProvider.overrideWithValue(
              h.controller.repository,
            ),
            workspaceControllerProvider.overrideWith(
              (ref, identity) => h.controller,
            ),
            roadRoutingProvider.overrideWithValue(routes),
          ],
        );
        addTearDown(() {
          container.dispose();
          routes.dispose();
          h.controller.dispose();
        });
        container.read(authControllerProvider);
        await h.ready();
        await h.selectTask();
        final nav = container.read(navigationProvider);
        await nav.start(
          h.controller.selectedTask!,
          chosenProfile: NavigationProfile.motorcycle,
          manualOrigin: const LatLng(14, 121),
        );
        expect(nav.active, isTrue);
        expect(nav.road, isNotNull);
        if (cause == 'hidden task') {
          h.detailError = const AccountFailure('Task hidden', status: 404);
          await h.controller.refreshTasks();
        } else if (cause == 'lost Home capability') {
          h.home['data']['capabilities']['home'] = false;
          await h.controller.refreshHome();
        } else {
          await container.read(authControllerProvider.notifier).logout();
          container.read(
            navigationProvider,
          ); // Flush identity-dependent disposal.
        }
        expect(nav.active, isFalse);
        expect(nav.starting, isFalse);
        expect(nav.road, isNull);
        expect(nav.task, isNull);
      },
    );
  }
}
