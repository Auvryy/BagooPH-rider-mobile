import 'package:dio/dio.dart';

import '../../../core/commands/parcel_proof.dart';
import '../../../core/commands/parcel_validation.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../workspace/data/workspace_models.dart';
import '../../workspace/data/workspace_repository.dart';
import '../../parcels/data/parcel_photo_service.dart';
import '../../trips/data/trip_models.dart';
import 'command_journal.dart';
import 'operations_models.dart';

class OperationsRepository extends UnavailableWorkspaceRepository {
  OperationsRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.writesVerified,
    this.parcelWritesVerified = false,
    this.prepaidDeliveryWritesVerified = false,
    this.proofStore,
    this.photos,
    required this.isCurrent,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RiderSessionApi api;
  final String accountId;
  final CommandJournal journal;
  final bool writesVerified;
  final bool parcelWritesVerified;
  final bool prepaidDeliveryWritesVerified;
  final ParcelProofStore? proofStore;
  final ParcelPhotoService? photos;
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

  Future<RetainedTripPage> tripPage({
    int page = 1,
    TripFilters? filters,
  }) async {
    final path = Uri(
      path: 'rider/trips',
      queryParameters: (filters ?? TripFilters()).query(page),
    ).toString();
    final result = RetainedTripPage.fromJson(await _request(path));
    if (result.page != page) Wire.invalid();
    return result;
  }

  static RiderTrip asRiderTrip(RetainedTrip trip) => RiderTrip(
    id: trip.id,
    tracking: trip.tracking,
    recipient: trip.recipient ?? 'Recipient not recorded',
    address: trip.address ?? 'Handoff address not recorded',
    outcome: tripOutcomeLabel(trip.outcome),
    recordedAt: trip.assignedAt,
    payment: trip.paymentMethod == 'cod'
        ? PaymentFilter.cod
        : PaymentFilter.prepaid,
    checkpoints: [
      for (final checkpoint in trip.checkpoints)
        TripCheckpoint(
          tripOutcomeLabel(checkpoint.kind),
          checkpoint.recordedAt,
        ),
    ],
    operation: trip,
  );
  @override
  Future<FeatureData<List<RiderTrip>>> trips() async =>
      FeatureData.ready((await tripPage()).items.map(asRiderTrip).toList());
  Future<RetainedTrip> tripDetail(String id) async {
    tripId(id);
    final value = RetainedTrip.fromJson(await _request('rider/trips/$id'));
    if (value.id != id) Wire.invalid();
    return value;
  }

  Future<PrivateApiBytes> tripProof(String id, String path) async {
    _guard();
    final fresh = await tripDetail(id);
    if (!fresh.proofPaths.contains(path) || api is! RiderEvidenceSessionApi) {
      throw const AccountFailure(
        'This proof is unavailable for the original assignment.',
      );
    }
    final value = await (api as RiderEvidenceSessionApi).authenticatedEvidence(
      path,
    );
    _guard();
    if (!parcelProofMimes.values.contains(value.mimeType) ||
        value.bytes.isEmpty ||
        value.bytes.length > parcelProofLimit ||
        !parcelProofSignature(value.bytes, value.mimeType)) {
      throw const AccountFailure(
        'The private proof response could not be verified.',
      );
    }
    return value;
  }

  Future<CommandIntent?> pending() async {
    _guard();
    final intent = await journal.read();
    _guard();
    if (intent != null &&
        (intent.accountId != accountId ||
            intent.isMessage ||
            intent.isNotification)) {
      Wire.invalid();
    }
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

  /// The review is tied to this exact assignment, version and submitted scan.
  /// A fresh detail can reject a changed review; it never silently updates it.
  Future<Map<String, dynamic>> parcel(
    ParcelAction action,
    OperationTask reviewed, {
    required String barcode,
    Map<String, dynamic> fields = const {},
    ParcelProof? proof,
  }) async {
    if (_writing) {
      throw const AccountFailure('A work request is already being checked.');
    }
    _writing = true;
    ParcelProofReference? retained;
    var persisted = false;
    try {
      _guard();
      if (!parcelWritesVerified) {
        throw const AccountFailure(
          'Parcel actions are awaiting live acceptance verification.',
        );
      }
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the saved work request before starting another.',
        );
      }
      final freshHome = await home();
      if (freshHome.capabilities['parcel_actions'] != true) {
        throw const AccountFailure(
          'Parcel actions are unavailable for this account.',
        );
      }
      if (reviewed.preview ||
          reviewed.actions[action.name] != true ||
          action.requiresProof != (proof != null)) {
        throw const AccountFailure(
          'Refresh this parcel before reviewing its action.',
        );
      }
      final fresh = await detail(reviewed.id);
      if (fresh.version != reviewed.version ||
          fresh.assignmentReference != reviewed.assignmentReference ||
          fresh.actions[action.name] != true ||
          (action == ParcelAction.deliver &&
              fresh.paymentTerms != reviewed.paymentTerms)) {
        throw const AccountFailure(
          'This parcel changed. Refresh it and review the current action.',
          status: 409,
          code: 'STALE_RESOURCE',
        );
      }
      final scan = parcelWaybill(barcode);
      if (scan != fresh.tracking) {
        throw const AccountFailure(
          'That waybill belongs to a different parcel.',
          fields: {'barcode': 'Scan the waybill attached to this parcel.'},
        );
      }
      if (fields.containsKey('expected_version') ||
          fields.containsKey('barcode')) {
        Wire.invalid();
      }
      if (action == ParcelAction.deliver) {
        if (fresh.deliveryPaymentKind == DeliveryPaymentKind.unavailable) {
          throw const AccountFailure(
            'This payment cannot be confirmed for delivery. Refresh the parcel or contact your hub.',
          );
        }
        if (fresh.deliveryPaymentKind == DeliveryPaymentKind.paidWallet) {
          if (!prepaidDeliveryWritesVerified) {
            throw const AccountFailure(
              'Prepaid delivery is awaiting live acceptance verification.',
            );
          }
          if ([
            'cash_received',
            'change_given',
            'cash_confirmed',
          ].any(fields.containsKey)) {
            throw const AccountFailure(
              'This parcel is prepaid. Do not submit a cash collection.',
            );
          }
        } else if (pesoInputCents(Wire.string(fields['cash_received'])) -
                pesoInputCents(
                  Wire.string(fields['change_given']),
                  field: 'change_given',
                ) !=
            fresh.codDueCents) {
          throw const AccountFailure(
            'Received cash minus change must equal the recorded COD amount.',
            fields: {
              'cash_received':
                  'Check the received cash and change against COD.',
            },
          );
        }
      }
      if (action == ParcelAction.fail &&
          (fresh.failurePolicy == null ||
              !fresh.failurePolicy!.reasons.containsKey(fields['reason']))) {
        throw const AccountFailure(
          'Refresh the permitted failure reasons before reporting an attempt.',
        );
      }
      final key = commandUuid();
      if (proof != null) {
        final store = proofStore;
        if (store == null) {
          throw const AccountFailure('Protected proof storage is unavailable.');
        }
        retained = await store.save(key, proof);
        _guard();
      }
      final intent = CommandIntent(
        accountId: accountId,
        key: key,
        action: action.name,
        resource: fresh.id,
        body: {'expected_version': fresh.version, 'barcode': scan, ...fields},
        createdAt: now().toUtc(),
        proof: retained,
        deliveryPaymentMethod:
            action == ParcelAction.deliver &&
                fresh.deliveryPaymentKind == DeliveryPaymentKind.paidWallet
            ? 'wallet'
            : null,
      );
      await journal.write(intent);
      persisted = true;
      _guard();
      return await _dispatch(intent);
    } finally {
      // No request is dispatched if persistence fails. A persisted unresolved
      // intent always keeps its original image, including through logout.
      try {
        if (!persisted && retained != null) {
          // A failed secure-storage write can itself be uncertain. Remove only
          // an image which a successful journal read proves is unreferenced.
          try {
            final saved = await journal.read();
            if (saved?.proof?.key != retained.key) {
              await proofStore!.delete(retained);
            }
          } catch (_) {
            // Keep encrypted recovery evidence when storage cannot be checked.
          }
        }
      } finally {
        _writing = false;
      }
    }
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
      if (Wire.boolean(value['on_duty']) != intent.body['on_duty']) {
        Wire.invalid();
      }
    } else {
      if (Wire.taskId(value['task_id']) != intent.resource ||
          Wire.id(value['delivery_id']) != intent.deliveryId) {
        Wire.invalid();
      }
      if (intent.parcelAction != null) {
        Wire.string(value['commercial_status']);
        Wire.id(value['checkpoint_id']);
        final expectedStage = switch (intent.parcelAction!) {
          ParcelAction.pickup => 'picked_up',
          ParcelAction.depart => 'out_for_delivery',
          ParcelAction.deliver => 'delivered',
          ParcelAction.fail => 'delivery_failed',
        };
        if (Wire.string(value['operational_stage']) != expectedStage) {
          Wire.invalid();
        }
      }
    }
    _guard();
    await _clear(intent);
    _guard();
    return value;
  }

  Future<void> _clear(CommandIntent intent) async {
    if (intent.proof != null) {
      final store = proofStore;
      if (store == null) {
        throw const AccountFailure(
          'Protected proof cleanup is unavailable.',
          unconfirmed: true,
        );
      }
      await store.delete(intent.proof!);
      _guard();
    }
    await journal.clear();
  }

  Future<Map<String, dynamic>> _dispatch(CommandIntent intent) async {
    try {
      Object data = intent.body;
      if (intent.proof != null) {
        final store = proofStore;
        if (store == null) {
          throw const AccountFailure(
            'The saved original proof is unavailable.',
            unconfirmed: true,
          );
        }
        final original = await store.read(intent.proof!);
        _guard();
        data = FormData.fromMap({
          ...intent.body,
          if (intent.body['cash_confirmed'] == true) 'cash_confirmed': '1',
          'proof_image_file': MultipartFile.fromBytes(
            original.bytes,
            filename: original.filename,
            contentType: DioMediaType.parse(original.mime),
          ),
        });
      }
      return await _validateResult(
        intent,
        await _request(
          intent.path,
          method: intent.method,
          data: data,
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
        await _clear(intent);
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
        if (!(intent.parcelAction == null
                ? writesVerified
                : parcelWritesVerified) ||
            (intent.deliveryPaymentMethod == 'wallet' &&
                !prepaidDeliveryWritesVerified) ||
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
