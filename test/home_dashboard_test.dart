import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/home_dashboard.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/geoapify_client.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_providers.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;

const account = RiderAccount(
  id: '5',
  name: 'Example Rider',
  email: 'rider@example.test',
  status: 'active',
  kycStatus: 'approved',
  approved: true,
  emailVerified: true,
  operationsApiVersion: 1,
);
void main() {
  testWidgets(
    'pins and cards select the same fresh owned task; missing coordinates keep address',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      final api = support.Session(), journal = support.Journal();
      final j =
          support.fixture('final-mile-task')['data'] as Map<String, dynamic>;
      j['stop']['latitude'] = 14.0;
      j['stop']['longitude'] = 121.0;
      final owned = OperationTask.fromJson(j);
      api.respond = (path, method, data, headers) async {
        if (path == 'rider/home') return support.fixture('home');
        if (path.startsWith('rider/tasks/')) return {'data': j};
        return {
          'data': {
            'items': [j],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 1,
              'last_page': 1,
            },
          },
        };
      };
      final repo = OperationsRepository(
        api,
        accountId: '5',
        journal: journal,
        writesVerified: false,
        isCurrent: () => true,
      );
      final controller = WorkspaceController(repo);
      controller.selectQueue(TaskQueue.delivery);
      final geo = GeoapifyClient('');
      final nav = NavigationController(
        routes: geo,
        authorize: (_) async => owned,
        vehicleType: () async => null,
        manual: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geoapifyProvider.overrideWithValue(geo),
            navigationProvider.overrideWithValue(nav),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: Scaffold(
              body: HomeDashboard(account: account, controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.text('Manual preview origin · no GPS tracking'),
        findsOneWidget,
      );
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      await tester.tap(find.byTooltip('Select ${owned.tracking}'));
      await tester.pumpAndSettle();
      expect(controller.selectedTask?.id, owned.id);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Origin latitude'), findsOneWidget);
      await tester.ensureVisible(find.text('Back to tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to tasks'));
      await tester.pumpAndSettle();
      expect(controller.selectedTask?.id, owned.id);
      await controller.openTask(OperationsRepository.asRiderTask(owned));
      expect(controller.selectedTask?.id, owned.id);
      j['stop']['latitude'] = null;
      j['stop']['longitude'] = null;
      await controller.openTask(OperationsRepository.asRiderTask(owned));
      expect(controller.selectedTask?.stop.latitude, isNull);
      expect(controller.selectedTask?.stop.address, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      nav.dispose();
      geo.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('map dashboard stays usable at $size and enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final controller = WorkspaceController(
        const UnavailableWorkspaceRepository(),
      );
      final geo = GeoapifyClient('');
      final nav = NavigationController(
        routes: geo,
        authorize: (_) async => throw StateError('unavailable'),
        vehicleType: () async => null,
        manual: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geoapifyProvider.overrideWithValue(geo),
            navigationProvider.overrideWithValue(nav),
          ],
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: HomeDashboard(account: account, controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      nav.dispose();
      geo.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
