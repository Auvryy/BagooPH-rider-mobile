import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';

import '../operations_contract_test.dart' as operations;

Map<String, dynamic> handoverFixture(String name) =>
    jsonDecode(File('test/fixtures/handover/$name.json').readAsStringSync())
        as Map<String, dynamic>;
final handoverNow = DateTime.utc(2026, 10, 14, 9);
Uint8List get pngEvidence => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfS8AAAAASUVORK5CYII=',
);
HandoverFile get evidenceFile => HandoverFile(pngEvidence, 'png');

class MemoryHandoverJournal implements HandoverJournal {
  String? encoded;
  bool failWrite = false, failRead = false;
  @override
  Future<HandoverIntent?> read() async {
    if (failRead) throw StateError('synthetic storage failure');
    return encoded == null
        ? null
        : HandoverIntent.fromJson(Wire.object(jsonDecode(encoded!)));
  }

  @override
  Future<void> write(HandoverIntent value) async {
    if (failWrite) throw StateError('synthetic storage failure');
    encoded = jsonEncode(value.toJson());
  }

  @override
  Future<void> clear() async {
    encoded = null;
  }
}

class HandoverSession implements RiderSessionApi, RiderEvidenceSessionApi {
  final calls =
      <
        ({
          String path,
          String method,
          Object? data,
          Map<String, String> headers,
        })
      >[];
  final downloads = <String>[];
  final home = operations.fixture('home');
  Map<String, dynamic> detailBody = handoverFixture('detail-pickup');
  Map<String, dynamic> listBody = handoverFixture('issues');
  Future<Map<String, dynamic>> Function(
    String,
    String,
    Object?,
    Map<String, String>,
  )?
  handler;
  Future<PrivateApiBytes> Function(String)? downloadHandler;
  HandoverSession() {
    home['data']['handover_api_version'] = 1;
    home['data']['capabilities']['handover_issues'] = true;
    home['data']['capabilities']['handover_reporting'] = true;
  }
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) async {
    calls.add((path: path, method: method, data: data, headers: headers));
    if (handler != null) return handler!(path, method, data, headers);
    return reply(path);
  }

  Future<Map<String, dynamic>> reply(String path) async {
    if (path == 'rider/home') return home;
    if (path.startsWith('rider/handover-issues?')) return listBody;
    if (path.startsWith('rider/handover-issues/')) return detailBody;
    throw StateError('Unexpected synthetic request');
  }

  @override
  Future<PrivateApiBytes> authenticatedEvidence(String path) async {
    downloads.add(path);
    return downloadHandler?.call(path) ??
        PrivateApiBytes(pngEvidence, 'image/png');
  }
}

HandoverRepository testHandoverRepository(
  HandoverSession api,
  MemoryHandoverJournal journal, {
  bool writes = true,
  int? sessionVersion = 1,
  bool Function()? isCurrent,
  DateTime Function()? now,
}) => HandoverRepository(
  api,
  accountId: '5',
  journal: journal,
  writesVerified: writes,
  sessionVersion: sessionVersion,
  isCurrent: isCurrent ?? () => true,
  now: now ?? () => handoverNow,
);

Map<String, dynamic> handoverCommand(
  HandoverIntent intent, {
  bool replayed = false,
}) {
  final response = handoverFixture(
    intent.action == 'handover.report' ? 'report' : 'acknowledgement',
  );
  response['data']['idempotency_key'] = intent.key;
  response['data']['action'] = intent.action;
  response['data']['resource'] = intent.resource;
  response['data']['replayed'] = replayed;
  if (intent.issueId != null) {
    response['data']['result']['issue_id'] = intent.issueId;
  }
  return response;
}
