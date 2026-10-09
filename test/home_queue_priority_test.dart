import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'operations_contract_test.dart' as support;

void main() {
  test(
    'first Home load opens existing responsibilities even while off duty',
    () async {
      final api = support.Session();
      final home = support.fixture('home');
      home['data']['on_duty'] = false;
      home['data']['eligibility']['can_claim'] = false;
      home['data']['eligibility']['claim_denial'] = 'OFF_DUTY';
      home['data']['counts'] = {'available': 0, 'pickup': 0, 'final_mile': 1};
      api.respond = (path, method, data, headers) async {
        if (path == 'rider/home') return home;
        return {
          'data': {
            'items': [support.fixture('final-mile-task')['data']],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 1,
              'last_page': 1,
            },
          },
        };
      };
      final controller = WorkspaceController(
        OperationsRepository(
          api,
          accountId: '5',
          journal: support.Journal(),
          writesVerified: false,
          isCurrent: () => true,
        ),
      );
      try {
        await controller.refreshAll();
        expect(controller.queue, TaskQueue.delivery);
        expect(controller.taskData.data!.single.operation!.phase, 'final_mile');
        expect(controller.homeData.data!.onDuty, false);
        expect(controller.canWrite, false);
        expect(api.calls.any((r) => r.path.contains('phase=final_mile')), true);
        expect(api.calls.any((r) => r.method != 'GET'), false);
      } finally {
        controller.dispose();
      }
    },
  );
  test(
    'an explicit available-queue choice survives Home discovery and refresh',
    () async {
      final api = support.Session();
      final home = support.fixture('home');
      home['data']['counts'] = {'available': 0, 'pickup': 2, 'final_mile': 0};
      api.respond = (path, method, data, headers) async {
        if (path == 'rider/home') return home;
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
      };
      final controller = WorkspaceController(
        OperationsRepository(
          api,
          accountId: '5',
          journal: support.Journal(),
          writesVerified: false,
          isCurrent: () => true,
        ),
      );
      try {
        controller.selectQueue(TaskQueue.available);
        await controller.refreshAll();
        await controller.refreshAll();
        expect(controller.queue, TaskQueue.available);
        expect(
          api.calls.where((r) => r.path.startsWith('rider/pickup-jobs')),
          isNotEmpty,
        );
        expect(api.calls.any((r) => r.path.contains('phase=pickup')), false);
      } finally {
        controller.dispose();
      }
    },
  );
}
