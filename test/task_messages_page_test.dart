import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_mode_page.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as ops;
import 'support/messages_support.dart';
import 'support/test_auth_repository.dart';

void main() {
  testWidgets(
    'owned Stop Mode resolves its real thread and account loss closes the private route',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = MessagesHarness();
      addTearDown(h.dispose);
      final data = ops.fixture('pickup-task')['data'] as Map<String, dynamic>;
      data['id'] = 'pickup-31';
      data['delivery_id'] = '31';
      data['tracking_number'] = 'BGO-TEST31';
      data['assignment_reference'] = 'CHK-41';
      h.api.respond = (path, method, body, headers) async {
        if (path == 'rider/home') {
          final home = await h.respond(path, method, body, headers);
          home['data']['counts'] = {
            'available': 0,
            'pickup': 1,
            'final_mile': 0,
          };
          home['data']['limits']['poll_interval_seconds'] = 3600;
          return home;
        }
        if (path.startsWith('rider/tasks/')) return {'data': data};
        if (path.startsWith('rider/tasks?')) {
          return {
            'data': {
              'items': [data],
              'pagination': {
                'page': 1,
                'per_page': 20,
                'total': 1,
                'last_page': 1,
              },
            },
          };
        }
        if (path.startsWith('rider/trips?')) {
          return {
            'data': {
              'items': [],
              'pagination': {
                'page': 1,
                'per_page': 20,
                'total': 0,
                'last_page': 1,
              },
            },
          };
        }
        return h.respond(path, method, body, headers);
      };
      final work = WorkspaceController(
        OperationsRepository(
          h.api,
          accountId: '5',
          journal: ops.Journal(),
          writesVerified: false,
          isCurrent: () => true,
        ),
        messagesRepository: h.repository,
      );
      addTearDown(work.dispose);
      final auth = TestAuthRepository()
        ..account = const RiderAccount(
          id: '5',
          name: 'Test Rider',
          email: 'rider@example.test',
          status: 'active',
          kycStatus: 'approved',
          approved: true,
          emailVerified: true,
          operationsApiVersion: 1,
        );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await tester.pump();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildRiderTheme(),
            home: StopModePage(
              initialTask: OperationsRepository.asRiderTask(
                OperationTask.fromJson(data),
              ),
              controller: work,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        work.selectedTask?.id,
        'pickup-31',
        reason: work.workFailure?.message,
      );
      expect(work.homeData.data?.capabilities['messages'], isTrue);
      final shortcut = find.byKey(const ValueKey('stop-message'));
      await tester.scrollUntilVisible(
        shortcut,
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('stop-mode-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Message seller'), findsOneWidget);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('message-draft')), findsOneWidget);
      expect(work.messages.thread!.id, pickupThread);
      expect(work.messages.thread!.participantId, '3');
      expect(tester.takeException(), isNull);
      auth.account = const RiderAccount(
        id: '5',
        name: 'Test Rider',
        email: 'rider@example.test',
        status: 'pending_approval',
        kycStatus: 'pending',
        approved: false,
        emailVerified: true,
      );
      await container.read(authControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('message-draft')), findsNothing);
      expect(work.messages.messages, isEmpty);
      expect(work.messages.selectedId, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      work.setForeground(false);
      await tester.pump();
    },
  );
}
