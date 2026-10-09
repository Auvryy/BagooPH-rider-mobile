import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../home/data/operations_repository.dart';
import '../../settings/data/settings_models.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../workspace/presentation/workspace_controller.dart';
import '../data/geoapify_client.dart';
import '../data/navigation_location.dart';
import 'navigation_controller.dart';

final geoapifyProvider = Provider<GeoapifyClient>((ref) {
  final client = GeoapifyClient(ref.watch(appConfigProvider).geoapifyKey);
  ref.onDispose(client.dispose);
  return client;
}, dependencies: [appConfigProvider]);

// Persistent across Home's widget/tab lifecycle; destroyed on identity/access
// changes. No service starts until the rider explicitly presses Navigate.
final navigationProvider = Provider<NavigationController>(
  (ref) {
    final identity = ref.watch(
      authControllerProvider.select(
        (s) => (
          id: s.user?.id,
          approved: s.user?.approved,
          version: s.user?.operationsApiVersion,
        ),
      ),
    );
    final repository = ref.watch(workspaceRepositoryProvider);
    final manual = defaultTargetPlatform == TargetPlatform.linux;
    final controller = NavigationController(
      routes: ref.watch(geoapifyProvider),
      manual: manual,
      location: manual ? null : AndroidNavigationLocation(),
      authorize: (id) async {
        if (identity.approved != true || repository is! OperationsRepository) {
          throw StateError('Live task authorization is unavailable.');
        }
        return repository.detail(id);
      },
      vehicleType: () async {
        if (identity.id == null) return null;
        final settings = ref.read(
          settingsRepositoryProvider(SettingsIdentity(identity.id!)),
        );
        return settings.available
            ? (await settings.read()).managed['vehicle_type']
            : null;
      },
      onAccessDenied: (message) =>
          ref.read(authControllerProvider.notifier).discardSession(message),
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
  dependencies: [
    authControllerProvider,
    workspaceRepositoryProvider,
    geoapifyProvider,
    settingsRepositoryProvider,
  ],
);
