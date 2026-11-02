import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const explicitApi = bool.hasEnvironment('API_BASE_URL');
  test(
    'launches use Azure even when historical preview flags are supplied',
    () {
      final config = AppConfig.environment();
      expect(config.origin.toString(), 'https://bagooph.shop/api/v1');
      expect(config.websiteOrigin?.origin, 'https://courier.bagooph.shop');
      expect(config.ephemeralLocalSession, isFalse);
    },
    skip: explicitApi,
  );

  test('explicit API configuration preserves environment isolation', () {
    const api = String.fromEnvironment('API_BASE_URL');
    final config = AppConfig.environment();
    expect(config.apiBase, api);
    if (api.isEmpty) {
      expect(() => config.origin, throwsFormatException);
    } else {
      expect(config.origin.toString(), api);
    }
    if (api != 'https://bagooph.shop/api/v1' &&
        !const bool.hasEnvironment('RIDER_WEBSITE_URL')) {
      expect(config.websiteOrigin, isNull);
    }
  }, skip: !explicitApi);

  test('rejects unsafe or malformed API origins', () {
    for (final origin in [
      'http://example.test/api/v1',
      'http://localhost.example.test/api/v1',
      'http://127.0.0.2/api/v1',
      'https://user@example.test/api/v1',
      'https://example.test/api/v1?token=example',
      'https://example.test/api/v1#fragment',
      'https://example.test/api/v2',
    ]) {
      expect(
        () => AppConfig(origin, localAuth: true).origin,
        throwsFormatException,
        reason: origin,
      );
    }
  });

  test('loopback HTTP requires explicit local authentication', () {
    for (final host in ['localhost', '127.0.0.1', '10.0.2.2']) {
      final origin = 'http://$host:8000/api/v1';
      expect(() => AppConfig(origin).origin, throwsFormatException);
      expect(AppConfig(origin, localAuth: true).origin.toString(), origin);
    }
  });
}
