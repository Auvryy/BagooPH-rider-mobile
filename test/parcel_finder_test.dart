import 'dart:async';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/parcel_finder/data/parcel_location_labels.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_finder_support.dart';

void main() {
  group('Session labels', () {
    late ParcelLocationLabels labels;
    setUp(
      () => labels = ParcelLocationLabels(
        apiOrigin: Uri.parse(ParcelFinderHarness.origin),
        accountId: '5',
      ),
    );

    test('shared slots remain separate and scopes do not share memory', () {
      final first = OperationTask.fromJson(
        finderTaskJson(id: '9223372036854775807'),
      );
      final second = OperationTask.fromJson(finderTaskJson(id: '32'));
      expect(labels.set(first, ParcelSlot.bag2), isTrue);
      expect(labels.set(second, ParcelSlot.bag2), isTrue);
      labels.set(first, ParcelSlot.topBoxLeft);
      expect(labels.location(first), ParcelSlot.topBoxLeft);
      expect(labels.location(second), ParcelSlot.bag2);
      for (final other in [
        ParcelLocationLabels(
          apiOrigin: Uri.parse(ParcelFinderHarness.origin),
          accountId: '6',
        ),
        ParcelLocationLabels(
          apiOrigin: Uri.parse('https://other.example.test/api/v1'),
          accountId: '5',
        ),
        ParcelLocationLabels(
          apiOrigin: Uri.parse(ParcelFinderHarness.origin),
          accountId: '5',
        ),
      ]) {
        expect(other.location(first), isNull);
      }
    });

    test('refresh keeps labels while reassignment, corrected identity and terminal state remove them', () {
      final data = finderTaskJson();
      final original = OperationTask.fromJson(data);
      labels.set(original, ParcelSlot.bag1);
      final refreshed = finderClone(data)..['version'] = 'a' * 64;
      labels.observe(OperationTask.fromJson(refreshed));
      expect(labels.location(original), ParcelSlot.bag1);
      final changed = finderClone(data)
        ..['assignment_reference'] = 'CHK-TEST-NEXT';
      labels.observe(OperationTask.fromJson(changed));
      expect(labels.location(original), isNull);
      labels.set(original, ParcelSlot.bag1);
      final corrected = finderClone(data)
        ..['tracking_number'] = 'BGO-TEST-CORRECTED';
      labels.observe(OperationTask.fromJson(corrected));
      expect(labels.location(original), isNull);
      labels.set(original, ParcelSlot.bag1);
      labels.observe(
        OperationTask.fromJson(
          finderClone(data)..['operational_stage'] = 'at_origin_hub',
        ),
      );
      expect(labels.location(original), isNull);
    });

    test(
      'previews, missing assignment and ended phases cannot gain a label',
      () {
        for (final data in [
          finderTaskJson()..['preview'] = true,
          finderTaskJson()..['assignment_reference'] = null,
          finderTaskJson()..['assignment_reference'] = '',
          finderTaskJson(phase: 'final_mile', stage: 'delivered'),
        ]) {
          final task = OperationTask.fromJson(data);
          expect(labels.set(task, ParcelSlot.bag1), isFalse);
          expect(labels.location(task), isNull);
        }
        final returning = OperationTask.fromJson(
          finderTaskJson(phase: 'final_mile', stage: 'delivery_failed'),
        );
        expect(labels.set(returning, ParcelSlot.bag1), isTrue);
      },
    );

    test('partial and other queues cannot erase labels; a complete owned queue can', () {
      final pickup = OperationTask.fromJson(finderTaskJson());
      final delivery = OperationTask.fromJson(
        finderTaskJson(phase: 'final_mile'),
      );
      labels.set(pickup, ParcelSlot.bag1);
      labels.set(delivery, ParcelSlot.bag2);
      labels.observeQueue('available', [], complete: true);
      labels.observeQueue('pickup', [], complete: false);
      expect(labels.location(pickup), ParcelSlot.bag1);
      labels.observeQueue('pickup', [], complete: true);
      expect(labels.location(pickup), isNull);
      expect(labels.location(delivery), ParcelSlot.bag2);
      labels.clear();
      expect(labels.location(delivery), isNull);
    });

    test('suffix collisions extend while complete tracking and duplicate rows stay exact', () {
      expect(
        distinguishingTrackingSuffix('BGO-AABCDEF', [
          'BGO-AABCDEF',
          'BGO-BABCDEF',
        ]),
        'AABCDEF',
      );
      expect(
        distinguishingTrackingSuffix('BGO-BABCDEF', ['BGO-AABCDEF']),
        'BABCDEF',
      );
      expect(
        distinguishingTrackingSuffix('BGO-ABCDE1', ['BGO-ABCDE1']),
        'ABCDE1',
      );
      expect(distinguishingTrackingSuffix('SHORT', []), 'SHORT');
    });
  });

  group('Authorized work integration', () {
    test('each label edit revalidates ownership with one GET and preserves the operational journal', () async {
      final h = ParcelFinderHarness();
      addTearDown(h.dispose);
      await h.boot();
      await h.open();
      h.api.calls.clear();
      expect(await h.set(ParcelSlot.bag2), isNull);
      expect(h.work.parcelLocationFor(h.task()), ParcelSlot.bag2);
      expect(h.api.calls.single.method, 'GET');
      expect(h.api.calls.single.path, 'rider/tasks/pickup-31');
      expect(h.journal.value, isNull);
      expect(h.task().heldByMe, isFalse);
      expect(await h.set(null), isNull);
      expect(h.work.parcelLocationFor(h.task()), isNull);
    });

    test('changed assignment clears its old label without applying the reviewed edit to the new one', () async {
      final h = ParcelFinderHarness();
      addTearDown(h.dispose);
      await h.boot();
      await h.open();
      await h.set(ParcelSlot.bag2);
      final original = h.task();
      h.rows.first['assignment_reference'] = 'CHK-TEST-NEW';
      expect(
        await h.set(ParcelSlot.topBoxRight),
        contains('assignment changed'),
      );
      expect(h.labels.location(original), isNull);
      expect(h.labels.location(h.task()), isNull);
      expect(await h.set(ParcelSlot.topBoxRight), isNull);
      expect(h.work.parcelLocationFor(h.task()), ParcelSlot.topBoxRight);
    });

    test(
      'covered/background pages and changed selection reject late edits',
      () async {
        final h = ParcelFinderHarness(
          tasks: [
            finderTaskJson(),
            finderTaskJson(id: '32'),
          ],
        );
        addTearDown(h.dispose);
        await h.boot();
        await h.open();
        var visible = true;
        final gate = Completer<Map<String, dynamic>>();
        h.detailGate = gate;
        final save = h.set(ParcelSlot.bag1, mayApply: () => visible);
        visible = false;
        gate.complete({'data': finderClone(h.rows.first)});
        expect(await save, isNotNull);
        expect(h.labels.location(h.task()), isNull);
        visible = true;
        final next = Completer<Map<String, dynamic>>();
        h.detailGate = next;
        final oldSelection = h.set(ParcelSlot.bag1);
        await h.open(1);
        next.complete({'data': finderClone(h.rows.first)});
        expect(await oldSelection, isNotNull);
        expect(h.labels.location(h.task()), isNull);
        expect(h.labels.location(h.task(1)), isNull);
        h.work.setForeground(false);
        final calls = h.api.calls.length;
        expect(await h.set(ParcelSlot.bag1), isNotNull);
        expect(h.api.calls, hasLength(calls));
      },
    );

    for (final status in [403, 404, 503]) {
      test(
        'detail $status handles labels according to confirmed access, not a transient outage',
        () async {
          final h = ParcelFinderHarness();
          addTearDown(h.dispose);
          await h.boot();
          await h.open();
          final original = h.task();
          await h.set(ParcelSlot.bag2);
          h.detailFailure = AccountFailure(
            'Synthetic verification failure',
            status: status,
          );
          expect(await h.set(ParcelSlot.bag1), isNotNull);
          expect(
            h.labels.location(original),
            status == 503 ? ParcelSlot.bag2 : null,
          );
          expect(h.work.canSetParcelLocation(original), isFalse);
          expect(h.api.calls.where((call) => call.method != 'GET'), isEmpty);
        },
      );
    }

    test('queue switching preserves labels; complete removal and disposal clear them', () async {
      final h = ParcelFinderHarness(
        tasks: [
          finderTaskJson(),
          finderTaskJson(id: '32'),
        ],
      );
      await h.boot();
      await h.open();
      final first = h.task();
      await h.set(ParcelSlot.bag2);
      h.work.closeTask();
      h.work.selectQueue(TaskQueue.available);
      await Future<void>.delayed(Duration.zero);
      expect(h.labels.location(first), ParcelSlot.bag2);
      h.totalOverride = 21;
      h.rows.removeAt(0);
      h.work.selectQueue(TaskQueue.pickups);
      await Future<void>.delayed(Duration.zero);
      expect(h.labels.location(first), ParcelSlot.bag2);
      h.totalOverride = null;
      await h.work.refreshTasks();
      expect(h.labels.location(first), isNull);
      await h.open();
      final remaining = h.task();
      await h.set(ParcelSlot.bag1);
      expect(h.labels.location(remaining), ParcelSlot.bag1);
      h.dispose();
      expect(h.labels.location(remaining), isNull);
    });
  });
}
