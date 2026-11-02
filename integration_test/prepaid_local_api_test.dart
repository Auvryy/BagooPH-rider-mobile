// Native Linux acceptance uses the shared real Laravel scenario with the
// platform secure-storage plugin. Run through the isolated prepaid runner.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/prepaid_local_api_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native Wallet handoff/replay retains the original recipient and private proof',
    (tester) =>
        runPrepaidLocalApiScenario(secureStorageAdapter: 'platform plugin'),
    skip: const String.fromEnvironment('LOCAL_PREPAID_API_BASE').isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
