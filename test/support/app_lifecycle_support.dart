import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void startRiderTestLifecycleResumed() {
  TestWidgetsFlutterBinding.ensureInitialized().handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
}
