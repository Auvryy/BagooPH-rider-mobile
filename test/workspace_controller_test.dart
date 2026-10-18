import 'dart:async';

import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledRepository implements WorkspaceRepository {
  final List<Completer<FeatureData<List<RiderTask>>>> requests = [];
  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) {
    final pending = Completer<FeatureData<List<RiderTask>>>();
    requests.add(pending);
    return pending.future;
  }

  @override
  Future<FeatureData<List<RiderTrip>>> trips() async =>
      const FeatureData.ready([]);
}

Future<void> settleController() => Future<void>.delayed(Duration.zero);
void main() {
  test('missing operational contracts remain unavailable rather than empty success', () async {
    final controller = WorkspaceController(
      const UnavailableWorkspaceRepository(),
    );
    addTearDown(controller.dispose);
    await settleController();
    expect(controller.taskData.status, FeatureStatus.unavailable);
    expect(controller.tripData.status, FeatureStatus.unavailable);
    expect(controller.messages.inbox.status, FeatureStatus.unavailable);
    expect(await controller.messages.sendDraft(), isFalse);
  });
  test('a late old queue response cannot overwrite a newly selected queue or disposed scope', () async {
    final repository = ControlledRepository();
    final controller = WorkspaceController(repository);
    controller.selectQueue(TaskQueue.delivery);
    const current = RiderTask(
      id: 'delivery',
      tracking: 'TEST-D',
      stage: 'Assigned',
      stop: 'Hub',
      address: 'Test street',
      nextStep: 'View assignment',
    );
    repository.requests[1].complete(const FeatureData.ready([current]));
    await settleController();
    repository.requests[0].complete(const FeatureData.ready([]));
    await settleController();
    expect(controller.visibleTasks.single.id, 'delivery');
    final reload = controller.refreshTasks();
    controller.dispose();
    repository.requests[2].complete(const FeatureData.ready([current]));
    await reload;
    expect(controller.taskData.data, isNull);
  });
  // Assignment chat now has its own typed controller and failure/lifecycle
  // coverage in messages_controller_test.dart and messages_pages_test.dart.
  test(
    'money and Philippine calendar dates preserve exact displayed meaning',
    () {
      expect(pesos(100001), '₱1,000.01');
      expect(pesos(-1), '-₱0.01');
      expect(dayLabel(DateTime.utc(2026, 10, 7, 20)), 'Oct 8, 2026');
      expect(calendarDateLabel(DateTime(2026, 10, 7)), 'Oct 7, 2026');
    },
  );
}
