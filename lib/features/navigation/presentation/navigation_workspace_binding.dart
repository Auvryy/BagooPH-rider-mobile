import 'dart:async';

import '../../workspace/presentation/workspace_controller.dart';
import 'navigation_controller.dart';

/// Connects accepted work updates to navigation outside any map/widget lifecycle.
class NavigationWorkspaceBinding {
  NavigationWorkspaceBinding(this.workspace, this.navigation) {
    workspace.addListener(_sync);
    navigation.addListener(_sync);
    _sync();
  }

  final WorkspaceController workspace;
  final NavigationController navigation;

  void _sync() {
    final task = navigation.navigatingTask;
    final id = task?.id ?? navigation.pausedTaskId;
    if (id == null) return;
    if (workspace.workAccessUnavailable || workspace.isTaskUnavailable(id)) {
      unawaited(
        navigation.stop(
          reason: 'This task is no longer available. Refresh before navigating again.',
        ),
      );
      return;
    }
    final fresh = workspace.selectedTask;
    if (fresh != null) navigation.stopIfTaskChanged(fresh);
  }

  void dispose() {
    workspace.removeListener(_sync);
    navigation.removeListener(_sync);
  }
}
