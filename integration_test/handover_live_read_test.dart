import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_repository.dart';
import 'package:bagoo_rider_mobile/features/handover/data/handover_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Reuse the public existing Rider seed from azure_account_test.dart. This
// opt-in read check creates no actor, parcel, report or custody event. It uses
// a separate in-memory token and never replaces the user's stored session.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('LIVE_HANDOVER_READ_CHECK');
  testWidgets(
    'Azure handover discovery and involved reads decode in the native client',
    (tester) async {
      final config = AppConfig.environment();
      if (config.origin.scheme != 'https' ||
          config.origin.host != 'bagooph.shop') {
        throw StateError('Use the reviewed Azure HTTPS configuration.');
      }
      final auth = ApiAuthRepository(config, MemoryTokenStore());
      try {
        final account = await auth.login('rider@bagoo.test', 'Password1234');
        expect(account.approved, true);
        expect(account.operationsApiVersion, 1);
        expect(account.handoverApiVersion, 1);
        final repo = HandoverRepository(
          auth,
          accountId: account.id,
          journal: _ReadOnlyJournal(),
          isCurrent: () => true,
          writesVerified: false,
          sessionVersion: account.handoverApiVersion,
        );
        final home = await repo.home();
        expect(repo.canRead(home), true);
        expect(home.capabilities['handover_reporting'], true);
        expect(repo.canWrite(home), false);
        final issues = await repo.list(status: 'all');
        // An empty involved list verifies decoding only. Reporting, holder
        // acknowledgement and actual hub receipt remain separate acceptance.
        if (issues.items.isNotEmpty) {
          final detail = await repo.detail(issues.items.first.id);
          final evidence = await repo.evidence(detail);
          expect(evidence.bytes.isNotEmpty, true);
        }
        debugPrint(
          'Verified native Azure handover discovery; involved issues: ${issues.items.length}. No handover writes performed.',
        );
      } finally {
        await auth.logout();
      }
    },
    skip: !enabled,
  );
}

class _ReadOnlyJournal implements HandoverJournal {
  @override
  Future<HandoverIntent?> read() async => null;
  @override
  Future<void> write(HandoverIntent intent) async =>
      throw StateError('This is a read-only acceptance check.');
  @override
  Future<void> clear() async =>
      throw StateError('This is a read-only acceptance check.');
}
