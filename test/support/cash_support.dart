import 'dart:convert';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/features/cash/data/cash_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';

import 'parcel_support.dart';

Map<String, dynamic> cashFixture({
  String id = '9007199254740993',
  bool detail = true,
}) => {
  'id': id,
  'reference': 'CASH-SOFTWARE-TEST',
  'delivery_id': '23',
  'tracking_number': 'BGO-SOFTWARE-TEST',
  'order_number': 'ORD-TEST',
  'source_kind': 'rider_delivery',
  'status': 'collected',
  'version': '1',
  'source_event_reference': 'EVENT-SOURCE',
  'hub_name': 'Test Hub',
  'company_name': 'Test Logistics',
  'own_held_cents': '12500',
  'own_remitted_cents': '0',
  'expected_cents': '12500',
  'product_subtotal_cents': '12000',
  'discount_cents': '500',
  'shipping_cents': '1000',
  'collected_cents': '12500',
  'reconciled_cents': '0',
  'excess_cents': '0',
  'recorded_at': '2026-10-22T02:00:00.000Z',
  'can_offer': true,
  'can_receive': false,
  'can_reconcile': false,
  'earnings': {
    'available': true,
    'confirmed_cents': '0',
    'pending_cents': '2500',
    'basis': 'original_delivery_earnings_ledger',
  },
  'pending_handover': null,
  'holders': [
    {
      'user_id': '5',
      'name': 'Test Rider',
      'stage': 'rider',
      'amount_cents': '12500',
      'restricted': false,
    },
  ],
  if (detail)
    'recipients': [
      {'id': '12', 'name': 'Test Hub Recipient'},
    ],
  if (detail)
    'history': [
      {
        'reference': 'EVENT-SOURCE',
        'sequence': '1',
        'event_type': 'collected',
        'actor_role': 'courier',
        'actor_name': 'Test Rider',
        'from_stage': null,
        'to_stage': 'rider',
        'provenance': 'delivery_checkpoint',
        'evidence_reference': null,
        'reason': null,
        'source_reference': null,
        'recorded_at': '2026-10-22T02:00:00.000Z',
        'amount_cents': '12500',
        'expected_cents': '12500',
        'received_cents': '12500',
        'discrepancy_cents': null,
        'from_user_id': null,
        'to_user_id': '5',
      },
    ],
  if (detail) 'discrepancies': [],
};
Map<String, dynamic> cashPageFixture({
  List<Map<String, dynamic>>? items,
  int page = 1,
  int total = 1,
  int perPage = 20,
}) => {
  'items': items ?? [cashFixture(detail: false)],
  'summary': {
    'own_held_cents': '900719925474099312500',
    'accounts_with_unresolved_difference': 2,
    'basis': 'all_owned_cash_journals',
  },
  'earnings': {
    'available': true,
    'confirmed_cents': '0',
    'pending_cents': '2500',
    'basis': 'original_delivery_earnings_ledger',
  },
  'pagination': {
    'page': page,
    'per_page': perPage,
    'total': total,
    'last_page': total == 0 ? 1 : (total + perPage - 1) ~/ perPage,
  },
};

class CashHarness {
  CashHarness() {
    api.respond = respond;
    repository = restart();
  }
  final api = ParcelTestApi();
  final journal = ParcelTestJournal();
  Map<String, dynamic> json = cashFixture();
  Map<String, dynamic>? committed;
  bool current = true, capable = true;
  late OperationsRepository repository;
  CashAccount get account => CashAccount.fromJson(json, detail: true);
  OperationsRepository restart({
    bool enabled = true,
    DateTime Function()? now,
  }) => OperationsRepository(
    api,
    accountId: '5',
    journal: journal,
    writesVerified: false,
    cashWritesVerified: enabled,
    isCurrent: () => current,
    now: now ?? () => DateTime.utc(2026, 10, 22, 2),
  );
  Future<Map<String, dynamic>> submit({
    String amount = '125.00',
    String recipient = '12',
    String evidence = 'TEST-HANDOVER-01',
    bool Function()? mayDispatch,
  }) => repository.offerCash(
    account,
    recipientId: recipient,
    amount: amount,
    evidenceReference: evidence,
    mayDispatch: mayDispatch ?? () => true,
  );
  Map<String, dynamic> result(CommandIntent intent) => {
    'idempotency_key': intent.key,
    'action': 'cash.offer',
    'resource': intent.resource,
    'state': 'committed',
    'recorded_at': '2026-10-22T02:00:00.000Z',
    'expires_at': '2026-10-29T02:00:00.000Z',
    'retry_expired': false,
    'replayed': false,
    'result': {
      'cash_account_id': account.id,
      'event_reference': 'EVENT-OFFER',
      'ledger_version': '2',
      'handover_state': 'awaiting_recipient_receipt',
    },
  };
  Future<Map<String, dynamic>> respond(
    String path,
    String method,
    Object? body,
    Map<String, String> headers,
  ) async {
    if (path == 'rider/home') {
      final j = operationFixture('home');
      j['data']['capabilities']['cash'] = capable;
      return j;
    }
    if (path.startsWith('rider/cash?')) return {'data': cashPageFixture()};
    if (path == 'rider/cash/${account.id}') {
      return {'data': jsonDecode(jsonEncode(json))};
    }
    if (path.startsWith('rider/commands/')) {
      if (committed != null) return {'data': committed};
      throw const AccountFailure(
        'Unknown',
        status: 404,
        code: 'COMMAND_UNKNOWN',
      );
    }
    if (path.endsWith('/offer') && method == 'POST') {
      return {'data': result(journal.value!)};
    }
    throw StateError('Unexpected test request $method $path');
  }
}
