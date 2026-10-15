import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
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

// Explicit native read acceptance. Runtime input is private, never a build
// definition. This does not use or replace the ordinary app's stored session.
// Only this test's login/logout may write; domain command dispatch is forbidden.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('LIVE_OPERATIONS_READ_CHECK');
  testWidgets(
    'Azure Home, queues and available owned detail use the native consumer',
    (tester) async {
      if (!Platform.isLinux) {
        throw StateError('This acceptance check targets native Linux.');
      }
      final config = AppConfig.environment();
      if (config.origin != Uri.parse('https://bagooph.shop/api/v1') ||
          config.operationsWritesVerified ||
          config.handoverWritesVerified) {
        throw StateError(
          'Use ordinary Azure HTTPS with domain writes disabled.',
        );
      }
      final path = Platform.environment['BAGOO_LIVE_OPERATIONS_CASE'];
      if (path == null || path.isEmpty) {
        throw StateError('Supply the private operations acceptance case.');
      }
      final caseFile = File(path);
      if (await FileSystemEntity.type(path, followLinks: false) !=
              FileSystemEntityType.file ||
          (await caseFile.stat()).mode & 0x3f != 0 ||
          (await caseFile.parent.stat()).mode & 0x3f != 0) {
        throw StateError(
          'Use a private mode-600 file in a mode-700 directory.',
        );
      }
      late final Map<String, dynamic> info;
      try {
        info = Wire.object(jsonDecode(await caseFile.readAsString()));
      } on FormatException {
        // JSON parser errors can quote the private input. Never surface them.
        throw StateError('The private acceptance case could not be decoded.');
      }
      final expectedAccount = Wire.id(info['account_id']);
      final audit = _PrivacyAudit();
      final dio = Dio()..interceptors.add(audit);
      final auth = ApiAuthRepository(config, MemoryTokenStore(), client: dio);
      final report = <String, dynamic>{
        'domain_writes': false,
        'checked_at': DateTime.now().toUtc().toIso8601String(),
      };
      try {
        final account = await auth.login(
          Wire.string(info['email']),
          Wire.string(info['password']),
        );
        if (account.id != expectedAccount ||
            !account.approved ||
            account.operationsApiVersion != 1) {
          throw StateError(
            'The designated approved operations-v1 rider is required.',
          );
        }
        final repo = OperationsRepository(
          auth,
          accountId: account.id,
          journal: _ReadOnlyJournal(),
          writesVerified: false,
          isCurrent: () => true,
        );
        final home = await repo.home();
        if (home.capabilities['home'] != true) {
          throw StateError('Home reading is unavailable for this account.');
        }
        report.addAll({
          'operations_api_version': account.operationsApiVersion,
          'on_duty': home.onDuty,
          'operational': home.operational,
          'can_claim': home.canClaim,
          'claim_denial': home.claimDenial,
          'counts': home.counts,
          'capacity': home.capacity,
          'limits': home.limits,
          'capabilities': home.capabilities,
        });
        var ownedDetails = 0;
        final queues = <String, dynamic>{};
        for (final queue in TaskQueue.values) {
          final page = await repo.taskPage(queue);
          queues[queue.name] = {
            'page': page.page,
            'total': page.total,
            'returned': page.items.length,
            'has_next': page.hasNext,
          };
          if (queue != TaskQueue.available && page.items.isNotEmpty) {
            // Authorization is read again; a list row is not owned-detail proof.
            final detail = await repo.detail(page.items.first.id);
            if (detail.preview || detail.phase != page.items.first.phase) {
              throw StateError(
                'The refreshed owned detail could not be verified.',
              );
            }
            ownedDetails++;
          }
        }
        if (!audit.valid || audit.reads == 0) {
          throw StateError(
            'The native JSON/privacy headers could not be verified.',
          );
        }
        report.addAll({
          'queues': queues,
          'owned_details_verified': ownedDetails,
          'private_json_read_responses': audit.reads,
          'private_no_store_no_cache_nosniff': true,
        });
        final output = File(
          '${caseFile.parent.path}/operations-read-receipt.json',
        );
        await output.create();
        final permissions = await Process.run('chmod', ['600', output.path]);
        if (permissions.exitCode != 0) {
          throw StateError('Could not protect the acceptance receipt.');
        }
        await output.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(report)}\n',
          flush: true,
        );
        debugPrint(
          'Native Azure Home and all three queues decoded; '
          '$ownedDetails owned detail reads verified. No duty or claim sent.',
        );
      } finally {
        try {
          await auth.logout();
        } finally {
          dio.close(force: true);
        }
      }
    },
    skip: !enabled,
  );
}

class _ReadOnlyJournal implements CommandJournal {
  @override
  Future<CommandIntent?> read() async => null;
  @override
  Future<void> write(CommandIntent intent) async =>
      throw StateError('The acceptance check cannot dispatch domain commands.');
  @override
  Future<void> clear() async =>
      throw StateError('The acceptance check cannot clear a command journal.');
}

class _PrivacyAudit extends Interceptor {
  var valid = true;
  var reads = 0;
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.requestOptions.method == 'GET') {
      reads++;
      final cache = (response.headers.value('cache-control') ?? '')
          .toLowerCase()
          .split(',')
          .map((part) => part.trim())
          .toSet();
      valid =
          valid &&
          response.statusCode == 200 &&
          response.headers.value('content-type')?.split(';').first.trim() ==
              'application/json' &&
          cache.containsAll({'private', 'no-store', 'no-cache'}) &&
          response.headers.value('x-content-type-options')?.toLowerCase() ==
              'nosniff';
    }
    handler.next(response);
  }
}
