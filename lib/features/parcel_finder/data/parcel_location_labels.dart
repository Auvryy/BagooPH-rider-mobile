import '../../home/data/operations_models.dart';

enum ParcelSlot {
  topBoxLeft('Top box left'),
  topBoxRight('Top box right'),
  bag1('Bag 1'),
  bag2('Bag 2');

  const ParcelSlot(this.label);
  final String label;
}

typedef _LabelKey = ({
  String api,
  String account,
  String task,
  String assignment,
  String tracking,
});

/// Personal organization only. This store has no I/O or operational commands.
class ParcelLocationLabels {
  ParcelLocationLabels({required Uri apiOrigin, required this.accountId})
    : _api = apiOrigin.toString();

  final String accountId;
  final String _api;
  final _labels = <_LabelKey, ParcelSlot>{};

  static bool supports(OperationTask task) =>
      !task.preview &&
      task.assignmentReference?.trim().isNotEmpty == true &&
      switch (task.phase) {
        'pickup' => const {
          'assigned',
          'assigned_pickup',
          'picked_up',
        }.contains(task.stage),
        'final_mile' => const {
          'assigned_to_rider',
          'out_for_delivery',
          'delivery_failed',
        }.contains(task.stage),
        _ => false,
      };

  _LabelKey _key(OperationTask task) => (
    api: _api,
    account: accountId,
    task: task.id,
    assignment: task.assignmentReference!,
    tracking: task.tracking,
  );

  ParcelSlot? location(OperationTask task) =>
      supports(task) ? _labels[_key(task)] : null;

  /// Call only with a successful, authorized observation, never cached preview
  /// data. Changing assignment or leaving its active phase clears the old label.
  void observe(OperationTask task) {
    _labels.removeWhere(
      (key, _) =>
          key.task == task.id &&
          (!supports(task) ||
              key.assignment != task.assignmentReference ||
              key.tracking != task.tracking),
    );
  }

  void observeQueue(
    String phase,
    Iterable<OperationTask> tasks, {
    required bool complete,
  }) {
    final rows = tasks.toList(growable: false);
    for (final task in rows) {
      observe(task);
    }
    if (!complete || !const {'pickup', 'final_mile'}.contains(phase)) return;
    final ids = rows
        .where((task) => task.phase == phase && supports(task))
        .map((task) => task.id)
        .toSet();
    _labels.removeWhere(
      (key, _) => key.task.startsWith('$phase-') && !ids.contains(key.task),
    );
  }

  bool set(OperationTask task, ParcelSlot? slot) {
    observe(task);
    if (!supports(task)) return false;
    if (slot == null) {
      _labels.remove(_key(task));
    } else {
      _labels[_key(task)] = slot;
    }
    return true;
  }

  void forget(String taskId) =>
      _labels.removeWhere((key, _) => key.task == taskId);
  void clear() => _labels.clear();
}

/// Keep the full identifier nearby. Extend a common suffix rather than hiding
/// a collision between two loaded, distinct tracking identifiers.
String distinguishingTrackingSuffix(String tracking, Iterable<String> others) {
  var count = tracking.length < 6 ? tracking.length : 6;
  final distinct = others.where((value) => value != tracking).toSet();
  while (count < tracking.length &&
      distinct.any(
        (value) => value.endsWith(tracking.substring(tracking.length - count)),
      )) {
    count++;
  }
  return tracking.substring(tracking.length - count);
}
