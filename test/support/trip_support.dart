import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/presentation/workspace_controller.dart';

import 'parcel_support.dart';

Map<String, dynamic> retainedTripJson({
  String id = '41',
  String delivery = '7',
  String phase = 'final_mile',
  String? recipient = 'Software Test Recipient',
  String? address = 'Recorded software-test stop',
  String? cents = '12500',
  String? outcome = 'delivered',
  bool withAttempt = false,
}) => jsonDecode(
  jsonEncode({
    'id': 'trip-$id',
    'assignment_reference': 'ASSIGN-SOFTWARE-$id',
    'delivery_id': delivery,
    'task_id': '$phase-$delivery',
    'phase': phase,
    'tracking_number': 'BGO-SOFTWARE-$delivery',
    'order_number': 'ORDER-SOFTWARE-$delivery',
    'outcome': outcome,
    'assignment_recorded_at': '2026-10-17T16:00:00.000Z',
    'last_recorded_at': '2026-10-18T02:00:00.000Z',
    'commercial_status': 'delivered',
    'current_operational_stage': 'delivered',
    'recipient': recipient,
    'address': address,
    'payment_method': 'cod',
    'collected_cents': cents,
    'earnings': {
      'available': true,
      'confirmed_cents': '0',
      'pending_cents': '2500',
      'basis': 'original_delivery_earnings_ledger',
    },
    'checkpoints': [
      {
        'id': id,
        'reference': 'ASSIGN-SOFTWARE-$id',
        'kind': phase == 'pickup' ? 'assigned_pickup' : 'assigned_to_rider',
        'recorded_at': '2026-10-17T16:00:00.000Z',
        'waybill_matched': false,
        'proof_url': null,
      },
      if (phase == 'final_mile')
        {
          'id': '42',
          'reference': 'DELIVER-SOFTWARE-42',
          'kind': 'delivered',
          'recorded_at': '2026-10-18T02:00:00.000Z',
          'waybill_matched': true,
          'proof_url': '/api/v1/rider/trips/trip-$id/checkpoints/42/proof',
        },
    ],
    'attempts': [
      if (withAttempt)
        {
          'id': '51',
          'reference': 'ATTEMPT-SOFTWARE-51',
          'number': 1,
          'reason': 'customer_unavailable',
          'recorded_at': '2026-10-18T01:00:00.000Z',
          'proof_url': '/api/v1/rider/trips/trip-$id/attempts/51/proof',
        },
    ],
  }),
) as Map<String, dynamic>;

Map<String, dynamic> retainedTripEnvelope(
  List<Map<String, dynamic>> rows, {
  int page = 1,
  int? total,
  int lastPage = 1,
}) => {
  'data': {
    'items': rows,
    'attribution': 'retained_assignment',
    'date_basis': 'assignment_recorded_at',
    'pagination': {
      'page': page,
      'per_page': 20,
      'total': total ?? rows.length,
      'last_page': lastPage,
    },
  },
};

class TripTestApi extends ParcelTestApi implements RiderEvidenceSessionApi {
  final downloads = <String>[];
  Future<PrivateApiBytes> Function(String)? onProof;
  @override
  Future<PrivateApiBytes> authenticatedEvidence(String path) async {
    downloads.add(path);
    return onProof == null
        ? PrivateApiBytes(parcelTestPng(), 'image/png')
        : onProof!(path);
  }
}

class TripHarness {
  TripHarness() {
    api.respond = (path, method, body, headers) async {
      if (path.startsWith('rider/trips?')) return retainedTripEnvelope(rows);
      if (path == 'rider/trips/${rows.first['id']}') {
        return {'data': rows.first};
      }
      final response = await domain.standardResponse(
        path,
        method,
        body,
        headers,
      );
      if (path == 'rider/home') {
        response['data']['capabilities']['trips'] = true;
      }
      return response;
    };
    repository = OperationsRepository(
      api,
      accountId: '5',
      journal: domain.journal,
      writesVerified: true,
      isCurrent: () => domain.current,
    );
    work = WorkspaceController(repository);
  }
  final domain = ParcelHarness();
  final api = TripTestApi();
  List<Map<String, dynamic>> rows = [retainedTripJson()];
  late final OperationsRepository repository;
  late final WorkspaceController work;
  bool _disposed = false;
  Future<void> boot() => Future<void>.delayed(Duration.zero);
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    work.dispose();
  }

  Uint8List get png => parcelTestPng();
}
