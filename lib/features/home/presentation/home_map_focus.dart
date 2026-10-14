import 'package:latlong2/latlong.dart';

import '../../navigation/data/philippines_map_region.dart';
import '../../navigation/data/route_geometry.dart';
import '../data/operations_models.dart';

enum HomeMapFocusKind { navigation, selectedStop, queuedStops, overview }

/// Presentation only: current authorization and unchanged coordinates belong
/// to the server/controller, even when the stop lies outside the map outline.
class HomeMapFocus {
  const HomeMapFocus._(
    this.kind,
    this.points,
    this.label,
    this.key, {
    this.outsideOutline = false,
    this.missingCoordinates = false,
  });
  final HomeMapFocusKind kind;
  final List<LatLng> points;
  final String label, key;
  final bool outsideOutline, missingCoordinates;

  factory HomeMapFocus.resolve({
    required PhilippinesMapRegion region,
    OperationTask? navigatingTask,
    LocationFix? fix,
    RoadRoute? road,
    OperationTask? selectedTask,
    required List<OperationTask> queuedTasks,
  }) {
    final current = navigatingTask ?? selectedTask;
    final stop = pointFor(current);
    if (current != null) {
      final key =
          '${navigatingTask == null ? 'selected' : 'navigation'}:${current.id}:${current.stop.kind}:$stop';
      if (stop == null || !region.containsLand(stop)) {
        return HomeMapFocus._(
          HomeMapFocusKind.overview,
          const [],
          'Philippines overview',
          key,
          outsideOutline: stop != null,
          missingCoordinates: stop == null,
        );
      }
      final points = <LatLng>[stop];
      if (navigatingTask != null) {
        if (fix != null && PhilippinesMapRegion.inCameraArea(fix.point)) {
          points.add(fix.point);
        }
        if (road != null) {
          points.addAll(
            road.lines
                .expand((line) => line)
                .where(PhilippinesMapRegion.inCameraArea),
          );
        }
      }
      return HomeMapFocus._(
        navigatingTask == null
            ? HomeMapFocusKind.selectedStop
            : HomeMapFocusKind.navigation,
        List.unmodifiable(points),
        navigatingTask == null
            ? 'Selected stop'
            : road == null
            ? 'Current stop'
            : 'Current route',
        key,
      );
    }
    final points = [
      for (final task in queuedTasks)
        if (pointFor(task) case final point? when region.containsLand(point))
          point,
    ];
    return HomeMapFocus._(
      points.isEmpty ? HomeMapFocusKind.overview : HomeMapFocusKind.queuedStops,
      List.unmodifiable(points),
      points.isEmpty ? 'Philippines overview' : 'Stops in this queue',
      'queue:${points.join(';')}',
    );
  }

  static LatLng? pointFor(OperationTask? task) {
    final stop = task?.stop;
    if (stop?.latitude == null || stop?.longitude == null) return null;
    final point = LatLng(stop!.latitude!, stop.longitude!);
    return validPoint(point) ? point : null;
  }

  static List<OperationTask> pins({
    required List<OperationTask> queuedTasks,
    OperationTask? selectedTask,
    OperationTask? navigatingTask,
  }) {
    final tasks = {for (final task in queuedTasks) task.id: task};
    if (selectedTask != null) {
      tasks[selectedTask.id] = selectedTask;
    }
    if (navigatingTask != null) {
      tasks[navigatingTask.id] = navigatingTask;
    }
    return tasks.values
        .where((task) => pointFor(task) != null)
        .toList(growable: false);
  }
}
