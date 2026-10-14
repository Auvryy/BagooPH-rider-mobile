import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/handover_support.dart';

void main() {
  test('native microsecond clocks serialize to the accepted millisecond journal timestamp', () {
    final original = HandoverIntent(
      accountId: '5',
      key: '00000000-0000-4000-8000-000000000001',
      action: 'handover.report',
      resource: 'handover-report',
      body: {
        'barcode': 'BGO-TEST',
        'kind': 'missed_scan',
        'reported_holder': 'Known rider',
        'reported_location': 'Assigned hub',
        'notes': 'Actual observed missed scan',
      },
      createdAt: handoverNow.add(const Duration(microseconds: 123456)),
      file: evidenceFile,
    );
    final restored = HandoverIntent.fromJson(original.toJson());
    expect(original.toJson()['created_at'], '2026-10-14T09:00:00.123Z');
    expect(
      restored.createdAt.millisecondsSinceEpoch,
      original.createdAt.millisecondsSinceEpoch,
    );
    expect(restored.file!.digest, original.file!.digest);
  });
  test('exercised report, pickup and manifest detail retain exact IDs and distinct versions', () {
    final j = handoverFixture('detail-pickup')['data'] as Map<String, dynamic>;
    j['id'] = '9223372036854775807';
    j['evidence']['download_path'] =
        '/api/v1/rider/handover-issues/9223372036854775807/evidence';
    j['recovery']['id'] = '9007199254740993';
    j['recovery']['receiving_hub']['id'] = '9223372036854775807';
    j['recovery']['expected_version'] = 1000000;
    final d = HandoverDetail.fromJson(j);
    expect(d.id, '9223372036854775807');
    expect(d.recovery!.id, '9007199254740993');
    expect(d.recovery!.version, 1000000);
    expect(d.recovery!.sourceToken, j['recovery']['source_token']);
    expect(d.reportedHolder, isNot(d.current.custodyLabel));
    expect(
      HandoverDetail.fromJson(handoverFixture('detail')['data']).recovery,
      isNull,
    );
    expect(
      HandoverDetail.fromJson(handoverFixture('detail-manifest')['data'])
          .recovery!
          .manifestReference,
      isNotNull,
    );
    for (final bad in [0, 1000001, 1.0, '1', true, null]) {
      expect(() => handoverVersion(bad), throwsFormatException);
    }
  });
  test('discovery distinguishes schema readiness from the actual reporting permission', () {
    final session = HandoverSession(),
        repo = testHandoverRepository(
          HandoverSession(),
          MemoryHandoverJournal(),
        );
    final h = OperationsHome.fromJson(session.home['data']);
    expect(h.handoverApiVersion, 1);
    expect(repo.canWrite(h), true);
    session.home['data']['capabilities']['handover_reporting'] = false;
    final readOnly = OperationsHome.fromJson(session.home['data']);
    expect(repo.canRead(readOnly), true);
    expect(repo.canWrite(readOnly), false);
    expect(
      testHandoverRepository(
        session,
        MemoryHandoverJournal(),
        sessionVersion: null,
      ).canWrite(h),
      false,
    );
    expect(
      testHandoverRepository(
        session,
        MemoryHandoverJournal(),
        writes: false,
      ).canWrite(h),
      false,
    );
    session.home['data']['handover_api_version'] = '1';
    expect(
      OperationsHome.fromJson(session.home['data']).handoverApiVersion,
      isNull,
    );
    final account = {
      'id': '5',
      'role': 'courier',
      'name': 'Example Rider',
      'email': 'rider@example.test',
      'status': 'active',
      'kyc_status': 'approved',
      'can_access_portal': true,
      'email_verified': true,
      'access_state': 'approved',
      'handover_api_version': 1,
    };
    expect(RiderAccount.fromJson(account).handoverApiVersion, 1);
    account['handover_api_version'] = 2;
    expect(RiderAccount.fromJson(account).handoverApiVersion, isNull);
  });
  test('pagination and private evidence paths reject unsafe wire data', () {
    final rows = handoverFixture('issues')['data'];
    expect(HandoverPage.fromJson(rows).items.single.id, '1');
    for (final bad in [0, 10001]) {
      final j = handoverFixture('issues')['data'];
      j['pagination']['page'] = bad;
      expect(() => HandoverPage.fromJson(j), throwsFormatException);
    }
    for (final path in [
      'https://foreign.test/file',
      '//foreign.test/file',
      '/storage/proof.png',
      '/api/v1/rider/handover-issues/2/evidence',
    ]) {
      final j = handoverFixture('detail')['data'];
      j['evidence']['download_path'] = path;
      expect(() => HandoverDetail.fromJson(j), throwsFormatException);
    }
    final j = handoverFixture('detail-pickup')['data'];
    j['recovery']['holder_is_me'] = false;
    expect(() => HandoverDetail.fromJson(j), throwsFormatException);
  });
  test(
    'original file is immutable, bounded and hash-verified after restart',
    () {
      final original = pngEvidence, file = HandoverFile(original, 'png');
      original[0] = 0;
      expect(file.bytes.first, 137);
      expect(() => file.bytes[0] = 0, throwsUnsupportedError);
      final restored = HandoverFile.fromJson(file.toJson());
      expect(restored.bytes, file.bytes);
      expect(restored.digest, file.digest);
      final damaged = file.toJson();
      damaged['sha256'] = '0' * 64;
      expect(() => HandoverFile.fromJson(damaged), throwsFormatException);
      for (final ext in ['exe', 'pdf', 'jpeg']) {
        expect(
          () => HandoverFile(pngEvidence, ext),
          throwsA(isA<AccountFailure>()),
        );
      }
      expect(
        () => HandoverFile(Uint8List(0), 'png'),
        throwsA(isA<AccountFailure>()),
      );
      expect(
        () => HandoverFile(Uint8List(evidenceLimit + 1), 'png'),
        throwsA(isA<AccountFailure>()),
      );
      final boundary = Uint8List(evidenceLimit)
        ..setRange(0, pngEvidence.length, pngEvidence);
      expect(HandoverFile(boundary, 'png').bytes.length, evidenceLimit);
      expect(
        handoverText('First line\nSecond line', 'notes', 10, 1000),
        'First line\nSecond line',
      );
    },
  );
  test('multipart report persists one intent before dispatch and sends exact original bytes', () async {
    final api = HandoverSession(),
        journal = MemoryHandoverJournal(),
        repo = testHandoverRepository(api, journal);
    api.handler = (path, method, data, headers) async {
      if (path == 'rider/home') return api.home;
      final intent = (await journal.read())!;
      expect(headers['Idempotency-Key'], intent.key);
      expect(headers['X-Request-ID'], isNot(intent.key));
      expect(data, isA<FormData>());
      final form = data as FormData;
      expect(Map.fromEntries(form.fields), {
        'barcode': 'BGO-TEST-1',
        'kind': 'missed_scan',
        'reported_holder': 'Known rider',
        'reported_location': 'Assigned hub desk',
        'notes': 'Observed an actual omitted scan.',
      });
      final upload = form.files.single.value;
      expect(upload.filename, 'handover-evidence.png');
      expect(upload.contentType.toString(), 'image/png');
      expect(await upload.finalize().expand((v) => v).toList(), pngEvidence);
      return handoverCommand(intent);
    };
    final result = await repo.report(
      barcode: ' bgo-test-1 ',
      holder: 'Known rider',
      location: 'Assigned hub desk',
      notes: 'Observed an actual omitted scan.',
      file: evidenceFile,
    );
    expect(result['state'], 'pending_review');
    expect(result['held'], false);
    expect(await repo.pending(), isNull);
    expect(api.calls.where((c) => c.method == 'POST').length, 1);
  });
  test('storage failure or missing permission prevents a write', () async {
    for (final storageFails in [false, true]) {
      final api = HandoverSession(),
          journal = MemoryHandoverJournal()..failWrite = storageFails;
      if (!storageFails) {
        api.home['data']['capabilities']['handover_reporting'] = false;
      }
      final repo = testHandoverRepository(api, journal);
      await expectLater(
        repo.report(
          barcode: 'BGO-TEST',
          holder: 'Known rider',
          location: 'Assigned hub',
          notes: 'Actual observed missed scan',
          file: evidenceFile,
        ),
        throwsA(anything),
      );
      expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
    }
  });
  test('lost report response survives restart; unknown cannot replace the key or evidence', () async {
    final api = HandoverSession(),
        journal = MemoryHandoverJournal(),
        repo = testHandoverRepository(api, journal);
    api.handler = (path, method, data, headers) async {
      if (path == 'rider/home') return api.home;
      throw const AccountFailure('Synthetic timeout', unconfirmed: true);
    };
    await expectLater(
      repo.report(
        barcode: 'BGO-TEST',
        holder: 'Known rider',
        location: 'Assigned hub',
        notes: 'Actual observed missed scan',
        file: evidenceFile,
      ),
      throwsA(isA<AccountFailure>()),
    );
    final saved = (await journal.read())!;
    final restarted = testHandoverRepository(api, journal);
    api.handler = (path, method, data, headers) async {
      if (path == 'rider/home') return api.home;
      if (path.startsWith('rider/commands/')) {
        throw const AccountFailure(
          'Unconfirmed',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      expect(headers['Idempotency-Key'], saved.key);
      expect((await journal.read())!.file!.digest, saved.file!.digest);
      expect(
        await (data as FormData).files.single.value
            .finalize()
            .expand((v) => v)
            .toList(),
        saved.file!.bytes,
      );
      return handoverCommand(saved, replayed: true);
    };
    expect(await restarted.reconcile(), isNull);
    expect(await restarted.pending(), isNotNull);
    final posts = api.calls.where((c) => c.method == 'POST').length;
    await expectLater(
      restarted.report(
        barcode: 'OTHER',
        holder: 'Other rider',
        location: 'Other location',
        notes: 'Replacement is forbidden',
        file: evidenceFile,
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(api.calls.where((c) => c.method == 'POST').length, posts);
    await restarted.reconcile(retryUnknown: true);
    expect(await restarted.pending(), isNull);
    expect(
      api.calls
          .where((c) => c.method == 'POST')
          .map((c) => c.headers['Idempotency-Key'])
          .toSet(),
      {saved.key},
    );
  });
  test('acknowledgement uses freshly reviewed integer version and explicit boolean possession', () async {
    final api = HandoverSession(),
        journal = MemoryHandoverJournal(),
        repo = testHandoverRepository(api, journal);
    final reviewed = HandoverDetail.fromJson(api.detailBody['data']);
    api.handler = (path, method, data, headers) async {
      if (path == 'rider/home') return api.home;
      if (method == 'GET') return api.detailBody;
      expect(path, 'rider/handover-recoveries/1/acknowledge');
      final body = data as Map<String, dynamic>;
      expect(body['expected_version'], 4);
      expect(body['expected_version'], isA<int>());
      expect(body['source_token'], reviewed.recovery!.sourceToken);
      expect(body['possession_verified'], same(true));
      expect(body.keys.toSet(), {
        'expected_version',
        'source_token',
        'barcode',
        'notes',
        'possession_verified',
      });
      return handoverCommand((await journal.read())!);
    };
    final result = await repo.acknowledge(
      reviewed,
      barcode: reviewed.tracking,
      notes: 'I physically hold this actual parcel.',
      possessionVerified: true,
    );
    expect(result['held'], true);
    expect(result['state'], 'needs_recovery');
    expect(result['event_type'], 'holder_acknowledged');
  });
  for (final changed in [
    'source',
    'version',
    'expired',
    'foreign',
    'not-confirmed',
    'wrong-barcode',
  ]) {
    test('acknowledgement blocks $changed before dispatch', () async {
      final api = HandoverSession(),
          journal = MemoryHandoverJournal(),
          repo = testHandoverRepository(api, journal);
      final reviewed = HandoverDetail.fromJson(api.detailBody['data']);
      final grant = api.detailBody['data']['recovery'];
      if (changed == 'source') grant['source_token'] = '0' * 64;
      if (changed == 'version') grant['expected_version'] = 5;
      if (changed == 'expired') {
        grant['expires_at'] = '2026-10-14T08:00:00.000Z';
      }
      if (changed == 'foreign') {
        grant['holder_is_me'] = false;
        grant['source_token'] = null;
        grant['actions']['acknowledge'] = false;
      }
      await expectLater(
        repo.acknowledge(
          reviewed,
          barcode: changed == 'wrong-barcode' ? 'OTHER' : reviewed.tracking,
          notes: 'I physically hold this actual parcel.',
          possessionVerified: changed != 'not-confirmed',
        ),
        throwsA(anything),
      );
      expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(await journal.read(), isNull);
    });
  }
  for (final error in [
    const AccountFailure(
      'Rejected field',
      status: 422,
      fields: {'notes': 'Explain the event.'},
    ),
    const AccountFailure(
      'Intent conflict',
      status: 409,
      code: 'IDEMPOTENCY_CONFLICT',
    ),
    const AccountFailure('Expired', status: 409, code: 'COMMAND_EXPIRED'),
    const AccountFailure('Wait', status: 429, retryAfterSeconds: 30),
    const AccountFailure('Lost session', status: 401),
    const AccountFailure('Unavailable', status: 503, unconfirmed: true),
  ]) {
    test(
      'command failure ${error.status}/${error.code} preserves the correct pending state',
      () async {
        final api = HandoverSession(),
            journal = MemoryHandoverJournal(),
            repo = testHandoverRepository(api, journal);
        api.handler = (path, method, data, headers) async {
          if (path == 'rider/home') return api.home;
          throw error;
        };
        await expectLater(
          repo.report(
            barcode: 'BGO-TEST',
            holder: 'Known rider',
            location: 'Assigned hub',
            notes: 'Actual observed missed scan',
            file: evidenceFile,
          ),
          throwsA(same(error)),
        );
        expect(await journal.read(), error.status == 422 ? isNull : isNotNull);
      },
    );
  }
  test('expired unknown intent is retained without a new POST; retained committed GET still resolves it', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    final intent = HandoverIntent(
      accountId: '5',
      key: '00000000-0000-4000-8000-000000000001',
      action: 'handover.report',
      resource: 'handover-report',
      body: {
        'barcode': 'BGO-TEST',
        'kind': 'missed_scan',
        'reported_holder': 'Known rider',
        'reported_location': 'Assigned hub',
        'notes': 'Actual observed missed scan',
      },
      createdAt: handoverNow.subtract(const Duration(days: 8)),
      file: evidenceFile,
    );
    await journal.write(intent);
    final repo = testHandoverRepository(api, journal);
    api.handler = (path, method, data, headers) async {
      throw const AccountFailure(
        'Unknown',
        status: 404,
        code: 'COMMAND_UNKNOWN',
      );
    };
    await expectLater(
      repo.reconcile(retryUnknown: true),
      throwsA(
        isA<AccountFailure>().having((e) => e.code, 'code', 'COMMAND_EXPIRED'),
      ),
    );
    expect(await journal.read(), isNotNull);
    expect(api.calls.any((c) => c.method == 'POST'), false);
    api.handler = (path, method, data, headers) async {
      final response = handoverCommand(intent, replayed: true);
      response['data']['retry_expired'] = true;
      return response;
    };
    await repo.reconcile();
    expect(await journal.read(), isNull);
  });
  test('late account loss cannot expose downloaded bytes or dispatch a preflight write', () async {
    final api = HandoverSession(), journal = MemoryHandoverJournal();
    var current = true;
    final repo = testHandoverRepository(api, journal, isCurrent: () => current);
    final wait = Completer<Map<String, dynamic>>();
    api.handler = (path, method, data, headers) => wait.future;
    final pending = repo.report(
      barcode: 'BGO-TEST',
      holder: 'Known rider',
      location: 'Assigned hub',
      notes: 'Actual observed missed scan',
      file: evidenceFile,
    );
    await Future<void>.delayed(Duration.zero);
    current = false;
    wait.complete(api.home);
    await expectLater(pending, throwsA(isA<AccountFailure>()));
    expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
  });
  test('private evidence uses a fresh involved detail and one origin-relative authenticated path', () async {
    final api = HandoverSession(),
        journal = MemoryHandoverJournal(),
        repo = testHandoverRepository(api, journal);
    final detail = HandoverDetail.fromJson(api.detailBody['data']);
    final document = await repo.evidence(detail);
    expect(document.bytes, pngEvidence);
    expect(api.calls.single.path, 'rider/handover-issues/1');
    expect(api.downloads, ['rider/handover-issues/1/evidence']);
    api.downloadHandler = (_) async => throw const AccountFailure(
      'Evidence altered',
      status: 409,
      code: 'EVIDENCE_CHANGED',
    );
    await expectLater(repo.evidence(detail), throwsA(isA<AccountFailure>()));
    api.downloadHandler = (_) async =>
        PrivateApiBytes(Uint8List.fromList(utf8.encode('<html>')), 'image/png');
    await expectLater(repo.evidence(detail), throwsA(isA<AccountFailure>()));
  });
}
