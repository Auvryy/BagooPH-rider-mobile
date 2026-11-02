// Windowless Wallet client acceptance over the isolated real Laravel kernel.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/prepaid_local_api_scenario.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  test(
    'headless Wallet handoff/replay retains the original recipient and private proof',
    () => runPrepaidLocalApiScenario(
      secureStorageAdapter: 'in-memory test adapter',
    ),
    skip: const String.fromEnvironment('LOCAL_PREPAID_API_BASE').isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
