import 'package:bagoo_rider_mobile/app/config.dart';
import 'package:bagoo_rider_mobile/features/auth/presentation/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const explicitApi = bool.hasEnvironment('API_BASE_URL');
  const preview =
      bool.fromEnvironment('HOME_PREVIEW') ||
      bool.fromEnvironment('WORKSPACE_PREVIEW');

  test('ordinary native launch connects to the deployed HTTPS account API', () {
    final config = AppConfig.environment();
    expect(config.origin.toString(), 'https://bagooph.shop/api/v1');
    expect(config.websiteOrigin?.origin, 'https://courier.bagooph.shop');
    expect(config.ephemeralLocalSession, isFalse);
  }, skip: kIsWeb || explicitApi || preview);

  test(
    'standalone sample preview cannot restore or persist a live session',
    () async {
      final config = AppConfig.environment();
      expect(config.apiBase, isEmpty);
      expect(() => config.origin, throwsFormatException);
      expect(config.websiteOrigin, isNull);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(tokenStoreProvider);
      expect(await store.read(), isNull);
      await expectLater(store.write('sample-session'), throwsStateError);
    },
    skip: kIsWeb || explicitApi || !preview,
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
