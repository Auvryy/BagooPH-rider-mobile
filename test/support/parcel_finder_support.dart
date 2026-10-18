import 'dart:async';
import 'dart:convert';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/parcel_finder/data/parcel_location_labels.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';

import '../operations_contract_test.dart' as ops;

Map<String, dynamic> finderClone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

Map<String, dynamic> finderTaskJson({
  String id = '31',
  String phase = 'pickup',
  String? stage,
  String assignment = 'CHK-TEST-41',
  String? tracking,
}) {
  final data =
      ops.fixture(phase == 'pickup' ? 'pickup-task' : 'final-mile-task')['data']
          as Map<String, dynamic>;
  data['id'] = '$phase-$id';
  data['delivery_id'] = id;
  data['assignment_reference'] = assignment;
  data['tracking_number'] = tracking ?? 'BGO-TEST${id.padLeft(8, '0')}';
  data['order_number'] = 'ORDER-TEST$id';
  data['stop']['name'] = 'Software test stop';
  data['stop']['address'] = 'Software test address';
  if (stage != null) data['operational_stage'] = stage;
  return data;
}

class ParcelFinderHarness {
  ParcelFinderHarness({List<Map<String, dynamic>>? tasks})
    : rows = tasks ?? [finderTaskJson()] {
    api.respond = respond;
    repository = OperationsRepository(
      api,
      accountId: accountId,
      journal: journal,
      writesVerified: false,
      isCurrent: () => authorized,
    );
    labels = ParcelLocationLabels(
      apiOrigin: Uri.parse(origin),
      accountId: accountId,
    );
    work = WorkspaceController(repository, parcelLocations: labels);
  }
  static const origin = 'https://rider.example.test/api/v1';
  final api = ops.Session();
  final journal = ops.Journal();
  final List<Map<String, dynamic>> rows;
  late final OperationsRepository repository;
  late final ParcelLocationLabels labels;
  late final WorkspaceController work;
  String accountId = '5';
  bool authorized = true;
  int? totalOverride;
  int details = 0;
  AccountFailure? detailFailure;
  Completer<Map<String, dynamic>>? detailGate;

  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (method != 'GET') {
      throw StateError('Parcel Finder must not mutate the server.');
    }
    if (path == 'rider/home') {
      final home = ops.fixture('home');
      home['data']['account_id'] = accountId;
      home['data']['counts'] = {
        'available': 0,
        'pickup': rows.where((r) => r['phase'] == 'pickup').length,
        'final_mile': rows.where((r) => r['phase'] == 'final_mile').length,
      };
      home['data']['capabilities']['messages'] = false;
      home['data']['limits']['poll_interval_seconds'] = 3600;
      return home;
    }
    if (path.startsWith('rider/tasks/')) {
      details++;
      final gate = detailGate;
      detailGate = null;
      if (gate != null) return gate.future;
      if (detailFailure != null) throw detailFailure!;
      final id = path.split('/').last;
      final row = rows.where((row) => row['id'] == id).firstOrNull;
      if (row == null) {
        throw const AccountFailure('Task no longer available.', status: 404);
      }
      return {'data': finderClone(row)};
    }
    if (path.startsWith('rider/trips?')) {
      return {
        'data': {
          'items': [],
          'attribution': 'retained_assignment',
          'date_basis': 'assignment_recorded_at',
          'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'last_page': 1},
        },
      };
    }
    if (path.startsWith('rider/tasks?') ||
        path.startsWith('rider/pickup-jobs?')) {
      final query = Uri.parse(path).queryParameters;
      final items = rows
          .where((row) => row['phase'] == query['phase'])
          .map(finderClone)
          .toList();
      final total = totalOverride ?? items.length;
      return {
        'data': {
          'items': items,
          'pagination': {
            'page': int.parse(query['page'] ?? '1'),
            'per_page': 20,
            'total': total,
            'last_page': total > 20 ? 2 : 1,
          },
        },
      };
    }
    throw StateError('Unexpected test request $path');
  }

  Future<void> boot() async {
    await Future<void>.delayed(Duration.zero);
  }

  OperationTask task([int index = 0]) =>
      OperationTask.fromJson(finderClone(rows[index]));
  Future<void> open([int index = 0]) =>
      work.openTask(OperationsRepository.asRiderTask(task(index)));
  Future<String?> set(ParcelSlot? slot, {bool Function()? mayApply}) =>
      work.setParcelLocation(
        work.selectedTask!,
        slot,
        mayApply: mayApply ?? () => true,
      );
  void dispose() => work.dispose();
}
