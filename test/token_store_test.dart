import 'package:bagoo_rider_mobile/core/security/token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};
  setUp(() {
    values.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final key = args['key'] as String;
          switch (call.method) {
            case 'write':
              values[key] = args['value'] as String;
            case 'read':
              return values[key];
            case 'delete':
              values.remove(key);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'secure sessions are isolated by API identity and legacy keys discarded',
    () async {
      final production = SecureTokenStore(
        apiOrigin: Uri.parse('https://bagoo.example.test/api/v1'),
      );
      final staging = SecureTokenStore(
        apiOrigin: Uri.parse('https://staging.example.test/api/v1'),
      );
      values['bagoo_rider_token'] = 'legacy-test-token';
      expect(await staging.read(), isNull);
      expect(values.containsKey('bagoo_rider_token'), isFalse);
      await production.write('production-test-token');
      await staging.write('staging-test-token');
      expect(await production.read(), 'production-test-token');
      expect(await staging.read(), 'staging-test-token');
      await production.clear();
      expect(await production.read(), isNull);
      expect(await staging.read(), 'staging-test-token');
    },
  );
}
