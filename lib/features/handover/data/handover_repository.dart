import 'package:dio/dio.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart' show commandUuid;
import '../../home/data/operations_models.dart';
import 'handover_intent.dart';
import 'handover_models.dart';

class HandoverRepository {
  HandoverRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.isCurrent,
    required this.writesVerified,
    required this.sessionVersion,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RiderSessionApi api;
  final String accountId;
  final HandoverJournal journal;
  final bool Function() isCurrent;
  final bool writesVerified;
  final int? sessionVersion;
  final DateTime Function() now;
  bool _writing = false;

  void guard() {
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
    guard();
    final response = await api.authenticatedRequest(
      path,
      method: method,
      data: data,
      headers: headers,
    );
    guard();
    return Wire.object(response['data']);
  }

  Future<OperationsHome> home() async {
    final h = OperationsHome.fromJson(await _request('rider/home'));
    if (h.accountId != accountId) Wire.invalid();
    return h;
  }

  bool canRead(OperationsHome h) =>
      h.handoverApiVersion == 1 && h.capabilities['handover_issues'] == true;
  bool canWrite(OperationsHome h) =>
      canRead(h) &&
      writesVerified &&
      sessionVersion == 1 &&
      h.capabilities['handover_reporting'] == true;
  Future<HandoverPage> list({String status = 'open', int page = 1}) async {
    if (!['open', 'recovered', 'dismissed', 'all'].contains(status) ||
        page < 1 ||
        page > 10000) {
      Wire.invalid();
    }
    final rows = HandoverPage.fromJson(
      await _request(
        'rider/handover-issues?status=$status&page=$page&per_page=20',
      ),
    );
    if (rows.page != page) Wire.invalid();
    return rows;
  }

  Future<HandoverDetail> detail(String id) async {
    Wire.id(id);
    final d = HandoverDetail.fromJson(
      await _request('rider/handover-issues/$id'),
    );
    if (d.id != id) Wire.invalid();
    return d;
  }

  Future<PrivateApiBytes> evidence(HandoverDetail selected) async {
    final fresh = await detail(selected.id);
    guard();
    if (api is! RiderEvidenceSessionApi) {
      throw const AccountFailure('Private evidence viewing is unavailable.');
    }
    // Detail validates the exact absolute path. Strip only the known API prefix;
    // the authenticated client resolves against its configured /api/v1 origin.
    final result = await (api as RiderEvidenceSessionApi).authenticatedEvidence(
      fresh.evidencePath.substring('/api/v1/'.length),
    );
    guard();
    if (result.mimeType != fresh.mime ||
        !evidenceMatches(result.bytes, fresh.mime)) {
      throw const AccountFailure(
        'The private evidence document could not be verified.',
      );
    }
    return result;
  }

  Future<HandoverIntent?> pending() async {
    guard();
    final value = await journal.read();
    guard();
    if (value != null && value.accountId != accountId) Wire.invalid();
    return value;
  }

  Future<Map<String, dynamic>> report({
    required String barcode,
    required String holder,
    required String location,
    required String notes,
    required HandoverFile file,
  }) => _newIntent('handover.report', 'handover-report', {
    'barcode': handoverBarcode(barcode),
    'kind': 'missed_scan',
    'reported_holder': handoverText(holder, 'reported_holder', 2, 100),
    'reported_location': handoverText(location, 'reported_location', 5, 255),
    'notes': handoverText(notes, 'notes', 10, 1000),
  }, file: file);

  Future<Map<String, dynamic>> acknowledge(
    HandoverDetail reviewed, {
    required String barcode,
    required String notes,
    required bool possessionVerified,
  }) async {
    if (!possessionVerified) {
      throw const AccountFailure(
        'Confirm that you physically hold this parcel.',
        fields: {'possession_verified': 'Actual possession must be confirmed.'},
      );
    }
    final code = handoverBarcode(barcode);
    if (code != handoverBarcode(reviewed.tracking)) {
      throw const AccountFailure(
        'The waybill does not match this parcel.',
        fields: {'barcode': 'Enter this parcel’s actual matching waybill.'},
      );
    }
    final text = handoverText(notes, 'notes', 10, 1000);
    final fresh = await detail(reviewed.id),
        old = reviewed.recovery,
        grant = fresh.recovery;
    if (old == null ||
        grant == null ||
        !old.sameAuthority(grant) ||
        fresh.tracking != reviewed.tracking ||
        !grant.canAcknowledge(now())) {
      throw const AccountFailure(
        'The recovery changed or is unavailable. Refresh and review it before acknowledging.',
        status: 409,
        code: 'STALE_HANDOVER',
      );
    }
    return _newIntent('handover.acknowledge', 'handover-recovery-${grant.id}', {
      'expected_version': grant.version,
      'source_token': grant.sourceToken,
      'barcode': code,
      'notes': text,
      'possession_verified': true,
    }, issueId: fresh.id);
  }

  Future<Map<String, dynamic>> _newIntent(
    String action,
    String resource,
    Map<String, dynamic> body, {
    String? issueId,
    HandoverFile? file,
  }) async {
    if (_writing) {
      throw const AccountFailure(
        'A handover request is already being checked.',
      );
    }
    _writing = true;
    try {
      guard();
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the saved handover request before starting another.',
        );
      }
      final h = await home();
      if (!canWrite(h)) {
        throw const AccountFailure(
          'Handover writes need a verified deployment and a fresh permitted sign-in.',
        );
      }
      final intent = HandoverIntent(
        accountId: accountId,
        key: commandUuid(),
        action: action,
        resource: resource,
        body: body,
        createdAt: now().toUtc(),
        issueId: issueId,
        file: file,
      );
      await journal.write(intent);
      guard();
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }

  Future<Map<String, dynamic>> _commit(
    HandoverIntent intent,
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
    Wire.id(value['issue_id']);
    Wire.string(value['reference']);
    handoverVersion(value['version']);
    Wire.boolean(value['held']);
    if (![
      'pending_review',
      'needs_recovery',
      'dismissed',
      'recovered',
    ].contains(value['state'])) {
      Wire.invalid();
    }
    if (intent.action == 'handover.acknowledge') {
      if (value['issue_id'] != intent.issueId ||
          Wire.id(value['grant_id']) !=
              intent.resource.substring('handover-recovery-'.length) ||
          value['event_type'] != 'holder_acknowledged') {
        Wire.invalid();
      }
      Wire.id(value['event_id']);
    }
    guard();
    await journal.clear();
    guard();
    return value;
  }

  Future<Map<String, dynamic>> _dispatch(HandoverIntent intent) async {
    Object data = intent.body;
    if (intent.file != null) {
      data = FormData.fromMap(intent.body);
      (data as FormData).files.add(
        MapEntry(
          'evidence',
          MultipartFile.fromBytes(
            intent.file!.bytes,
            filename: intent.file!.filename,
            contentType: DioMediaType.parse(intent.file!.mime),
          ),
        ),
      );
    }
    try {
      return await _commit(
        intent,
        await _request(
          intent.path,
          method: 'POST',
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
        guard();
        await journal.clear();
      }
      rethrow;
    } catch (_) {
      throw const AccountFailure(
        'The handover result is uncertain. Check the saved request.',
        unconfirmed: true,
      );
    }
  }

  Future<Map<String, dynamic>?> reconcile({bool retryUnknown = false}) async {
    if (_writing) {
      throw const AccountFailure(
        'A handover request is already being checked.',
      );
    }
    _writing = true;
    try {
      final intent = await pending();
      if (intent == null) return null;
      try {
        return await _commit(
          intent,
          await _request('rider/commands/${intent.key}'),
        );
      } on AccountFailure catch (error) {
        if (error.status != 404 || error.code != 'COMMAND_UNKNOWN') rethrow;
        if (!retryUnknown) return null;
        if (now().toUtc().difference(intent.createdAt) >=
            const Duration(days: 7)) {
          throw const AccountFailure(
            'The original request’s retry window has closed. Keep it for reconciliation.',
            code: 'COMMAND_EXPIRED',
          );
        }
        if (!canWrite(await home())) {
          throw const AccountFailure(
            'Sign in with current handover permission before retrying.',
          );
        }
        return await _dispatch(intent);
      }
    } finally {
      _writing = false;
    }
  }
}
