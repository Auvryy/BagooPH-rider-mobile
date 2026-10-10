import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/data/workspace_repository.dart';
import 'command_journal.dart';
import 'operations_models.dart';

class OperationsRepository extends UnavailableWorkspaceRepository {
  OperationsRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.writesVerified,
    required this.isCurrent,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RiderSessionApi api;
  final String accountId;
  final CommandJournal journal;
  final bool writesVerified;
  final bool Function() isCurrent;
  final DateTime Function() now;
  bool _writing = false;
  OperationsHome? _home;
  TaskPage? lastPage;

  void _guard() {
    if (!isCurrent()) {
      throw const AccountFailure('Please sign in again.', status: 401);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) async {
    _guard();
    final response = await api.authenticatedRequest(
      path,
      method: method,
      data: data,
      headers: headers,
    );
    _guard();
    return Wire.object(response['data']);
  }

  Future<OperationsHome> home() async {
    final result = OperationsHome.fromJson(await _request('rider/home'));
    if (result.accountId != accountId) Wire.invalid();
    _home = result;
    return result;
  }

  Future<TaskPage> taskPage(TaskQueue queue, {int page = 1}) async {
    if (page < 1 || page > 10000) Wire.invalid();
    final perPage = (_home?.limits['per_page_max'] ?? 20).clamp(1, 20);
    final path = queue == TaskQueue.available
        ? 'rider/pickup-jobs?page=$page&per_page=$perPage'
        : 'rider/tasks?phase=${queue == TaskQueue.pickups ? 'pickup' : 'final_mile'}&page=$page&per_page=$perPage';
    final result = TaskPage.fromJson(await _request(path));
    if (result.page != page ||
        result.items.any(
          (t) => queue == TaskQueue.available
              ? !t.preview || t.phase != 'pickup'
              : t.preview ||
                    t.phase !=
                        (queue == TaskQueue.pickups ? 'pickup' : 'final_mile'),
        )) {
      Wire.invalid();
    }
    lastPage = result;
    return result;
  }

  @override
  Future<FeatureData<List<RiderTask>>> tasks(TaskQueue queue) async =>
      FeatureData.ready(
        (await taskPage(queue)).items.map(asRiderTask).toList(),
      );
  static RiderTask asRiderTask(OperationTask t) => RiderTask(
    id: t.id,
    tracking: t.tracking,
    stage: t.stage,
    stop: t.stop.name ?? 'Stop name unavailable',
    address: t.stop.address ?? 'Address unavailable',
    nextStep: t.nextInstruction,
    operation: t,
  );
  Future<OperationTask> detail(String id) async {
    Wire.taskId(id);
    final task = OperationTask.fromJson(await _request('rider/tasks/$id'));
    if (task.id != id || task.preview) Wire.invalid();
    return task;
  }

  Future<CommandIntent?> pending() async {
    _guard();
    final intent = await journal.read();
    _guard();
    if (intent != null && intent.accountId != accountId) Wire.invalid();
    return intent;
  }

  Future<Map<String, dynamic>> duty(bool desired) =>
      _newIntent('duty', 'rider', {'on_duty': desired});
  Future<Map<String, dynamic>> claim(OperationTask task) async {
    if (!task.preview ||
        task.phase != 'pickup' ||
        task.actions['claim'] != true) {
      throw const AccountFailure('Refresh this pickup before claiming it.');
    }
    return _newIntent('claim', task.id, {'expected_version': task.version});
  }

  Future<Map<String, dynamic>> _newIntent(
    String action,
    String resource,
    Map<String, dynamic> body,
  ) async {
    if (_writing) {
      throw const AccountFailure('A work request is already being checked.');
    }
    _writing = true;
    try {
      _guard();
      if (!writesVerified) {
        throw const AccountFailure(
          'Work actions are awaiting deployment verification.',
        );
      }
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the previous request before starting another.',
        );
      }
      final fresh = await home();
      if (fresh.capabilities[action == 'claim' ? 'pickup_claim' : 'duty'] !=
              true ||
          (action == 'claim' && !fresh.canClaim)) {
        throw AccountFailure(
          fresh.claimDenial ?? 'This work action is unavailable.',
        );
      }
      // Persist before the first dispatch. Storage failure prevents a write.
      final intent = CommandIntent(
        accountId: accountId,
        key: commandUuid(),
        action: action,
        resource: resource,
        body: body,
        createdAt: now().toUtc(),
      );
      await journal.write(intent);
      _guard();
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }

  Future<Map<String, dynamic>> _validateResult(
    CommandIntent intent,
    Map<String, dynamic> result,
  ) async {
    if (Wire.uuid(result['idempotency_key']) != intent.key ||
        result['action'] != intent.action ||
        result['resource'] != intent.resource ||
        result['state'] != 'committed') {
      Wire.invalid();
    }
    Wire.time(result['recorded_at']);
    Wire.time(result['expires_at']);
    Wire.boolean(result['retry_expired']);
    Wire.boolean(result['replayed']);
    final value = Wire.object(result['result']);
    if (intent.action == 'duty') {
      Wire.boolean(value['on_duty']);
    } else if (Wire.taskId(value['task_id']) != intent.resource ||
        Wire.id(value['delivery_id']) != intent.resource.substring(7)) {
      Wire.invalid();
    }
    _guard();
    await journal.clear();
    return value;
  }

  Future<Map<String, dynamic>> _dispatch(CommandIntent intent) async {
    try {
      return await _validateResult(
        intent,
        await _request(
          intent.path,
          method: intent.method,
          data: intent.body,
          headers: {
            'Idempotency-Key': intent.key,
            'X-Request-ID': commandUuid(),
          },
        ),
      );
    } on AccountFailure catch (error) {
      if (!error.unconfirmed &&
          [404, 409, 422].contains(error.status) &&
          !['IDEMPOTENCY_CONFLICT', 'COMMAND_EXPIRED'].contains(error.code)) {
        await journal.clear();
      }
      rethrow;
    } catch (_) {
      throw const AccountFailure(
        'The request result is uncertain. Check the saved request.',
        unconfirmed: true,
      );
    }
  }

  /// COMMAND_UNKNOWN is retained. The rider may explicitly retry the same key
  /// and unchanged body, but cannot start a replacement intent.
  Future<Map<String, dynamic>?> reconcile({bool retryUnknown = false}) async {
    if (_writing) {
      throw const AccountFailure('A work request is already being checked.');
    }
    _writing = true;
    try {
      final intent = await pending();
      if (intent == null) return null;
      try {
        return await _validateResult(
          intent,
          await _request('rider/commands/${intent.key}'),
        );
      } on AccountFailure catch (error) {
        if (error.code != 'COMMAND_UNKNOWN' || error.status != 404) rethrow;
        if (!retryUnknown) return null;
        if (!writesVerified ||
            now().toUtc().difference(intent.createdAt) >=
                const Duration(days: 7)) {
          throw const AccountFailure(
            'The saved request requires revalidation; its retry window is closed.',
          );
        }
        return await _dispatch(intent);
      }
    } finally {
      _writing = false;
    }
  }
}
