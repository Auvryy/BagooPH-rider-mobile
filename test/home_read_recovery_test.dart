import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/navigation/data/route_geometry.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_controller.dart';
import 'package:bagoo_rider_mobile/features/navigation/presentation/navigation_workspace_binding.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'navigation_test.dart' as navigation;
import 'operations_contract_test.dart' as support;

class RecoveryHarness {
  RecoveryHarness({Future<void> Function(String)? onSessionEnd}) {
    home['data']['counts'] = {'available': 0, 'pickup': 0, 'final_mile': 1};
    task['data']['stop']['latitude'] = 14.6;
    task['data']['stop']['longitude'] = 120.986;
    api.respond = respond;
    controller = WorkspaceController(
      OperationsRepository(
        api,
        accountId: '5',
        journal: journal,
        writesVerified: true,
        isCurrent: () => true,
      ),
      onSessionEnd: onSessionEnd,
    );
  }

  final api = support.Session();
  final journal = support.Journal();
  final home = support.fixture('home');
  final task = support.fixture('final-mile-task');
  late final WorkspaceController controller;
  AccountFailure? homeError, queueError, detailError, appendError, commandError;
  bool commandUnknown = false;
  Completer<Map<String, dynamic>>? nextHome, nextQueue, nextDetail, nextAppend;
  int total = 1;

  Map<String, dynamic> page(int number) => {
    'data': {
      'items': [task['data']],
      'pagination': {
        'page': number,
        'per_page': 20,
        'total': total,
        'last_page': total > 20 ? 2 : 1,
      },
    },
  };

  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? data,
    Map<String, String> headers,
  ) async {
    if (method != 'GET' || path.startsWith('rider/commands/')) {
      if (commandError case final error?) throw error;
      if (commandUnknown && method == 'GET') {
        throw const AccountFailure(
          'Unknown command',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      return support.command(journal.value!);
    }
    if (path == 'rider/home') {
      if (homeError case final error?) throw error;
      final pending = nextHome;
      nextHome = null;
      return pending == null ? home : pending.future;
    }
    if (path.startsWith('rider/tasks/')) {
      if (detailError case final error?) throw error;
      final pending = nextDetail;
      nextDetail = null;
      return pending == null ? task : pending.future;
    }
    if (Uri.parse(path).queryParameters['page'] == '2') {
      if (appendError case final error?) throw error;
      final pending = nextAppend;
      nextAppend = null;
      return pending == null ? page(2) : pending.future;
    }
    if (queueError case final error?) throw error;
    final pending = nextQueue;
    nextQueue = null;
    return pending == null
        ? path.contains('phase=final_mile')
              ? page(1)
              : {
                  'data': {
                    'items': [],
                    'pagination': {
                      'page': 1,
                      'per_page': 20,
                      'total': 0,
                      'last_page': 1,
                    },
                  },
                }
        : pending.future;
  }

  Future<void> ready() => Future<void>.delayed(Duration.zero);
  Future<void> selectTask() =>
      controller.openTask(controller.visibleTasks.single);
}

void main() {
  for (final status in [401, 403]) {
    test(
      'access denial $status clears work and navigation before slow session cleanup',
      () async {
        final cleanup = Completer<void>();
        final h = RecoveryHarness(onSessionEnd: (_) => cleanup.future);
        final routes = navigation.Routes();
        final nav = NavigationController(
          routes: routes,
          authorize: (id) => h.controller.operations!.detail(id),
          vehicleType: () async => 'motorcycle',
          manual: true,
        );
        final binding = NavigationWorkspaceBinding(h.controller, nav);
        addTearDown(() {
          if (!cleanup.isCompleted) cleanup.complete();
          binding.dispose();
          nav.dispose();
          routes.dispose();
          h.controller.dispose();
        });
        await h.ready();
        await h.selectTask();
        await nav.start(
          h.controller.selectedTask!,
          manualOrigin: const LatLng(14, 121),
        );
        expect(nav.active, isTrue);
        h.detailError = AccountFailure('Access denied', status: status);
        final refreshing = h.controller.refreshTasks();
        await h.ready();
        expect(cleanup.isCompleted, isFalse);
        expect(nav.active, isFalse);
        expect(nav.road, isNull);
        expect(h.controller.selectedTask, isNull);
        expect(h.controller.taskData.data, isNull);
        expect(h.controller.tripData.data, isNull);
        expect(h.controller.messages.inbox.data, isNull);
        expect(h.controller.canWrite, isFalse);
        cleanup.complete();
        await refreshing;
      },
    );
  }
  test('accepted Home recovery clears its obsolete read failure', () async {
    final h = RecoveryHarness();
    addTearDown(h.controller.dispose);
    await h.ready();
    h.homeError = const AccountFailure('Home unavailable', status: 503);
    await h.controller.refreshHome();
    expect(h.controller.homeData.status, FeatureStatus.failed);
    expect(h.controller.workFailure?.message, 'Home unavailable');
    h.homeError = null;
    await h.controller.refreshHome();
    expect(h.controller.homeData.status, FeatureStatus.ready);
    expect(h.controller.workFailure, isNull);
  });

  test(
    'selected detail 404 during refresh removes its row and selection',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      await h.selectTask();
      final id = h.controller.selectedTask!.id;
      h.detailError = const AccountFailure('Task unavailable', status: 404);
      await h.controller.refreshTasks();
      expect(h.controller.selectedTask, isNull);
      expect(h.controller.unavailableTaskId, id);
      expect(h.controller.visibleTasks, isEmpty);
      expect(h.controller.taskData.status, FeatureStatus.failed);
      expect(h.controller.homeData.status, FeatureStatus.failed);
    },
  );

  test(
    'Home recovery leaves an uncertain command and its original UUID intact',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      h.commandError = const AccountFailure(
        'Result uncertain',
        unconfirmed: true,
      );
      await h.controller.setDuty(false);
      final saved = h.journal.value!;
      expect(h.controller.pendingIntent?.key, saved.key);
      expect(h.controller.homeData.status, FeatureStatus.ready);
      h.commandError = null;
      h.commandUnknown = true;
      h.homeError = const AccountFailure('Read outage', status: 503);
      await h.controller.refreshHome();
      h.homeError = null;
      await h.controller.refreshHome();
      expect(h.controller.workFailure?.unconfirmed, isTrue);
      expect(h.controller.pendingIntent?.key, saved.key);
      expect(h.journal.value?.body, saved.body);
      expect(h.controller.canWrite, isFalse);
      await h.controller.setDuty(true);
      expect(h.api.calls.where((r) => r.method != 'GET'), hasLength(1));
      h.commandUnknown = false;
      await h.controller.refreshHome();
      expect(h.controller.pendingIntent, isNull);
      expect(h.controller.workFailure, isNull);
    },
  );

  test(
    'Home success does not clear a queue failure; accepted queue data does',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      h.queueError = const AccountFailure('Queue unavailable', status: 503);
      await h.controller.refreshTasks();
      expect(h.controller.taskData.status, FeatureStatus.failed);
      expect(h.controller.visibleTasks, hasLength(1));
      await h.controller.refreshHome();
      expect(h.controller.workFailure?.message, 'Queue unavailable');
      h.queueError = null;
      await h.controller.refreshTasks();
      expect(h.controller.taskData.status, FeatureStatus.ready);
      expect(h.controller.workFailure, isNull);
    },
  );

  test(
    'failed first page stays failed and does not report an empty queue',
    () async {
      final h = RecoveryHarness()
        ..queueError = const AccountFailure('Queue unavailable', status: 503);
      addTearDown(h.controller.dispose);
      await h.ready();
      expect(h.controller.taskData.status, FeatureStatus.failed);
      expect(h.controller.taskData.data, isNull);
      h.queueError = null;
      await h.controller.refreshTasks();
      expect(h.controller.taskData.status, FeatureStatus.ready);
      expect(h.controller.visibleTasks, hasLength(1));
      expect(h.controller.workFailure, isNull);
    },
  );

  test(
    'failed append preserves the page and rows until an accepted retry',
    () async {
      final h = RecoveryHarness()..total = 21;
      addTearDown(h.controller.dispose);
      await h.ready();
      h.appendError = const AccountFailure('More unavailable', status: 503);
      await h.controller.loadMoreTasks();
      expect(h.controller.taskPage!.page, 1);
      expect(h.controller.taskData.status, FeatureStatus.ready);
      expect(h.controller.visibleTasks, hasLength(1));
      expect(h.controller.loadingMore, isFalse);
      expect(h.controller.loadMoreFailure, isNotNull);
      await h.controller.refreshHome();
      expect(h.controller.loadMoreFailure, isNotNull);
      h.appendError = null;
      await h.controller.loadMoreTasks();
      expect(h.controller.taskPage!.page, 2);
      expect(
        h.controller.visibleTasks,
        hasLength(1),
      ); // Same ID is deduplicated.
      expect(h.controller.workFailure, isNull);
    },
  );

  test(
    'a transient selected-detail failure retains a labelled stale selection',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      await h.selectTask();
      final selected = h.controller.selectedTask;
      h.detailError = const AccountFailure('Stop unavailable', status: 503);
      await h.controller.refreshTasks();
      expect(h.controller.selectedTask, same(selected));
      expect(h.controller.taskData.status, FeatureStatus.failed);
      expect(h.controller.unavailableTaskId, isNull);
      h.detailError = null;
      await h.controller.refreshTasks();
      expect(h.controller.taskData.status, FeatureStatus.ready);
      expect(h.controller.workFailure, isNull);
    },
  );

  test(
    'invalidation cancels an old append so it cannot restore the hidden row',
    () async {
      final h = RecoveryHarness()..total = 21;
      addTearDown(h.controller.dispose);
      await h.ready();
      await h.selectTask();
      final append = Completer<Map<String, dynamic>>();
      h.nextAppend = append;
      final loading = h.controller.loadMoreTasks();
      h.detailError = const AccountFailure('Task unavailable', status: 404);
      await h.controller.refreshTasks();
      append.complete(h.page(2));
      await loading;
      expect(h.controller.visibleTasks, isEmpty);
      expect(h.controller.selectedTask, isNull);
      expect(h.controller.taskData.status, FeatureStatus.failed);
      expect(h.controller.loadingMore, isFalse);
    },
  );

  test(
    'old Home success cannot restore private work after accepted access denial',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      final older = Completer<Map<String, dynamic>>();
      h.nextHome = older;
      final reading = h.controller.refreshHome();
      h.homeError = const AccountFailure('Access denied', status: 403);
      await h.controller.refreshHome();
      older.complete(h.home);
      await reading;
      expect(h.controller.homeData.status, FeatureStatus.unavailable);
      expect(h.controller.taskData.data, isNull);
      expect(h.controller.selectedTask, isNull);
      expect(h.controller.canWrite, isFalse);
      expect(h.controller.workAccessUnavailable, isTrue);
      final calls = h.api.calls.length;
      await h.controller.refreshAll();
      expect(h.api.calls, hasLength(calls));
    },
  );

  test(
    'obsolete queue and detail replies cannot change the explicit queue',
    () async {
      final h = RecoveryHarness();
      addTearDown(h.controller.dispose);
      await h.ready();
      await h.selectTask();
      final detail = Completer<Map<String, dynamic>>();
      h.nextDetail = detail;
      final refreshing = h.controller.refreshTasks();
      await h.ready();
      h.controller.selectQueue(TaskQueue.available);
      await h.ready();
      detail.completeError(
        const AccountFailure('Old hidden detail', status: 404),
      );
      await refreshing;
      expect(h.controller.queue, TaskQueue.available);
      expect(h.controller.visibleTasks, isEmpty);
      expect(h.controller.taskData.status, FeatureStatus.ready);
      expect(h.controller.workFailure, isNull);
      expect(h.controller.unavailableTaskId, isNull);
    },
  );

  test(
    'accepted destination changes stop a route without a mounted Home',
    () async {
      final h = RecoveryHarness();
      final routes = navigation.Routes();
      final nav = NavigationController(
        routes: routes,
        authorize: (id) => h.controller.operations!.detail(id),
        vehicleType: () async => 'motorcycle',
        manual: true,
      );
      final binding = NavigationWorkspaceBinding(h.controller, nav);
      addTearDown(() {
        binding.dispose();
        nav.dispose();
        routes.dispose();
        h.controller.dispose();
      });
      await h.ready();
      await h.selectTask();
      await nav.start(
        h.controller.selectedTask!,
        manualOrigin: const LatLng(14, 121),
      );
      expect(nav.active, isTrue);
      h.task['data']['stop']['address'] = 'Another authorized address';
      await h.controller.refreshTasks();
      expect(nav.active, isFalse);
      expect(nav.road, isNull);
      expect(nav.message, contains('destination changed'));
    },
  );

  test(
    'a hidden task cancels a navigation start awaiting authorization',
    () async {
      final h = RecoveryHarness();
      final routes = navigation.Routes();
      final authorization = Completer<OperationTask>();
      final nav = NavigationController(
        routes: routes,
        authorize: (_) => authorization.future,
        vehicleType: () async => 'motorcycle',
        manual: true,
      );
      final binding = NavigationWorkspaceBinding(h.controller, nav);
      addTearDown(() {
        binding.dispose();
        nav.dispose();
        routes.dispose();
        h.controller.dispose();
      });
      await h.ready();
      await h.selectTask();
      final selected = h.controller.selectedTask!;
      final starting = nav.start(selected, manualOrigin: const LatLng(14, 121));
      await h.ready();
      expect(nav.starting, isTrue);
      h.detailError = const AccountFailure('Task unavailable', status: 404);
      await h.controller.refreshTasks();
      expect(nav.starting, isFalse);
      authorization.complete(selected);
      await starting;
      expect(nav.active, isFalse);
      expect(nav.task, isNull);
      expect(routes.calls, isEmpty);
    },
  );
  test(
    'a hidden task cancels a pending route and rejects its late geometry',
    () async {
      final h = RecoveryHarness();
      final routes = navigation.Routes();
      final response = Completer<RoadRoute>();
      routes.response = () => response.future;
      final nav = NavigationController(
        routes: routes,
        authorize: (id) => h.controller.operations!.detail(id),
        vehicleType: () async => 'motorcycle',
        manual: true,
      );
      final binding = NavigationWorkspaceBinding(h.controller, nav);
      addTearDown(() {
        binding.dispose();
        nav.dispose();
        routes.dispose();
        h.controller.dispose();
      });
      await h.ready();
      await h.selectTask();
      final starting = nav.start(
        h.controller.selectedTask!,
        manualOrigin: const LatLng(14, 121),
      );
      await h.ready();
      expect(nav.calculating, isTrue);
      final cancel = routes.calls.single.cancel;
      h.detailError = const AccountFailure('Task unavailable', status: 404);
      await h.controller.refreshTasks();
      expect(cancel.isCancelled, isTrue);
      response.complete(RoadRoute.geoJson(navigation.geometry));
      await starting;
      expect(nav.active, isFalse);
      expect(nav.road, isNull);
      expect(nav.task, isNull);
    },
  );
}
