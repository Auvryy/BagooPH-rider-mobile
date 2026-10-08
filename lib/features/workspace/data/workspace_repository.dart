import 'workspace_models.dart';

abstract interface class WorkspaceRepository {
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue);
  Future<FeatureData<List<RiderTrip>>> trips();
  Future<FeatureData<List<RiderConversation>>> conversations();
  Future<RiderMessage> send(String conversationId, String phase, String text);
  Future<void> acknowledge(
    String conversationId,
    String phase,
    String latestMessageId,
  );
}

/// Account access is deployed; these operational native contracts are not yet
/// provided. Do not call proposed URLs or treat missing resources as empty data.
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
  @override
  Future<FeatureData<List<RiderConversation>>> conversations() async =>
      const FeatureData.unavailable(
        'Use the Rider website to contact the seller or buyer for your assigned parcel. Mobile messages are not connected yet.',
      );
  @override
  Future<RiderMessage> send(
    String conversationId,
    String phase,
    String text,
  ) async => throw StateError('Messaging is unavailable.');
  @override
  Future<void> acknowledge(
    String conversationId,
    String phase,
    String latestMessageId,
  ) async => throw StateError('Messaging is unavailable.');
}
