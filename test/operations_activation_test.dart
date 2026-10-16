import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/work_summary.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;

// Exercise the ordinary build's activation flag through the actual controller
// and duty control, with isolated server responses and no live writes.
class _ActivationHarness {
  _ActivationHarness({this.assigned = false}) {
    final preview = support.fixture('pickup-task')['data'];
    preview['preview'] = true;
    preview['assignment_reference'] = null;
    preview['operational_stage'] = 'unassigned';
    preview['actions']['claim'] = true;
    available = OperationTask.fromJson(preview);
    api.respond = (path, method, body, headers) async {
      if (method != 'GET') {
        // The UI/controller must still persist before the first dispatch.
        final intent = journal.value!;
        expect(headers['Idempotency-Key'], intent.key);
        expect(body, intent.body);
        if (path == 'rider/duty') {
          onDuty = (body as Map)['on_duty'] as bool;
        } else {
          expect(path, 'rider/pickup-jobs/1/claim');
          expect(body, {'expected_version': available.version});
          assigned = true;
        }
        return support.command(intent);
      }
      if (path == 'rider/home') {
        final home = support.fixture('home');
        home['data']['on_duty'] = onDuty;
        home['data']['eligibility']['can_claim'] = onDuty;
        home['data']['eligibility']['claim_denial'] = onDuty
            ? null
            : 'OFF_DUTY';
        home['data']['counts'] = {
          'available': assigned ? 0 : 1,
          'pickup': assigned ? 1 : 0,
          'final_mile': 0,
        };
        return home;
      }
      if (path == 'rider/tasks/pickup-1') {
        expect(assigned, isTrue);
        return support.fixture('pickup-task');
      }
      final items = path.startsWith('rider/pickup-jobs')
          ? [if (!assigned) preview]
          : [
              if (assigned && path.contains('phase=pickup'))
                support.fixture('pickup-task')['data'],
            ];
      return {
        'data': {
          'items': items,
          'pagination': {
            'page': 1,
            'per_page': 20,
            'total': items.length,
            'last_page': 1,
          },
        },
      };
    };
    work = WorkspaceController(
      OperationsRepository(
        api,
        accountId: '5',
        journal: journal,
        writesVerified: AppConfig.environment().operationsWritesVerified,
        isCurrent: () => true,
      ),
    );
  }

  final api = support.Session();
  final journal = support.Journal();
  late final OperationTask available;
  late final WorkspaceController work;
  bool assigned, onDuty = true;
  int get writes => api.calls.where((call) => call.method != 'GET').length;
  Future<void> ready() => Future<void>.delayed(Duration.zero);
}

void main() {
  final enabled = AppConfig.environment().operationsWritesVerified;
  testWidgets('ordinary duty control honors activation and keeps owned work', (
    tester,
  ) async {
    final h = _ActivationHarness(assigned: true);
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRiderTheme(),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: h.work,
            builder: (context, _) => WorkDutyControl(controller: h.work),
          ),
        ),
      ),
    );
    expect(
      tester.widget<Switch>(find.byType(Switch)).onChanged != null,
      enabled,
    );
    if (enabled) {
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(h.writes, 1);
      expect(h.work.homeData.data?.onDuty, isFalse);
      expect(h.work.homeData.data?.canClaim, isFalse);
      expect(h.work.homeData.data?.claimDenial, 'OFF_DUTY');
      expect(h.journal.value, isNull);
    } else {
      await h.work.setDuty(false);
      expect(h.writes, 0);
      expect(h.work.homeData.data?.onDuty, isTrue);
    }
    expect(h.work.visibleTasks.single.id, 'pickup-1');
    await tester.pumpWidget(const SizedBox.shrink());
    h.work.dispose();
  });

  test(
    'ordinary claim activation opens fresh owned detail after confirmation',
    () async {
      final h = _ActivationHarness();
      addTearDown(h.work.dispose);
      await h.ready();
      await h.work.openTask(OperationsRepository.asRiderTask(h.available));
      await h.work.claimTask(h.available);
      if (!enabled) {
        expect(h.writes, 0);
        expect(h.work.selectedTask?.preview, isTrue);
        return;
      }
      expect(h.writes, 1);
      final claim = h.api.calls.indexWhere((call) => call.method == 'POST');
      final detail = h.api.calls.indexWhere(
        (call) => call.path == 'rider/tasks/pickup-1',
      );
      expect(claim, greaterThanOrEqualTo(0));
      expect(detail, greaterThan(claim));
      expect(h.work.selectedTask?.preview, isFalse);
      expect(h.work.selectedTask?.stage, 'assigned_pickup');
      expect(h.work.selectedTask?.custodyKind, 'seller');
      expect(h.work.queue, TaskQueue.pickups);
      expect(h.work.visibleTasks.single.id, 'pickup-1');
      expect(h.work.pendingIntent, isNull);
      expect(h.journal.value, isNull);
    },
  );
}
