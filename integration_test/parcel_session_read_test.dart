import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/core/network/wire.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/home/data/command_journal.dart';
import 'package:bagoo_rider_mobile/features/home/data/operations_repository.dart';
import 'package:bagoo_rider_mobile/features/workspace/data/workspace_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Opt-in, GET-only reuse of the already authorized native session. The scoped
// token is never printed, replaced or revoked. No login or domain write is sent.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('LIVE_PARCEL_SESSION_READ_CHECK');
  testWidgets(
    'authorized saved native session verifies Azure parcel and retained-history reads',
    (tester) async {
      final config = AppConfig.environment();
      final expected = Platform.environment['BAGOO_EXPECTED_RIDER_ID'];
      if (!Platform.isLinux ||
          expected == null ||
          config.origin != Uri.parse('https://bagooph.shop/api/v1') ||
          config.operationsWritesVerified ||
          config.parcelWritesVerified ||
          config.handoverWritesVerified) {
        throw StateError(
          'Use the authorized Linux read-only acceptance profile.',
        );
      }
      Wire.id(expected);
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method != 'GET') {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.cancel,
                  ),
                );
              } else {
                handler.next(options);
              }
            },
          ),
        );
      final auth = ApiAuthRepository(
        config,
        _PreserveStoredSession(SecureTokenStore(apiOrigin: config.origin)),
        client: dio,
      );
      final report = <String, dynamic>{
        'checked_at': DateTime.now().toUtc().toIso8601String(),
        'domain_writes': false,
        'stored_session_changed': false,
        'reads_verified': false,
      };
      try {
        final account = await auth.restore();
        if (account == null) {
          report['reason'] = 'no_valid_saved_session';
          debugPrint(
            'Azure parcel reads were not accepted: no valid saved native session.',
          );
          markTestSkipped(
            'The authorized saved native session is unavailable.',
          );
          return;
        }
        if (account.id != expected ||
            !account.approved ||
            account.operationsApiVersion != 1) {
          report['reason'] = 'designated_approved_v1_session_unavailable';
          debugPrint(
            'Azure parcel reads were not accepted: the designated approved session is unavailable.',
          );
          markTestSkipped(
            'The designated approved version-1 session is unavailable.',
          );
          return;
        }
        final repo = OperationsRepository(
          auth,
          accountId: account.id,
          journal: _NoCommands(),
          writesVerified: false,
          isCurrent: () => true,
        );
        final home = await repo.home();
        report['capabilities'] = home.capabilities;
        final queues = <String, Object>{};
        var details = 0;
        for (final queue in TaskQueue.values) {
          final page = await repo.taskPage(queue);
          queues[queue.name] = {
            'returned': page.items.length,
            'total': page.total,
          };
          if (queue != TaskQueue.available && page.items.isNotEmpty) {
            await repo.detail(page.items.first.id);
            details++;
          }
        }
        report['queues'] = queues;
        report['owned_details_verified'] = details;
        if (home.capabilities['trips'] == true) {
          final trips = await repo.tripPage();
          report['retained_assignments_returned'] = trips.items.length;
          report['retained_assignment_total'] = trips.total;
          if (trips.items.isNotEmpty) {
            final original = await repo.tripDetail(trips.items.first.id);
            report['trip_detail_verified'] = true;
            if (original.proofPaths.isNotEmpty) {
              final proof = await repo.tripProof(
                original.id,
                original.proofPaths.first,
              );
              report['private_proof_verified'] = proof.bytes.isNotEmpty;
            }
          }
        }
        report['reads_verified'] =
            home.capabilities['home'] == true &&
            home.capabilities['parcel_actions'] == true &&
            home.capabilities['trips'] == true;
        expect(
          report['reads_verified'],
          isTrue,
          reason:
              'The deployed parcel/Home/Trips capabilities must be available.',
        );
        debugPrint(
          'Native Azure parcel read result: ${report['reads_verified']}; owned details checked: $details. No domain write sent.',
        );
      } finally {
        await auth.discardSession();
        dio.close(force: true);
        final folder = Directory(
          'build/operations-delivery-verification/private',
        );
        await folder.create(recursive: true);
        final file = File('${folder.path}/azure-session-reads.json');
        await file.create();
        final secured = await Process.run('chmod', ['700', folder.path]);
        final securedFile = await Process.run('chmod', ['600', file.path]);
        if (secured.exitCode != 0 || securedFile.exitCode != 0) {
          throw StateError('Could not protect the private read receipt.');
        }
        await file.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(report)}\n',
          flush: true,
        );
      }
    },
    skip: !enabled,
  );
}

class _PreserveStoredSession implements TokenStore {
  _PreserveStoredSession(this.source);
  final TokenStore source;
  @override
  Future<String?> read() => source.read();
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

class _NoCommands implements CommandJournal {
  @override
  Future<CommandIntent?> read() async => null;
  @override
  Future<void> write(CommandIntent intent) async =>
      throw StateError('Read-only acceptance cannot dispatch commands.');
  @override
  Future<void> clear() async =>
      throw StateError('Read-only acceptance cannot clear commands.');
}
