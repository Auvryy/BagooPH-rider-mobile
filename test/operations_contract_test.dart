import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/operations/$name.json').readAsStringSync())
        as Map<String, dynamic>;

class Journal implements CommandJournal {
  CommandIntent? value;
  bool fail = false;
  @override
  Future<CommandIntent?> read() async => value;
  @override
  Future<void> write(CommandIntent intent) async {
    if (fail) throw StateError('storage unavailable');
    value = intent;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class Session implements RiderSessionApi {
  final calls =
      <
        ({
          String path,
          String method,
          Object? data,
          Map<String, String> headers,
        })
      >[];
  late Future<Map<String, dynamic>> Function(
    String,
    String,
    Object?,
    Map<String, String>,
  )
  respond;
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) {
    calls.add((path: path, method: method, data: data, headers: headers));
    return respond(path, method, data, headers);
  }
}

Map<String, dynamic> command(CommandIntent intent) => {
  'data': {
    'idempotency_key': intent.key,
    'action': intent.action,
    'resource': intent.resource,
    'state': 'committed',
    'result': intent.action == 'duty'
        ? {'on_duty': intent.body['on_duty']}
        : {
            'task_id': intent.resource,
            'delivery_id': intent.resource.substring(7),
          },
    'recorded_at': '2026-10-09T02:00:00.000Z',
    'expires_at': '2026-10-16T02:00:00.000Z',
    'retry_expired': false,
    'replayed': false,
  },
};
void main() {
  test('accepted Home and owned tasks retain exact identifiers and money', () {
    final home = OperationsHome.fromJson(fixture('home')['data']);
    expect(home.capacity['pickup_limit'], 5);
    final j = fixture('final-mile-task')['data'] as Map<String, dynamic>;
    j['id'] = 'final_mile-9223372036854775807';
    j['delivery_id'] = '9223372036854775807';
    j['payment']['cod_due_cents'] = '900719925474099399';
    final t = OperationTask.fromJson(j);
    expect(t.deliveryId, '9223372036854775807');
    expect(t.codDueCents, BigInt.parse('900719925474099399'));
    expect(exactPesos(t.codDueCents!), '₱9,007,199,254,740,993.99');
    for (final bad in ['01', '9223372036854775808', '1.0', '１']) {
      expect(() => Wire.id(bad), throwsFormatException);
    }
    expect(() => Wire.id(1), throwsFormatException);
    expect(() => Wire.version('v1'), throwsFormatException);
    expect(() => Wire.time('2026-02-30T00:00:00.000Z'), throwsFormatException);
  });
  test('missing or invalid coordinates do not invent pins and preview rejects private buyer data', () {
    final j = fixture('pickup-task')['data'] as Map<String, dynamic>;
    j['stop']['latitude'] = 91;
    j['stop']['longitude'] = 121;
    expect(OperationTask.fromJson(j).stop.latitude, isNull);
    j['preview'] = true;
    j['stop']['kind'] = 'buyer';
    expect(() => OperationTask.fromJson(j), throwsFormatException);
  });
  test(
    'pagination validates boundaries and stale schema does not appear empty',
    () {
      final page = TaskPage.fromJson({
        'items': [],
        'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'last_page': 1},
      });
      expect(page.hasNext, false);
      expect(() => TaskPage.fromJson({'items': []}), throwsFormatException);
    },
  );
  test('persist before send; timeout and restart reconcile or replay the exact intent', () async {
    final api = Session(), journal = Journal();
    final repo = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: true,
      isCurrent: () => true,
    );
    api.respond = (path, method, data, headers) async {
      if (path == 'rider/home') return fixture('home');
      expect(journal.value, isNotNull);
      expect(headers['Idempotency-Key'], journal.value!.key);
      throw const AccountFailure('timeout', unconfirmed: true);
    };
    await expectLater(repo.duty(false), throwsA(isA<AccountFailure>()));
    final original = journal.value!;
    final persisted = CommandIntent.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    journal.value = persisted;
    final restarted = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: true,
      isCurrent: () => true,
    );
    api.respond = (path, method, data, headers) async {
      if (path.startsWith('rider/commands/')) {
        throw const AccountFailure(
          'unknown',
          status: 404,
          code: 'COMMAND_UNKNOWN',
        );
      }
      expect(headers['Idempotency-Key'], original.key);
      expect(data, original.body);
      return command(original);
    };
    expect(await restarted.reconcile(), isNull);
    expect(journal.value!.key, original.key);
    expect(await restarted.reconcile(retryUnknown: true), {'on_duty': false});
    expect(journal.value, isNull);
  });
  test('storage failure, unresolved intent, disabled deployment and changed account prevent writes', () async {
    final api = Session(), journal = Journal();
    bool current = true;
    api.respond = (_, _, _, _) async => fixture('home');
    var repo = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: false,
      isCurrent: () => current,
    );
    await expectLater(repo.duty(true), throwsA(isA<AccountFailure>()));
    expect(api.calls, isEmpty);
    repo = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: true,
      isCurrent: () => current,
    );
    journal.fail = true;
    await expectLater(repo.duty(true), throwsStateError);
    expect(api.calls.every((c) => c.method == 'GET'), true);
    journal.fail = false;
    journal.value = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'duty',
      resource: 'rider',
      body: {'on_duty': true},
      createdAt: DateTime.utc(2026, 10, 9),
    );
    api.calls.clear();
    await expectLater(repo.duty(false), throwsA(isA<AccountFailure>()));
    expect(api.calls, isEmpty);
    current = false;
    await expectLater(repo.home(), throwsA(isA<AccountFailure>()));
    expect(api.calls, isEmpty);
  });
  test('expired unknown intent retains its original key; committed expired result reconciles', () async {
    final api = Session(), journal = Journal();
    final intent = CommandIntent(
      accountId: '5',
      key: commandUuid(),
      action: 'duty',
      resource: 'rider',
      body: {'on_duty': false},
      createdAt: DateTime.utc(2026, 10, 1),
    );
    journal.value = intent;
    final repo = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: true,
      isCurrent: () => true,
      now: () => DateTime.utc(2026, 10, 9),
    );
    api.respond = (_, _, _, _) async => throw const AccountFailure(
      'unknown',
      status: 404,
      code: 'COMMAND_UNKNOWN',
    );
    await expectLater(
      repo.reconcile(retryUnknown: true),
      throwsA(isA<AccountFailure>()),
    );
    expect(journal.value!.key, intent.key);
    api.respond = (_, _, _, _) async =>
        command(intent)..['data']['retry_expired'] = true;
    expect(await repo.reconcile(), {'on_duty': false});
    expect(journal.value, isNull);
  });
  test('claim sends only expected version, refresh detail is owned and lists use real phases', () async {
    final api = Session(), journal = Journal();
    final j = fixture('pickup-task')['data'] as Map<String, dynamic>;
    j['preview'] = true;
    j['actions']['claim'] = true;
    final task = OperationTask.fromJson(j);
    api.respond = (path, method, data, headers) async {
      if (path == 'rider/home') return fixture('home');
      if (method == 'POST') {
        expect(data, {'expected_version': task.version});
        return command(journal.value!);
      }
      if (path.startsWith('rider/tasks/')) return fixture('pickup-task');
      return {
        'data': {
          'items': [],
          'pagination': {'page': 1, 'per_page': 20, 'total': 0, 'last_page': 1},
        },
      };
    };
    final repo = OperationsRepository(
      api,
      accountId: '5',
      journal: journal,
      writesVerified: true,
      isCurrent: () => true,
    );
    final result = await repo.claim(task);
    expect(result['task_id'], 'pickup-1');
    expect((await repo.detail(result['task_id'])).preview, false);
    await repo.taskPage(TaskQueue.delivery);
    expect(api.calls.last.path, contains('phase=final_mile'));
  });
}
