import 'dart:convert';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/commands/command_intent.dart';
import 'package:bagoo_rider_mobile/core/commands/parcel_validation.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/parcel_support.dart';

const recipientFields = {
  'recipient_name': 'Software Test Recipient',
  'recipient_relationship': 'buyer',
};

ParcelHarness walletHarness({bool enabled = true}) {
  final h = ParcelHarness(action: ParcelAction.deliver);
  h.taskJson['payment'] = {
    'method': 'wallet',
    'commercial_payment_status': 'paid',
    'cod_due_cents': null,
  };
  h.taskJson['stop']['kind'] = 'buyer';
  h.repository = h.restart(prepaidEnabled: enabled);
  return h;
}

Future<Map<String, dynamic>> deliver(
  ParcelHarness h, {
  Map<String, dynamic> fields = recipientFields,
}) => h.repository.parcel(
  ParcelAction.deliver,
  h.task,
  barcode: h.task.tracking,
  fields: fields,
  proof: h.proof,
);

void main() {
  test(
    'prepaid acceptance is independently disabled in ordinary builds',
    () async {
      const config = AppConfig(
        'https://example.test/api/v1',
        parcelWritesVerified: true,
      );
      expect(config.prepaidDeliveryWritesVerified, isFalse);
      final h = walletHarness(enabled: false);
      await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(h.proofs.files, isEmpty);
      expect(h.journal.value, isNull);
    },
  );

  test('paid wallet body omits cash and local variant metadata while retaining original proof', () async {
    final h = walletHarness();
    expect(h.task.deliveryPaymentKind, DeliveryPaymentKind.paidWallet);
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        final intent = h.journal.value!;
        expect(intent.deliveryPaymentMethod, 'wallet');
        expect(
          intent.body.keys,
          unorderedEquals([
            'expected_version',
            'barcode',
            ...recipientFields.keys,
          ]),
        );
        final data = body as FormData, fields = Map.fromEntries((body).fields);
        expect(fields.keys, unorderedEquals(intent.body.keys));
        expect(
          fields.keys.any((k) => k.startsWith('cash') || k == 'change_given'),
          isFalse,
        );
        expect(fields.containsKey('delivery_payment_method'), isFalse);
        expect(headers['Idempotency-Key'], intent.key);
        expect(
          await data.files.single.value.finalize().expand((v) => v).toList(),
          h.proof.bytes,
        );
      }
      return h.standardResponse(path, method, body, headers);
    };
    expect((await deliver(h))['operational_stage'], 'delivered');
    expect(h.journal.value, isNull);
    expect(h.proofs.files, isEmpty);
  });

  for (final change in [
    {
      'method': 'wallet',
      'commercial_payment_status': 'unpaid',
      'cod_due_cents': null,
    },
    {
      'method': 'wallet',
      'commercial_payment_status': 'paid',
      'cod_due_cents': '100',
    },
    {
      'method': 'card',
      'commercial_payment_status': 'paid',
      'cod_due_cents': null,
    },
    {
      'method': 'cod',
      'commercial_payment_status': 'pending',
      'cod_due_cents': null,
    },
  ]) {
    test(
      'unverified or inconsistent payment ${change['method']}/${change['commercial_payment_status']}/${change['cod_due_cents']} cannot deliver',
      () async {
        final h = walletHarness();
        h.taskJson['payment'] = change;
        expect(h.task.deliveryPaymentKind, DeliveryPaymentKind.unavailable);
        await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
        expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
        expect(h.proofs.files, isEmpty);
        expect(h.journal.value, isNull);
      },
    );
  }

  test(
    'a paid label without the current delivery permission is unavailable',
    () async {
      final h = walletHarness();
      h.taskJson['actions']['deliver'] = false;
      expect(h.task.deliveryPaymentKind, DeliveryPaymentKind.unavailable);
      await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
    },
  );

  for (final fields in [
    {...recipientFields, 'cash_received': '0'},
    {
      ...recipientFields,
      'cash_received': '100.00',
      'change_given': '0',
      'cash_confirmed': true,
    },
    {...recipientFields, 'cash_confirmed': false},
  ]) {
    test('wallet command refuses caller cash fields ${fields.keys}', () async {
      final h = walletHarness();
      await expectLater(
        deliver(h, fields: fields),
        throwsA(isA<AccountFailure>()),
      );
      expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(h.journal.value, isNull);
    });
  }

  test('a changed payment with an unchanged version requires a new explicit review', () async {
    final h = walletHarness(), reviewed = walletHarness().task;
    h.taskJson['payment'] = {
      'method': 'cod',
      'commercial_payment_status': 'pending',
      'cod_due_cents': '12500',
    };
    await expectLater(
      h.repository.parcel(
        ParcelAction.deliver,
        reviewed,
        barcode: reviewed.tracking,
        fields: recipientFields,
        proof: h.proof,
      ),
      throwsA(
        isA<AccountFailure>().having((e) => e.code, 'code', 'STALE_RESOURCE'),
      ),
    );
    expect(h.journal.value, isNull);
    expect(h.api.calls.where((c) => c.method == 'POST'), isEmpty);
  });

  test('wallet restart/unknown replay retains the same key, omitted cash and original image', () async {
    final h = walletHarness();
    final keys = <String>[],
        bodies = <Map<String, String>>[],
        images = <List<int>>[];
    var interrupted = true;
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        final data = body as FormData;
        keys.add(headers['Idempotency-Key']!);
        bodies.add(Map.fromEntries(data.fields));
        images.add(
          await data.files.single.value.finalize().expand((v) => v).toList(),
        );
        if (interrupted) {
          interrupted = false;
          throw const AccountFailure('Interrupted upload', unconfirmed: true);
        }
      }
      return h.standardResponse(path, method, body, headers);
    };
    await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    h.journal.value = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    final restarted = h.restart(prepaidEnabled: true);
    expect(await restarted.reconcile(), isNull);
    await restarted.reconcile(retryUnknown: true);
    expect(keys, [original.key, original.key]);
    expect(bodies[0], bodies[1]);
    expect(images, [h.proof.bytes.toList(), h.proof.bytes.toList()]);
    expect(h.journal.value, isNull);
  });

  test('unaccepted prepaid retry stays retained but a committed result can reconcile', () async {
    final h = walletHarness();
    h.api.respond = (path, method, body, headers) async {
      if (method == 'POST') {
        throw const AccountFailure('Lost result', unconfirmed: true);
      }
      return h.standardResponse(path, method, body, headers);
    };
    await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
    final original = h.journal.value!;
    await expectLater(
      h.restart().reconcile(retryUnknown: true),
      throwsA(isA<AccountFailure>()),
    );
    expect(h.journal.value!.key, original.key);
    expect(h.api.calls.where((c) => c.method == 'POST'), hasLength(1));
    h.api.respond = (path, method, body, headers) async =>
        parcelCommand(original);
    await h.restart().reconcile();
    expect(h.journal.value, isNull);
  });

  test(
    'journal distinguishes a prepaid intent from an incomplete legacy COD body',
    () async {
      final h = walletHarness();
      h.api.respond = (path, method, body, headers) async {
        if (method == 'POST') {
          throw const AccountFailure('Lost result', unconfirmed: true);
        }
        return h.standardResponse(path, method, body, headers);
      };
      await expectLater(deliver(h), throwsA(isA<AccountFailure>()));
      final original = h.journal.value!,
          json = Map<String, dynamic>.from(h.journal.value!.toJson());
      expect(CommandIntent.fromJson(json).deliveryPaymentMethod, 'wallet');
      json.remove('delivery_payment_method');
      expect(() => CommandIntent.fromJson(json), throwsFormatException);
      expect(
        () => CommandIntent.fromJson({
          ...original.toJson(),
          'delivery_payment_method': 'future',
        }),
        throwsFormatException,
      );
      expect(
        () => CommandIntent.fromJson({
          ...original.toJson(),
          'body': {...original.body, 'cash_confirmed': true},
        }),
        throwsFormatException,
      );
    },
  );
}
