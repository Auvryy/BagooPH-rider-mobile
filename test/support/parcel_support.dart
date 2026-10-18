import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/core/commands/parcel_proof.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';

Uint8List parcelTestPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfS8AAAAASUVORK5CYII=',
);

Map<String, dynamic> operationFixture(String name) =>
    jsonDecode(File('test/fixtures/operations/$name.json').readAsStringSync())
        as Map<String, dynamic>;

class ParcelTestJournal implements CommandJournal {
  CommandIntent? value;
  bool failWrite = false;
  bool failRead = false;
  final events = <String>[];
  @override
  Future<CommandIntent?> read() async {
    if (failRead) throw StateError('Protected storage unavailable');
    return value;
  }

  @override
  Future<void> write(CommandIntent intent) async {
    events.add('persist');
    if (failWrite) throw StateError('Protected storage unavailable');
    value = intent;
  }

  @override
  Future<void> clear() async {
    events.add('clear');
    value = null;
  }
}

class ParcelTestProofStore implements ParcelProofStore {
  final files = <String, ParcelProof>{};
  bool failSave = false, failRead = false, failDelete = false;
  @override
  Future<ParcelProofReference> save(String key, ParcelProof proof) async {
    if (failSave) throw StateError('Protected storage unavailable');
    files[key] = ParcelProof(proof.bytes, proof.extension);
    return ParcelProofReference(
      key: key,
      digest: proof.digest,
      extension: proof.extension,
    );
  }

  @override
  Future<ParcelProof> read(ParcelProofReference reference) async {
    if (failRead || !files.containsKey(reference.key)) {
      throw const AccountFailure(
        'Original proof unavailable',
        unconfirmed: true,
      );
    }
    final file = files[reference.key]!;
    if (file.digest != reference.digest) throw StateError('Changed original');
    return file;
  }

  @override
  Future<void> delete(ParcelProofReference reference) async {
    if (failDelete) throw StateError('Protected storage unavailable');
    files.remove(reference.key);
  }
}

typedef ParcelTestResponse = Future<Map<String, dynamic>> Function(
  String path,
  String method,
  Object? body,
  Map<String, String> headers,
);

class ParcelTestApi implements RiderSessionApi {
  late ParcelTestResponse respond;
  final calls =
      <
        ({
          String path,
          String method,
          Object? body,
          Map<String, String> headers,
        })
      >[];
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) {
    calls.add((path: path, method: method, body: data, headers: headers));
    return respond(path, method, data, headers);
  }
}

class ParcelHarness {
  ParcelHarness({this.action = ParcelAction.pickup, bool enabled = true}) {
    taskJson = operationFixture(
      action == ParcelAction.pickup ? 'pickup-task' : 'final-mile-task',
    )['data'];
    taskJson['actions'][action.name] = true;
    if (action == ParcelAction.deliver || action == ParcelAction.fail) {
      taskJson['operational_stage'] = 'out_for_delivery';
      taskJson['payment']['cod_due_cents'] = '12500';
      taskJson['payment']['method'] = 'cod';
    }
    if (action == ParcelAction.fail) {
      taskJson['failure_policy'] = {
        'attempt_limit': 3,
        'recorded_attempts': 1,
        'return_hub_id': '2',
        'retry_authority': 'destination_hub',
        'requires_notes': true,
        'requires_location': true,
        'requires_private_image': true,
        'reasons': [
          for (final code in failureReasonCodes)
            {'code': code, 'label': code.replaceAll('_', ' ')},
        ],
      };
    }
    api.respond = standardResponse;
    repository = restart(enabled: enabled);
  }
  final ParcelAction action;
  final api = ParcelTestApi();
  final journal = ParcelTestJournal();
  final proofs = ParcelTestProofStore();
  late Map<String, dynamic> taskJson;
  late OperationsRepository repository;
  bool current = true;
  OperationTask get task => OperationTask.fromJson(taskJson);
  ParcelProof get proof => ParcelProof(parcelTestPng(), 'png');
  Map<String, dynamic> get fields => switch (action) {
    ParcelAction.deliver => {
      'recipient_name': 'Software Test Recipient',
      'recipient_relationship': 'buyer',
      'cash_received': '200.00',
      'change_given': '75.00',
      'cash_confirmed': true,
    },
    ParcelAction.fail => {
      'reason': 'customer_unavailable',
      'notes': 'Software test recipient was unavailable at the agreed stop.',
      'location_name': 'Software test delivery stop',
    },
    _ => {'notes': 'Software test waybill review.'},
  };
  OperationsRepository restart({
    bool enabled = true,
    DateTime Function()? now,
    ParcelPhotoService? photos,
  }) => OperationsRepository(
    api,
    accountId: '5',
    journal: journal,
    writesVerified: true,
    parcelWritesVerified: enabled,
    proofStore: proofs,
    photos: photos,
    isCurrent: () => current,
    now: now ?? () => DateTime.utc(2026, 10, 18, 2),
  );
  Future<Map<String, dynamic>> submit() => repository.parcel(
    action,
    task,
    barcode: task.tracking,
    fields: fields,
    proof: action.requiresProof ? proof : null,
  );
  Future<Map<String, dynamic>> standardResponse(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (path == 'rider/home') {
      final home = operationFixture('home');
      home['data']['capabilities']['parcel_actions'] = true;
      return home;
    }
    if (path == 'rider/tasks/${task.id}') return {'data': taskJson};
    if (path.startsWith('rider/trips?')) {
      return {
        'data': {
          'items': <Object>[],
          'attribution': 'retained_assignment',
          'date_basis': 'assignment_recorded_at',
          'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'last_page': 1},
        },
      };
    }
    if (path.startsWith('rider/tasks?') ||
        path.startsWith('rider/pickup-jobs?')) {
      final phase = Uri.parse(path).queryParameters['phase'];
      final items = [
        if (phase == task.phase && task.stage != 'delivered') taskJson,
      ];
      return {
        'data': {
          'items': items,
          'pagination': {
            'page': 1,
            'per_page': 20,
            'total': items.length,
            'last_page': 1,
          },
        },
      };
    }
    if (path.startsWith('rider/commands/')) {
      throw const AccountFailure(
        'Unknown command',
        status: 404,
        code: 'COMMAND_UNKNOWN',
      );
    }
    return parcelCommand(journal.value!);
  }
}

Map<String, dynamic> parcelCommand(CommandIntent intent) => {
  'data': {
    'idempotency_key': intent.key,
    'action': intent.action,
    'resource': intent.resource,
    'state': 'committed',
    'result': {
      'task_id': intent.resource,
      'delivery_id': intent.deliveryId,
      'commercial_status': intent.action == 'deliver'
          ? 'delivered'
          : 'processing',
      'operational_stage': switch (intent.action) {
        'pickup' => 'picked_up',
        'depart' => 'out_for_delivery',
        'deliver' => 'delivered',
        'fail' => 'delivery_failed',
        _ => 'unknown',
      },
      'checkpoint_id': '9223372036854775807',
    },
    'recorded_at': '2026-10-18T02:00:00.000Z',
    'expires_at': '2026-10-25T02:00:00.000Z',
    'retry_expired': false,
    'replayed': false,
  },
};
