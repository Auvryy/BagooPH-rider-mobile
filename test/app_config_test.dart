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
}
