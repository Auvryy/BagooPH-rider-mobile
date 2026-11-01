import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/features/home/presentation/stop_guidance.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

void main() {
  test('only a recorded completed order is presented as completed', () {
    expect(deliveryRecordedNotice('completed'), contains('order completed'));
    expect(
      deliveryRecordedNotice('completed'),
      contains('separate hub receipt'),
    );
    expect(
      deliveryRecordedNotice('delivered'),
      contains('order status Delivered'),
    );
    for (final unknown in [null, 'out_for_delivery', 'future_status', 42]) {
      expect(deliveryRecordedNotice(unknown), contains('Refresh Trips'));
      expect(
        deliveryRecordedNotice(unknown),
        isNot(contains('order completed')),
      );
    }
  });

  test(
    'stop guidance preserves recovery authority and does not change task facts',
    () {
      final h = ParcelHarness(action: ParcelAction.deliver);
      h.taskJson['next_instruction'] =
          'Record recipient handoff. The buyer confirms receipt separately.';
      expect(taskInstruction(h.task), startsWith('Record recipient handoff.'));
      expect(taskInstruction(h.task), isNot(contains('buyer confirms')));
      h.taskJson['operational_stage'] = 'delivered';
      h.taskJson['commercial_status'] = 'completed';
      expect(taskInstruction(h.task), contains('order completed'));
      expect(nextActorLabel(h.task), startsWith('Delivery complete'));
      expect(legGuide(h.task), isNot(contains('buyer confirms')));
      h.taskJson['action_denials']['handover'] = 'HANDOVER_HOLD';
      h.taskJson['next_instruction'] =
          'Return this held parcel to the named hub.';
      expect(taskInstruction(h.task), h.task.nextInstruction);
      expect(nextActorLabel(h.task), contains('reviewed handover recovery'));
      expect(h.task.commercialStatus, 'completed');
      expect(h.task.stage, 'delivered');
    },
  );

  test('a changed order state invalidates a previously reviewed stop', () {
    final h = ParcelHarness(action: ParcelAction.deliver);
    final reviewed = h.task;
    h.taskJson['commercial_status'] = 'completed';
    expect(h.task.version, reviewed.version);
    expect(sameReviewedStop(reviewed, h.task), isFalse);
  });
}
