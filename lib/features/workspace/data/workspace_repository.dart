import 'workspace_models.dart';

abstract interface class WorkspaceRepository {
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue);
  Future<FeatureData<List<RiderTrip>>> trips();
}

/// Features without accepted live integration stay explicitly unavailable.
/// Operational v1 uses its own adapter after account capability discovery.
class UnavailableWorkspaceRepository implements WorkspaceRepository {
  const UnavailableWorkspaceRepository();
  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) async =>
      const FeatureData.unavailable(
        'Mobile work queues are not connected yet. You can view your tasks on the Rider website.',
      );
  @override
  Future<FeatureData<List<RiderTrip>>> trips() async =>
      const FeatureData.unavailable(
        'Your recorded trips are available on the Rider website. Mobile history is not connected yet.',
      );
}
