import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig(
    this.apiBase, {
    this.localAuth = false,
    this.riderWebsite = '',
  });
  final String apiBase;
  final bool localAuth;
  final String riderWebsite;
  factory AppConfig.environment() {
    const deployedApi = 'https://bagooph.shop/api/v1';
    const deployedWebsite = 'https://courier.bagooph.shop';
    // Standalone layout previews must not restore a real account session.
    const layoutPreview =
        kDebugMode &&
        (bool.fromEnvironment('HOME_PREVIEW') ||
            bool.fromEnvironment('WORKSPACE_PREVIEW'));
    const api = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: kIsWeb || layoutPreview ? '' : deployedApi,
    );
    const website = String.fromEnvironment(
      'RIDER_WEBSITE_URL',
      defaultValue: api == deployedApi ? deployedWebsite : '',
    );
    return const AppConfig(
      api,
      localAuth: bool.fromEnvironment('ALLOW_LOCAL_AUTH'),
      riderWebsite: website,
    );
  }
  Uri get origin {
    final uri = Uri.tryParse(apiBase);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.endsWith('/api/v1')) {
      throw const FormatException(
        'The account service is not configured for this build.',
      );
    }
    if (uri.scheme != 'https' &&
        !(kDebugMode &&
            localAuth &&
            uri.scheme == 'http' &&
            ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host))) {
      throw const FormatException(
        'The account service requires a secure connection.',
      );
    }
    return uri;
  }

  bool get ephemeralLocalSession =>
      kDebugMode &&
      localAuth &&
      ['localhost', '127.0.0.1', '10.0.2.2'].contains(origin.host);

  Uri? get websiteOrigin {
    if (riderWebsite.isEmpty) return null;
    final uri = Uri.tryParse(riderWebsite);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['', '/'].contains(uri.path) ||
        uri.host != 'courier.${origin.host}' ||
        uri.port != 443) {
      throw const FormatException(
        'The Rider website address could not be verified.',
      );
    }
    return uri;
  }
}
