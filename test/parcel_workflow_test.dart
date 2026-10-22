import 'dart:async';

import 'package:bagoo_rider_mobile/app/theme.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/parcels/presentation/parcel_action_controller.dart';
import 'package:bagoo_rider_mobile/features/parcels/presentation/parcel_action_page.dart';
import 'package:bagoo_rider_mobile/features/parcels/presentation/waybill_scanner_page.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

class _Workflow {
  _Workflow({ParcelAction action = ParcelAction.pickup})
    : domain = ParcelHarness(action: action) {
    work = WorkspaceController(domain.repository);
  }
  final ParcelHarness domain;
  late final WorkspaceController work;
  ParcelActionController? action;
  Future<ParcelActionController> open() async {
    await Future<void>.delayed(Duration.zero);
    await work.openTask(OperationsRepository.asRiderTask(domain.task));
    action = ParcelActionController(
      work: work,
      taskId: domain.task.id,
      action: domain.action,
    );
    await Future<void>.delayed(Duration.zero);
    return action!;
  }

  void dispose() {
    action?.dispose();
    work.dispose();
  }

  int get writes =>
      domain.api.calls.where((call) => call.method == 'POST').length;
}

void main() {
  test(
    'fresh owned pickup requires a submitted matching scan before collection',
    () async {
      final h = _Workflow();
      addTearDown(h.dispose);
      final c = await h.open();
      expect(c.canCapture, isTrue);
      expect(c.canSubmit, isFalse);
      expect(await c.submit(), isFalse);
      c.acceptScan('BGO-ANOTHER-PARCEL');
      expect(c.failure?.fields['barcode'], isNotNull);
      expect(c.canSubmit, isFalse);
      c.acceptScan(h.domain.task.tracking.toLowerCase());
      expect(c.canSubmit, isTrue);
      expect(await c.submit(), isTrue);
      expect(h.writes, 1);
      expect(h.work.queue, TaskQueue.pickups);
      expect(c.result?['operational_stage'], 'picked_up');
    },
  );

  test('collection refreshes the origin-hub responsibility without recording its intake', () async {
    final h = _Workflow();
    addTearDown(h.dispose);
    final c = await h.open();
    h.domain.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        final result = parcelCommand(h.domain.journal.value!);
        h.domain.taskJson['operational_stage'] = 'picked_up';
        h.domain.taskJson['version'] = 'b' * 64;
        h.domain.taskJson['stop']['kind'] = 'origin_hub';
        h.domain.taskJson['actions']['pickup'] = false;
        h.domain.taskJson['next_instruction'] =
            'Bring the parcel to the origin hub. Its handler confirms intake.';
        return result;
      }
      return h.domain.standardResponse(path, method, body, headers);
    };
    c.acceptScan(h.domain.task.tracking);
    expect(await c.submit(), isTrue);
    expect(h.work.selectedTask?.stop.kind, 'origin_hub');
    expect(h.work.selectedTask?.actions['pickup'], isFalse);
    expect(
      h.domain.api.calls.where((call) => call.method == 'POST').single.path,
      endsWith('/pickup'),
    );
  });

  test(
    'departure keeps final-mile selection and refreshes its buyer stop',
    () async {
      final h = _Workflow(action: ParcelAction.depart);
      addTearDown(h.dispose);
      final c = await h.open();
      h.domain.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          final result = parcelCommand(h.domain.journal.value!);
          h.domain.taskJson['operational_stage'] = 'out_for_delivery';
          h.domain.taskJson['version'] = 'c' * 64;
          h.domain.taskJson['stop']['kind'] = 'buyer';
          h.domain.taskJson['actions']['depart'] = false;
          h.domain.taskJson['actions']['deliver'] = true;
          return result;
        }
        return h.domain.standardResponse(path, method, body, headers);
      };
      c.acceptScan(h.domain.task.tracking);
      expect(await c.submit(), isTrue);
      expect(h.work.queue, TaskQueue.delivery);
      expect(h.work.selectedTask?.phase, 'final_mile');
      expect(h.work.selectedTask?.stop.kind, 'buyer');
    },
  );

  test(
    'repeated confirmation cannot create a second command during an upload',
    () async {
      final h = _Workflow();
      addTearDown(h.dispose);
      final c = await h.open();
      final started = Completer<void>(), finish = Completer<void>();
      h.domain.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          started.complete();
          await finish.future;
        }
        return h.domain.standardResponse(path, method, body, headers);
      };
      c.acceptScan(h.domain.task.tracking);
      final first = c.submit();
      await started.future;
      expect(c.submitting, isTrue);
      expect(await c.submit(), isFalse);
      finish.complete();
      expect(await first, isTrue);
      expect(h.writes, 1);
    },
  );

  test(
    'resume and changed task require revalidation before a new confirmation',
    () async {
      final h = _Workflow();
      addTearDown(h.dispose);
      final c = await h.open();
      c.acceptScan(h.domain.task.tracking);
      c.setForeground(false);
      expect(c.canSubmit, isFalse);
      h.domain.taskJson['version'] = 'd' * 64;
      c.setForeground(true);
      await Future<void>.delayed(Duration.zero);
      expect(c.task?.version, 'd' * 64);
      expect(c.barcode, isNull);
      expect(h.writes, 0);
    },
  );

  test('access removal erases the visible task and scan', () async {
    final h = _Workflow();
    addTearDown(h.dispose);
    final c = await h.open();
    c.acceptScan(h.domain.task.tracking);
    h.domain.api.respond = (path, method, body, headers) async =>
        throw const AccountFailure('Access removed', status: 403);
    await c.refresh();
    expect(c.task, isNull);
    expect(c.barcode, isNull);
    expect(c.canCapture, isFalse);
    expect(c.canSubmit, isFalse);
  });

  test(
    'payment changes invalidate a scan even when the task version is unchanged',
    () async {
      final h = _Workflow(action: ParcelAction.deliver);
      addTearDown(h.dispose);
      final c = await h.open();
      final version = c.task!.version;
      c.acceptScan(h.domain.task.tracking);
      expect(c.canSubmit, isTrue);
      h.domain.taskJson['payment']['cod_due_cents'] = '12600';
      await h.work.openTask(OperationsRepository.asRiderTask(h.domain.task));
      expect(c.needsRevalidation, isTrue);
      expect(c.barcode, isNull);
      expect(c.canSubmit, isFalse);
      await c.refresh();
      expect(c.task!.version, version);
      expect(c.task!.codDueCents, BigInt.from(12600));
      expect(c.barcode, isNull);
      expect(c.canCapture, isTrue);
      expect(c.canSubmit, isFalse);
      expect(h.writes, 0);
    },
  );

  test('uncertain collection stays blocked and a later saved-result check shows success', () async {
    final h = _Workflow();
    addTearDown(h.dispose);
    final c = await h.open();
    h.domain.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Reply lost', unconfirmed: true);
      }
      return h.domain.standardResponse(path, method, body, headers);
    };
    c.acceptScan(h.domain.task.tracking);
    expect(await c.submit(), isFalse);
    expect(h.work.pendingIntent, isNotNull);
    expect(c.canSubmit, isFalse);
    final original = h.domain.journal.value!;
    h.domain.api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/commands/')) return parcelCommand(original);
      return h.domain.standardResponse(path, method, body, headers);
    };
    await h.work.checkPending();
    expect(c.result?['operational_stage'], 'picked_up');
    expect(h.work.pendingIntent, isNull);
    expect(h.writes, 1);
  });

  test('completed delivery clears the task without treating its expected 404 as failure', () async {
    final h = _Workflow(action: ParcelAction.deliver);
    addTearDown(h.dispose);
    final c = await h.open();
    h.domain.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        final result = parcelCommand(h.domain.journal.value!);
        h.domain.taskJson['operational_stage'] = 'delivered';
        return result;
      }
      if (path == 'rider/tasks/${h.domain.task.id}' &&
          h.domain.task.stage == 'delivered') {
        throw const AccountFailure('Terminal task hidden', status: 404);
      }
      return h.domain.standardResponse(path, method, body, headers);
    };
    c.acceptScan(h.domain.task.tracking);
    expect(
      await c.submit(fields: h.domain.fields, proof: h.domain.proof),
      isTrue,
    );
    expect(h.work.selectedTask, isNull);
    expect(h.work.workFailure, isNull);
    expect(h.work.workNotice, contains('buyer confirms receipt separately'));
    expect(h.work.queue, TaskQueue.delivery);
  });

  for (final width in [320.0, 900.0]) {
    testWidgets(
      'pickup review scrolls at width $width and 200 percent text without overflow',
      (tester) async {
        tester.view.physicalSize = Size(width, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = _Workflow();
        await tester.runAsync(h.open);
        h.action!.dispose();
        h.action = null;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRiderTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: ParcelActionPage(
              work: h.work,
              taskId: h.domain.task.id,
              action: ParcelAction.pickup,
              cameraAvailable: true,
              scan: (_, _) async => h.domain.task.tracking,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('parcel-scan')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('parcel-scan')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('parcel-matched-scan')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('parcel-submit')));
        await tester.pumpAndSettle();
        final submit = tester.widget<FilledButton>(
          find.byKey(const ValueKey('parcel-submit')),
        );
        expect(submit.onPressed, isNotNull);
        expect(
          tester.getSize(find.byKey(const ValueKey('parcel-submit'))).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.byKey(const ValueKey('parcel-submit')));
        await tester.pumpAndSettle();
        expect(find.text('Collection recorded'), findsOneWidget);
        expect(h.writes, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        h.dispose();
      },
    );
  }

  testWidgets(
    'unsupported desktop scanner offers cancellation without a typed scan fallback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRiderTheme(),
          home: const WaybillScannerPage(expectedWaybill: 'BGO-SOFTWARE-TEST'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('requires an Android camera'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Cancel scan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'scanner closes and removes its private reference when task access changes',
    (tester) async {
      final allowed = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRiderTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => WaybillScannerPage(
                      expectedWaybill: 'BGO-PRIVATE-SOFTWARE-TEST',
                      authorization: allowed,
                      isAuthorized: () => allowed.value,
                    ),
                  ),
                ),
                child: const Text('Open scanner'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open scanner'));
      await tester.pumpAndSettle();
      expect(find.text('BGO-PRIVATE-SOFTWARE-TEST'), findsOneWidget);
      allowed.value = false;
      await tester.pumpAndSettle();
      expect(find.text('BGO-PRIVATE-SOFTWARE-TEST'), findsNothing);
      expect(find.text('Open scanner'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      allowed.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
