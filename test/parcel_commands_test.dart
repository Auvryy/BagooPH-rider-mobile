import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

void main() {
  test(
    'parcel activation is separate from accepted duty and pickup claims',
    () async {
      const config = AppConfig(
        'https://example.test/api/v1',
        operationsWritesVerified: true,
      );
      expect(config.parcelWritesVerified, isFalse);
      final h = ParcelHarness(enabled: false);
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      expect(h.api.calls, isEmpty);
      expect(h.journal.value, isNull);
    },
  );

  for (final action in ParcelAction.values) {
    test(
      '${action.name} is persisted before dispatch and verifies its result',
      () async {
        final h = ParcelHarness(action: action);
        h.api.respond = (path, method, body, headers) async {
          if (method == 'POST') {
            final original = h.journal.value!;
            expect(h.journal.events, ['persist']);
            expect(headers['Idempotency-Key'], original.key);
            expect(headers['X-Request-ID'], isNot(original.key));
            expect(path, 'rider/tasks/${h.task.id}/${action.name}');
            if (action.requiresProof) {
              expect(h.proofs.files[original.key]!.digest, h.proof.digest);
              expect(body, isA<FormData>());
              final data = body as FormData;
              expect(Map.fromEntries(data.fields)['barcode'], h.task.tracking);
              expect(data.files.single.key, 'proof_image_file');
              expect(
                data.files.single.value.contentType.toString(),
                'image/png',
              );
              expect(
                await data.files.single.value
                    .finalize()
                    .expand((v) => v)
                    .toList(),
                h.proof.bytes,
              );
              if (action == ParcelAction.deliver) {
                expect(Map.fromEntries(data.fields)['cash_confirmed'], '1');
                expect(Map.fromEntries(data.fields)['cash_received'], '200.00');
              }
            } else {
              expect(body, original.body);
            }
          }
          return h.standardResponse(path, method, body, headers);
        };
        final result = await h.submit();
        expect(result['checkpoint_id'], '9223372036854775807');
        expect(h.journal.value, isNull);
        expect(h.proofs.files, isEmpty);
      },
    );
  }

  test('timeout/restart checks unknown then retries the exact key body and original proof', () async {
    final h = ParcelHarness(action: ParcelAction.deliver);
    final keys = <String>[];
    final files = <List<int>>[];
    var first = true;
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        keys.add(headers['Idempotency-Key']!);
        final data = body as FormData;
        files.add(
          await data.files.single.value.finalize().expand((v) => v).toList(),
        );
        expect(
          Map.fromEntries(data.fields)['recipient_name'],
          h.fields['recipient_name'],
        );
        if (first) {
          first = false;
          throw const AccountFailure('Interrupted upload', unconfirmed: true);
        }
      }
      return h.standardResponse(path, method, body, headers);
    };
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    h.journal.value = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    final restarted = h.restart();
    expect(await restarted.reconcile(), isNull);
    expect(h.journal.value!.key, original.key);
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    await restarted.reconcile(retryUnknown: true);
    expect(keys, [original.key, original.key]);
    expect(files, [h.proof.bytes.toList(), h.proof.bytes.toList()]);
    expect(h.journal.value, isNull);
    expect(h.proofs.files, isEmpty);
  });

  test('a committed retained result reconciles without reading missing local proof', () async {
    final h = ParcelHarness(action: ParcelAction.deliver);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Lost response', unconfirmed: true);
      }
      return h.standardResponse(path, method, body, headers);
    };
    await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    h.proofs.files.clear();
    h.api.respond = (path, method, body, headers) async =>
        parcelCommand(original);
    await h.restart().reconcile();
    expect(h.journal.value, isNull);
    expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
  });

  test(
    'unknown command with missing original proof cannot recapture or dispatch',
    () async {
      final h = ParcelHarness(action: ParcelAction.fail);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          throw const AccountFailure('Lost response', unconfirmed: true);
        }
        return h.standardResponse(path, method, body, headers);
      };
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      final original = h.journal.value!;
      h.proofs.files.clear();
      await expectLater(
        h.restart().reconcile(retryUnknown: true),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value!.key, original.key);
      expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
    },
  );

  test(
    'stale assignment/version and wrong waybill do not send a custody command',
    () async {
      final h = ParcelHarness();
      final reviewed = h.task;
      h.taskJson['version'] = 'b' * 64;
      await expectLater(
        h.repository.parcel(h.action, reviewed, barcode: reviewed.tracking),
        throwsA(isA<AccountFailure>()),
      );
      await expectLater(
        h.repository.parcel(h.action, h.task, barcode: 'BGO-WRONG-PARCEL'),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(h.journal.value, isNull);
    },
  );

  test('proof or journal storage failure prevents network mutation and allows recovery', () async {
    final h = ParcelHarness(action: ParcelAction.deliver);
    h.proofs.failSave = true;
    await expectLater(h.submit(), throwsStateError);
    h.proofs.failSave = false;
    h.journal.failWrite = true;
    await expectLater(h.submit(), throwsStateError);
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    expect(h.proofs.files, isEmpty);
    h.journal.failWrite = false;
    await h.submit();
    expect(h.journal.value, isNull);
  });

  test(
    'logout during dispatch keeps the original account recovery evidence',
    () async {
      final h = ParcelHarness(action: ParcelAction.deliver);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          h.current = false;
          return parcelCommand(h.journal.value!);
        }
        return h.standardResponse(path, method, body, headers);
      };
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      expect(h.journal.value, isNotNull);
      expect(h.proofs.files, hasLength(1));
      await expectLater(
        h.repository.reconcile(),
        throwsA(isA<AccountFailure>()),
      );
    },
  );

  for (final status in [403, 409, 422]) {
    test(
      '$status rejection preserves uncertainty or cleans a definitive refusal correctly',
      () async {
        final h = ParcelHarness(action: ParcelAction.deliver);
        h.api.respond = (path, method, body, headers) async {
          if (method == 'POST') {
            throw AccountFailure('Rejected', status: status);
          }
          return h.standardResponse(path, method, body, headers);
        };
        await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
        expect(h.journal.value != null, status == 403);
        expect(h.proofs.files.isNotEmpty, status == 403);
      },
    );
  }

  test(
    'changed intent/expired replay cannot replace the unresolved key',
    () async {
      final h = ParcelHarness(action: ParcelAction.fail);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          throw const AccountFailure(
            'Conflict',
            status: 409,
            code: 'IDEMPOTENCY_CONFLICT',
          );
        }
        return h.standardResponse(path, method, body, headers);
      };
      await expectLater(h.submit(), throwsA(isA<AccountFailure>()));
      final original = h.journal.value!;
      await expectLater(
        h
            .restart(now: () => DateTime.utc(2026, 10, 26))
            .reconcile(retryUnknown: true),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.journal.value!.key, original.key);
      expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
      h.api.respond = (path, method, body, headers) async {
        final response = parcelCommand(original);
        response['data']['retry_expired'] = true;
        return response;
      };
      await h.repository.reconcile();
      expect(h.journal.value, isNull);
    },
  );

  test(
    'mismatched result retains recovery and proof instead of reporting success',
    () async {
      final h = ParcelHarness(action: ParcelAction.deliver);
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          final result = parcelCommand(h.journal.value!);
          result['data']['result']['operational_stage'] = 'completed';
          return result;
        }
        return h.standardResponse(path, method, body, headers);
      };
      await expectLater(
        h.submit(),
        throwsA(
          isA<AccountFailure>().having((v) => v.unconfirmed, 'uncertain', true),
        ),
      );
      expect(h.journal.value, isNotNull);
      expect(h.proofs.files, hasLength(1));
    },
  );

  test('COD checks use exact cents and reject a changed received-minus-change amount', () async {
    final h = ParcelHarness(action: ParcelAction.deliver);
    await expectLater(
      h.repository.parcel(
        h.action,
        h.task,
        barcode: h.task.tracking,
        proof: h.proof,
        fields: {...h.fields, 'change_given': '74.99'},
      ),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    expect(h.proofs.files, isEmpty);
    expect(pesoInputCents('999999999.99'), BigInt.parse('99999999999'));
    for (final input in [
      '01',
      '-1',
      '1,000',
      '1.001',
      '1e2',
      '１',
      '1000000000',
    ]) {
      expect(() => pesoInputCents(input), throwsA(isA<AccountFailure>()));
    }
  });

  test('existing duty/claim JSON and unsupported future records preserve their identity', () {
    final old = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'duty',
      resource: 'rider',
      body: {'on_duty': false},
      createdAt: DateTime.utc(2026),
    );
    final restored = CommandIntent.fromJson(
      jsonDecode(jsonEncode(old.toJson())),
    );
    expect(restored.key, old.key);
    expect(restored.toJson(), old.toJson());
    expect(
      () =>
          CommandIntent.fromJson({...old.toJson(), 'action': 'future.action'}),
      throwsFormatException,
    );
    for (final raw in [
      '\nBGO-123',
      'BGO-123\n',
      'ＢＧＯ-123',
      'https://example.test/track/BGO-123',
    ]) {
      expect(() => parcelWaybill(raw), throwsA(isA<AccountFailure>()));
    }
    expect(parcelWaybill('  bgo-123  '), 'BGO-123');
  });
}
