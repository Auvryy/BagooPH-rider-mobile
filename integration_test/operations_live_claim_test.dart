import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/network/api_failure.dart';
import 'package:bagoo_rider_mobile/core/network/rider_api_client.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_models.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Operator-only native acceptance. The private runtime case must identify one
// expressly authorized unassigned parcel and a verified deployment. Nothing is
// automatically selected from another account or an arbitrary available job.
// Saved steps retain their original UUID/body across reruns. Claim response loss
// is injected locally AFTER a real successful reply; this is not a network test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('LIVE_DUTY_CLAIM_CHECK');
  testWidgets('native Azure duty and one designated claim retain their intents', (
    tester,
  ) async {
    final config = AppConfig.environment();
    _require(
      Platform.isLinux &&
          config.origin == Uri.parse('https://bagooph.shop/api/v1') &&
          config.operationsWritesVerified &&
          !config.handoverWritesVerified,
      'Use the explicitly enabled Linux operations acceptance configuration.',
    );
    final path = Platform.environment['BAGOO_LIVE_OPERATIONS_CASE'];
    _require(path != null && path.isNotEmpty, 'Supply the private case.');
    final input = File(path!);
    await _privateFile(input);
    final info = await _readJson(input);
    _require(
      info['writes_authorized'] == true &&
          info['migrations_verified'] == true &&
          RegExp(r'^[a-f0-9]{40}$')
              .hasMatch(Wire.string(info['deployed_revision'])) &&
          DateTime.tryParse(Wire.string(info['deployment_verified_at'])) !=
              null,
      'Dated deployment, migrations and isolated write authorization are required.',
    );
    final receipt = await _Receipt.open(input.parent, info);
    final audit = _Audit();
    final dio = Dio()..interceptors.add(audit);
    final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
    var signedIn = false;
    try {
      final account = await auth.login(
        Wire.string(info['email']),
        Wire.string(info['password']),
      );
      signedIn = true;
      _require(
        account.id == Wire.id(info['account_id']) &&
            account.approved &&
            account.operationsApiVersion == 1,
        'The designated approved operations-v1 rider is required.',
      );
      final api = _SuppressClaimReply(auth, receipt);
      final journal = _RecordedJournal(
        SecureCommandJournal(origin: config.origin, accountId: account.id),
        receipt,
      );
      OperationsRepository repository() => OperationsRepository(
        api,
        accountId: account.id,
        journal: journal,
        writesVerified: config.operationsWritesVerified,
        isCurrent: () => signedIn,
      );
      var repo = repository();
      final pending = await repo.pending();
      _require(
        pending == null || receipt.owns(pending),
        'An unrelated saved intent needs its own reconciliation.',
      );
      final home = await repo.home();
      _require(
        home.companyId == Wire.id(info['company_id']) &&
            home.hubId == Wire.id(info['hub_id']) &&
            home.operational &&
            home.capabilities['duty'] == true &&
            home.capabilities['pickup_claim'] == true,
        'The authorized operational placement or capabilities changed.',
      );
      if (receipt.data['baseline'] == null) {
        final pickups = await repo.taskPage(TaskQueue.pickups);
        final deliveries = await repo.taskPage(TaskQueue.delivery);
        _require(
          home.onDuty == Wire.boolean(info['initial_duty']) &&
              home.canClaim &&
              home.capacity['active_pickups'] ==
                  Wire.count(info['initial_pickup_count']) &&
              !pickups.hasNext &&
              !deliveries.hasNext &&
              pickups.total == info['initial_pickup_count'] &&
              pickups.items.every((t) => t.id != info['task_id']),
          'The prepared baseline changed; no command was sent.',
        );
        receipt.data['baseline'] = {
          'pickups': pickups.items.map(_taskState).toList(),
          'deliveries': deliveries.items.map(_taskState).toList(),
          'active_pickups': home.capacity['active_pickups'],
        };
        await receipt.save();
      }

      Future<Map<String, dynamic>> command(
        String step,
        Future<Map<String, dynamic>> Function() send, {
        bool replay = false,
      }) async {
        final saved = receipt.intent(step);
        journal.step = step;
        if (saved != null) {
          final retained = await repo.pending();
          _require(
            retained == null || retained.key == saved.key,
            'A different command must be reconciled first.',
          );
          // Reinsert only this exact original intent if a previous successful
          // response already cleared protected storage before receipt saving.
          if (retained == null) await journal.write(saved);
          await repo.reconcile(retryUnknown: true);
        } else {
          _require(
            await repo.pending() == null,
            'Reconcile the retained command before another step.',
          );
          try {
            await send();
          } on AccountFailure catch (failure) {
            if (!failure.unconfirmed) rethrow;
            final retained = await repo.pending();
            _require(
              retained != null && retained.key == receipt.intent(step)?.key,
              'An uncertain response must retain its original protected intent.',
            );
            receipt.data['protected_uncertain_intent_verified'] = true;
            await receipt.save();
            // Recreate the repository to exercise restart-style recovery.
            repo = repository();
            await repo.reconcile(retryUnknown: true);
          }
        }
        final intent = receipt.intent(step)!;
        final envelope = Wire.object(
          (await api.authenticatedRequest(
            'rider/commands/${intent.key}',
          ))['data'],
        );
        _commandMatches(intent, envelope);
        if (replay && receipt.stepData(step)['replayed'] != true) {
          final again = Wire.object(
            (await api.authenticatedRequest(
              intent.path,
              method: intent.method,
              data: intent.body,
              headers: {
                'Idempotency-Key': intent.key,
                'X-Request-ID': commandUuid(),
              },
            ))['data'],
          );
          _commandMatches(intent, again);
          _require(again['replayed'] == true, 'Replay was not acknowledged.');
          _require(
            jsonEncode(again['result']) == jsonEncode(envelope['result']),
            'Replay changed the original command result.',
          );
          receipt.stepData(step)['replayed'] = true;
        }
        _require(
          await repo.pending() == null,
          'Committed reconciliation did not clear the protected intent.',
        );
        receipt.stepData(step)['command'] = envelope;
        await receipt.save();
        return Wire.object(envelope['result']);
      }

      if (receipt.data['off_duty_preserved_work'] != true) {
        await command('duty_off', () => repo.duty(false), replay: true);
        final off = await repo.home();
        _require(
          !off.onDuty && !off.canClaim && off.claimDenial == 'OFF_DUTY',
          'Off duty must block new claims.',
        );
        final owned = await repo.taskPage(TaskQueue.pickups);
        _sameTasks(owned, receipt.baseline('pickups'));
        _sameTasks(
          await repo.taskPage(TaskQueue.delivery),
          receipt.baseline('deliveries'),
        );
        receipt.data['off_duty_preserved_work'] = true;
        await receipt.save();
      }
      if (receipt.data['on_duty_verified'] != true) {
        await command('duty_on', () => repo.duty(true));
        final on = await repo.home();
        _require(
          on.onDuty && on.canClaim,
          'On-duty eligibility was not saved.',
        );
        receipt.data['on_duty_verified'] = true;
        await receipt.save();
      }
      if (receipt.data['changed_body_rejected'] != true) {
        final original = receipt.intent('duty_on')!;
        try {
          await api.authenticatedRequest(
            original.path,
            method: original.method,
            data: {'on_duty': false},
            headers: {
              'Idempotency-Key': original.key,
              'X-Request-ID': commandUuid(),
            },
          );
          throw StateError('A changed-body replay unexpectedly succeeded.');
        } on AccountFailure catch (failure) {
          _require(
            !failure.unconfirmed &&
                failure.status == 409 &&
                failure.code == 'IDEMPOTENCY_CONFLICT',
            'The changed-body conflict could not be verified.',
          );
          receipt.data['changed_body_rejected'] = true;
          receipt.data['changed_body_rejection'] = {
            'status': failure.status,
            'code': failure.code,
            'request_id': failure.requestId,
          };
          await receipt.save();
        }
      }
      if (receipt.data['claim_owned_verified'] != true) {
        OperationTask? preview;
        if (receipt.intent('claim') == null) {
          final available = await repo.taskPage(TaskQueue.available);
          final designated = available.items.where(
            (t) => t.id == Wire.taskId(info['task_id']),
          );
          _require(
            designated.length == 1,
            'The designated parcel is no longer in this refreshed queue.',
          );
          preview = designated.single;
          _require(
            preview.deliveryId == Wire.id(info['parcel_id']) &&
                preview.tracking == Wire.string(info['tracking']) &&
                preview.order == Wire.string(info['order']) &&
                preview.stage == Wire.string(info['expected_stage']) &&
                preview.commercialStatus ==
                    Wire.string(info['expected_status']) &&
                preview.custodyKind == Wire.string(info['expected_custody']) &&
                preview.preview &&
                preview.assignmentReference == null &&
                preview.actions['claim'] == true &&
                !preview.heldByMe,
            'The designated available parcel changed; no claim was sent.',
          );
        }
        await command('claim', () => repo.claim(preview!), replay: true);
        receipt.data['claim_owned_verified'] = true;
        await receipt.save();
      }

      // An explicitly separate negative probe uses the ORIGINAL preview version
      // after the confirmed claim. It is never a replacement for an uncertain
      // intent. Retain its own key so even an interrupted probe cannot multiply.
      if (receipt.data['stale_claim_rejected'] != true) {
        journal.step = 'stale_probe';
        final stale =
            receipt.intent('stale_probe') ??
            CommandIntent(
              accountId: account.id,
              key: commandUuid(),
              action: 'claim',
              resource: Wire.taskId(info['task_id']),
              body: receipt.intent('claim')!.body,
              createdAt: DateTime.now().toUtc(),
            );
        final retained = await repo.pending();
        _require(
          retained == null || retained.key == stale.key,
          'Resolve the different pending command.',
        );
        await journal.write(stale);
        try {
          await api.authenticatedRequest(
            stale.path,
            method: stale.method,
            data: stale.body,
            headers: {
              'Idempotency-Key': stale.key,
              'X-Request-ID': commandUuid(),
            },
          );
          throw StateError('A stale claim unexpectedly succeeded; inspect it.');
        } on AccountFailure catch (failure) {
          _require(
            !failure.unconfirmed &&
                failure.status == 409 &&
                failure.code == 'STALE_RESOURCE',
            'The stale probe needs original-key reconciliation; do not replace it.',
          );
          receipt.data['stale_claim_rejected'] = true;
          receipt.stepData('stale_probe')['rejection'] = {
            'status': failure.status,
            'code': failure.code,
            'request_id': failure.requestId,
          };
          await receipt.save();
          await journal.clear();
        }
      }
      final detail = await repo.detail(Wire.taskId(info['task_id']));
      _require(
        detail.deliveryId == info['parcel_id'] &&
            detail.tracking == info['tracking'] &&
            detail.order == info['order'] &&
            !detail.preview &&
            detail.assignmentReference != null &&
            detail.stage == 'assigned_pickup' &&
            detail.commercialStatus == info['expected_status'] &&
            detail.custodyKind == info['expected_custody'] &&
            !detail.heldByMe &&
            detail.custodyHubId == null,
        'Fresh owned detail does not establish assignment without collection.',
      );
      final pickups = await repo.taskPage(TaskQueue.pickups);
      _require(
        !pickups.hasNext &&
            pickups.total == receipt.baseline('pickups').length + 1 &&
            pickups.items.where((t) => t.id == detail.id).length == 1,
        'The final pickup queue does not contain exactly one new assignment.',
      );
      final other = pickups.items.where((t) => t.id != detail.id).toList();
      _require(
        _sameState(other.map(_taskState).toList(), receipt.baseline('pickups')),
        'Another existing pickup assignment changed.',
      );
      _sameTasks(
        await repo.taskPage(TaskQueue.delivery),
        receipt.baseline('deliveries'),
      );
      final finalHome = await repo.home();
      _require(
        finalHome.onDuty &&
            finalHome.capacity['active_pickups'] == pickups.total &&
            audit.valid,
        'Final duty, capacity or native privacy headers could not be verified.',
      );
      receipt.data.addAll({
        'phase': 'native_check_passed_website_confirmation_pending',
        'observed_at': DateTime.now().toUtc().toIso8601String(),
        'final_duty': finalHome.onDuty,
        'final_task': _taskState(detail),
        'final_active_pickups': finalHome.capacity['active_pickups'],
        'private_json_headers_verified': true,
        'website_post_check': 'pending',
        'physical_collection_performed': false,
        'request_references': audit.requests,
      });
      await receipt.save();
      debugPrint(
        'Native Azure duty, original-key replay, protected-intent recovery, '
        'designated assignment and stale rejection verified. '
        'Website post-check remains pending; no physical collection.',
      );
    } on AccountFailure catch (failure) {
      receipt.data['last_failure'] = {
        'status': failure.status,
        'code': failure.code,
        'request_id': failure.requestId,
        'unconfirmed': failure.unconfirmed,
      };
      await receipt.save();
      throw StateError(
        'Native acceptance stopped; inspect the private receipt.',
      );
    } finally {
      try {
        if (signedIn) {
          await auth.logout();
          receipt.data['temporary_session_logged_out'] = true;
          await receipt.save();
        }
      } finally {
        signedIn = false;
        dio.close(force: true);
      }
    }
  }, skip: !enabled);
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Map<String, dynamic> _taskState(OperationTask task) => {
  'id': task.id,
  'delivery_id': task.deliveryId,
  'assignment_reference': task.assignmentReference,
  'version': task.version,
  'stage': task.stage,
  'commercial_status': task.commercialStatus,
  'custody': task.custodyKind,
  'held_by_me': task.heldByMe,
  'custody_hub_id': task.custodyHubId,
};

bool _sameState(List<dynamic> a, List<dynamic> b) {
  final left = a.map(jsonEncode).toList()..sort();
  final right = b.map(jsonEncode).toList()..sort();
  return listEquals(left, right);
}

void _sameTasks(TaskPage page, List<dynamic> baseline) => _require(
  !page.hasNext &&
      page.total == baseline.length &&
      _sameState(page.items.map(_taskState).toList(), baseline),
  'Off-duty existing work changed.',
);

void _commandMatches(CommandIntent intent, Map<String, dynamic> command) {
  _require(
    command['idempotency_key'] == intent.key &&
        command['action'] == intent.action &&
        command['resource'] == intent.resource &&
        command['state'] == 'committed' &&
        command['retry_expired'] == false,
    'The owned command does not match the original retained intent.',
  );
  Wire.time(command['recorded_at']);
  Wire.time(command['expires_at']);
  Wire.boolean(command['replayed']);
  final result = Wire.object(command['result']);
  _require(
    intent.action == 'duty'
        ? result['on_duty'] == intent.body['on_duty']
        : result['task_id'] == intent.resource &&
              result['delivery_id'] == intent.resource.substring(7),
    'The committed result differs from the original requested action.',
  );
}

Future<void> _privateFile(File file) async => _require(
  await FileSystemEntity.type(file.path, followLinks: false) ==
          FileSystemEntityType.file &&
      (await file.stat()).mode & 0x3f == 0 &&
      (await file.parent.stat()).mode & 0x3f == 0,
  'Use mode-600 files in a mode-700 directory without symlinks.',
);

Future<Map<String, dynamic>> _readJson(File file) async {
  try {
    return Wire.object(jsonDecode(await file.readAsString()));
  } on FormatException {
    throw StateError('Private acceptance JSON could not be decoded.');
  }
}

class _Receipt {
  _Receipt(this.file, this.data);
  final File file;
  final Map<String, dynamic> data;
  static Future<_Receipt> open(
    Directory directory,
    Map<String, dynamic> info,
  ) async {
    final file = File('${directory.path}/duty-claim-receipt.json');
    final binding = {
      'case_marker': Wire.string(info['case_marker']),
      'account_id': Wire.id(info['account_id']),
      'parcel_id': Wire.id(info['parcel_id']),
      'task_id': Wire.taskId(info['task_id']),
      'operator_verified_deployment': Wire.string(info['deployed_revision']),
    };
    Map<String, dynamic> data;
    if (await file.exists()) {
      await _privateFile(file);
      data = await _readJson(file);
      _require(
        binding.entries.every((e) => data[e.key] == e.value),
        'The receipt belongs to a different case; preserve it.',
      );
    } else {
      data = {...binding, 'steps': <String, dynamic>{}};
    }
    final receipt = _Receipt(file, data);
    await receipt.save();
    return receipt;
  }

  Map<String, dynamic> stepData(String step) {
    final steps = Wire.object(data['steps']);
    return Wire.object(steps.putIfAbsent(step, () => <String, dynamic>{}));
  }

  CommandIntent? intent(String step) {
    final value = stepData(step)['intent'];
    return value == null ? null : CommandIntent.fromJson(Wire.object(value));
  }

  bool owns(CommandIntent pending) => Wire.object(data['steps']).values.any(
    (value) =>
        Wire.object(value)['intent'] is Map &&
        Wire.object(Wire.object(value)['intent'])['key'] == pending.key,
  );

  List<dynamic> baseline(String queue) =>
      Wire.object(data['baseline'])[queue] as List<dynamic>;

  Future<void> save() async {
    final temporary = File('${file.path}.next');
    _require(
      !await temporary.exists(),
      'Inspect the interrupted receipt write.',
    );
    await temporary.create(exclusive: true);
    final mode = await Process.run('chmod', ['600', temporary.path]);
    _require(mode.exitCode == 0, 'Could not protect the private receipt.');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      flush: true,
    );
    await temporary.rename(file.path);
  }
}

class _RecordedJournal implements CommandJournal {
  _RecordedJournal(this.inner, this.receipt);
  final CommandJournal inner;
  final _Receipt receipt;
  String? step;
  @override
  Future<CommandIntent?> read() => inner.read();
  @override
  Future<void> clear() => inner.clear();
  @override
  Future<void> write(CommandIntent intent) async {
    _require(step != null, 'A controlled command step is required.');
    final previous = receipt.intent(step!);
    _require(
      previous == null ||
          jsonEncode(previous.toJson()) == jsonEncode(intent.toJson()),
      'Never replace an original step intent.',
    );
    receipt.stepData(step!)['intent'] = intent.toJson();
    await receipt.save();
    await inner.write(intent);
  }
}

class _SuppressClaimReply implements RiderSessionApi {
  _SuppressClaimReply(this.inner, this.receipt);
  final RiderSessionApi inner;
  final _Receipt receipt;
  @override
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  }) async {
    final response = await inner.authenticatedRequest(
      path,
      method: method,
      data: data,
      headers: headers,
    );
    if (method == 'POST' &&
        path == 'rider/pickup-jobs/${receipt.data['parcel_id']}/claim' &&
        headers['Idempotency-Key'] == receipt.intent('claim')?.key &&
        receipt.data['claim_reply_suppressed_locally'] != true) {
      receipt.data['claim_reply_suppressed_locally'] = true;
      await receipt.save();
      throw const AccountFailure(
        'Locally suppressed committed claim response for recovery acceptance.',
        unconfirmed: true,
      );
    }
    return response;
  }
}

class _Audit extends Interceptor {
  var valid = true;
  final requests = <Map<String, dynamic>>[];
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final cache = (response.headers.value('cache-control') ?? '')
        .toLowerCase()
        .split(',')
        .map((v) => v.trim())
        .toSet();
    if (RegExp(r'/api/v1/rider/(home|duty|pickup-jobs|tasks|commands)(/|$)')
        .hasMatch(response.requestOptions.uri.path)) {
      valid =
          valid &&
          response.headers.value('content-type')?.split(';').first.trim() ==
              'application/json' &&
          cache.containsAll({'private', 'no-store'}) &&
          (cache.contains('no-cache') ||
              response.headers.value('pragma')?.toLowerCase() == 'no-cache') &&
          response.headers.value('x-content-type-options') == 'nosniff';
      final body = response.data;
      final reference = body is Map ? body['request_id'] : null;
      requests.add({
        'method': response.requestOptions.method,
        'path': response.requestOptions.uri.path,
        'status': response.statusCode,
        if (reference is String &&
            RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$')
                .hasMatch(reference))
          'request_id': reference,
      });
    }
    handler.next(response);
  }
}
