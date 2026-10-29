import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/company/data/company_repository.dart';

import 'parcel_support.dart';

Map<String, dynamic> companyFixture(String name) =>
    jsonDecode(
          File('test/fixtures/company/$name.json').readAsStringSync(),
        )['data']
        as Map<String, dynamic>;

class CompanyTestApi implements RiderSessionApi {
  Map<String, dynamic> membership = companyFixture('assignment-unassigned');
  Map<String, dynamic> detail = companyFixture('application-offered');
  Map<String, dynamic> directory = companyFixture('companies');
  Map<String, dynamic> company = companyFixture('company');
  final calls =
      <
        ({
          String method,
          String path,
          Map<String, String> headers,
          Object? body,
        })
      >[];
  final results = <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> requests = [];
  bool loseAfterCommit = false, loseBeforeCommit = false, wrongReceipt = false;
  Completer<void>? delay;
  AccountFailure? failure;
  int get writes => calls.where((c) => c.method == 'POST').length;
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) async {
    calls.add((
      method: method,
      path: path,
      headers: Map.of(headers),
      body: data,
    ));
    if (delay != null) {
      final gate = delay!;
      delay = null;
      await gate.future;
    }
    if (failure != null) throw failure!;
    Map<String, dynamic> result;
    if (method == 'POST') {
      final key = headers['Idempotency-Key']!;
      if (loseBeforeCommit) {
        loseBeforeCommit = false;
        throw const AccountFailure(
          'Connection interrupted.',
          unconfirmed: true,
        );
      }
      if (results.containsKey(key)) return {'data': results[key]!};
      final accepting = path.endsWith('/accept');
      final action = accepting
          ? 'accepted'
          : path.endsWith('/decline')
          ? 'declined'
          : path.endsWith('/withdraw')
          ? 'withdrawn'
          : 'pending';
      result = companyFixture(
        accepting ? 'command-accepted' : 'command-submitted',
      );
      result['idempotency_key'] = wrongReceipt
          ? '11111111-1111-4111-8111-111111111111'
          : key;
      if (action != 'pending') {
        result['action'] = 'company.$action';
        result['resource'] = 'company-request-1';
        (result['result'] as Map<String, dynamic>)['status'] = action;
      }
      results[key] = jsonDecode(jsonEncode(result)) as Map<String, dynamic>;
      if (accepting) {
        membership = companyFixture('assignment-accepted');
        detail = companyFixture('application-accepted');
      } else {
        detail = companyFixture('application-pending');
        detail['status'] = action;
        detail['effective_status'] = action;
        if (action == 'pending') {
          (membership['actions'] as Map<String, dynamic>)['apply'] = false;
          membership['blocked_reason'] =
              'Your current company request is awaiting review.';
        }
      }
      requests = [detail];
      if (loseAfterCommit) {
        loseAfterCommit = false;
        throw const AccountFailure(
          'Connection interrupted.',
          unconfirmed: true,
        );
      }
    } else if (path.startsWith('rider/company-commands/')) {
      final saved = results[path.split('/').last];
      if (saved == null) {
        throw const AccountFailure(
          'No committed request is visible.',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      result = saved;
    } else if (path == 'rider/company-assignment') {
      result = membership;
    } else if (path.startsWith('rider/companies?')) {
      result = directory;
    } else if (path == 'rider/companies/1') {
      result = company;
    } else if (path.startsWith('rider/company-requests?')) {
      result = {
        'items': requests,
        'pagination': {
          'page': 1,
          'per_page': 20,
          'total': requests.length,
          'last_page': 1,
        },
      };
    } else if (path == 'rider/company-requests/1') {
      result = detail;
    } else {
      throw const AccountFailure('Unknown software-test path.', status: 404);
    }
    return {'data': jsonDecode(jsonEncode(result))};
  }
}

({
  RiderCompanyRepository repository,
  CompanyTestApi api,
  ParcelTestJournal journal,
})
companySetup({bool Function()? isCurrent}) {
  final api = CompanyTestApi(), journal = ParcelTestJournal();
  return (
    api: api,
    journal: journal,
    repository: RiderCompanyRepository(
      api,
      accountId: '7',
      journal: journal,
      isCurrent: isCurrent ?? () => true,
      now: () => DateTime.utc(2026, 10, 15, 7),
    ),
  );
}
