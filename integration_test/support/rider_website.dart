import 'dart:convert';
import 'dart:io';

import 'package:bagoo_rider_mobile/features/auth/data/account.dart';

/// A real website session, separate from the native bearer being checked.
/// Credentials, cookies and page contents stay in memory and are never logged.
Future<bool> confirmRiderWebsiteAccount(
  Uri api,
  RiderAccount account,
  String password, {
  void Function(String)? report,
  bool checkContact = false,
  String? expectedPhone,
}) async {
  const configured = String.fromEnvironment('RIDER_WEBSITE_URL');
  final website = Uri.parse(
    configured.isEmpty ? 'https://courier.${api.host}' : configured,
  );
  if (api.scheme != 'https' ||
      api.host != 'bagooph.shop' ||
      website.scheme != 'https' ||
      website.host != 'courier.${api.host}' ||
      website.userInfo.isNotEmpty ||
      website.hasQuery ||
      website.hasFragment ||
      !['', '/'].contains(website.path)) {
    throw StateError('Use the reviewed HTTPS Rider website for this check.');
  }

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'Mozilla/5.0';
  final cookies = <String, Cookie>{};
  var signedIn = false;
  var secureRedirect = false;
  var matches = false;
  var signedOut = false;
  String? csrf;

  Future<({int status, String body, String? location})> request(
    String path, {
    Map<String, String>? form,
  }) async {
    final request = await client.openUrl(
      form == null ? 'GET' : 'POST',
      website.resolve(path),
    );
    request.followRedirects = false;
    request.cookies.addAll(cookies.values);
    request.headers.set('Accept', 'text/html');
    if (form != null) {
      request.headers.set('Origin', website.origin);
      request.headers.set('Referer', website.resolve('/login').toString());
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      request.write(Uri(queryParameters: form).query);
    }
    final response = await request.close().timeout(const Duration(seconds: 30));
    for (final cookie in response.cookies) {
      cookies[cookie.name] = cookie;
    }
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 30));
    return (
      status: response.statusCode,
      body: body,
      location: response.headers.value('location'),
    );
  }

  String? pageCsrf(String html) =>
      RegExp('<meta name="csrf-token" content="([^"]+)"')
          .firstMatch(html)
          ?.group(1);

  try {
    final page = await request('/login');
    csrf = pageCsrf(page.body);
    report?.call(
      'Rider website login page: HTTP ${page.status}; CSRF available: ${csrf != null}.',
    );
    if (page.status != 200 || csrf == null) return false;
    final login = await request(
      '/login',
      form: {'_token': csrf, 'email': account.email, 'password': password},
    );
    final destination = website.resolve(login.location ?? '');
    final path = account.approved ? '/deliveries' : '/pending-approval';
    signedIn =
        login.status == 302 &&
        destination.host == website.host &&
        destination.path == path;
    secureRedirect = destination.origin == website.origin;
    report?.call(
      'Rider website sign-in: HTTP ${login.status}; expected destination: ${destination.path == path}.',
    );
    report?.call(
      'Rider website redirect uses HTTPS: ${destination.scheme == 'https'}; expected host: ${destination.host == website.host}.',
    );
    if (!signedIn) return false;

    // Read only the fixed HTTPS page. Never follow a server downgrade redirect.
    final home = await request(path);
    csrf = pageCsrf(home.body) ?? csrf;
    final encoded = RegExp('data-page="([^"]+)"')
        .firstMatch(home.body)
        ?.group(1);
    report?.call(
      'Rider website account page: HTTP ${home.status}; account page available: ${encoded != null}.',
    );
    if (home.status != 200 || encoded == null) return false;
    final data = jsonDecode(
      encoded
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&'),
    ) as Map;
    final user = data['props']['auth']['user'] as Map;
    matches =
        user['id'].toString() == account.id &&
        user['name'] == account.name &&
        user['email'] == account.email &&
        user['role'] == 'courier' &&
        user['status'] == account.status &&
        user['kyc_status'] == account.kycStatus &&
        user['kyc_feedback'] == account.feedback &&
        (user['email_verified_at'] != null) == account.emailVerified;
    report?.call('Rider website/native account fields match: $matches.');
    if (matches && checkContact) {
      final profile = await request('/profile');
      final encodedProfile = RegExp('data-page="([^"]+)"')
          .firstMatch(profile.body)
          ?.group(1);
      if (profile.status != 200 || encodedProfile == null) {
        matches = false;
      } else {
        final page = jsonDecode(
          encodedProfile
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'")
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&'),
        ) as Map;
        final rider = page['props']['rider'];
        matches =
            rider is Map &&
            rider['email'] == account.email &&
            rider['phone'] == expectedPhone;
      }
      report?.call('Rider website/native saved contact matches: $matches.');
    }
  } catch (error) {
    // The caller gets a failed check without exposing a response or credential.
    matches = false;
    report?.call('Rider website check failed: ${error.runtimeType}.');
  } finally {
    if (signedIn && csrf != null) {
      try {
        final logout = await request('/logout', form: {'_token': csrf});
        signedOut = logout.status == 302 || logout.status == 303;
        report?.call('Rider website logout: HTTP ${logout.status}.');
      } catch (_) {
        signedOut = false;
      }
    }
    client.close(force: true);
  }
  return matches && signedOut && secureRedirect;
}
