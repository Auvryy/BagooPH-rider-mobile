import 'package:dio/dio.dart';

import '../../app/config.dart';
import 'api_failure.dart';
import 'request_budget.dart';

/// Data repositories share the current native session without reading tokens.
abstract interface class RiderSessionApi {
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  });
}

class RiderApiClient {
  RiderApiClient(this.config, {Dio? client}) : _client = client ?? Dio() {
    _client.options.connectTimeout = const Duration(seconds: 15);
  }
  final AppConfig config;
  final Dio _client;
  final NativeRequestBudget _budget = NativeRequestBudget();

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    String? token,
    Map<String, String> headers = const {},
  }) async {
    final relative = Uri.tryParse(path);
    if (relative == null ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasFragment ||
        path.startsWith('/') ||
        relative.pathSegments.any((s) => s == '..' || s == '.')) {
      throw const AccountFailure('The service path could not be verified.');
    }
    for (final entry in headers.entries) {
      if (!['Idempotency-Key', 'X-Request-ID'].contains(entry.key) ||
          !RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$')
              .hasMatch(entry.value)) {
        throw const AccountFailure(
          'The command headers could not be verified.',
        );
      }
    }
    _budget.reserve(method);
    try {
      final response = await _client.request(
        '${config.origin}/$path',
        data: data,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
            ...headers,
          },
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.data is! Map<String, dynamic>) {
        throw AccountFailure(
          'The account service returned an unexpected response.',
          unconfirmed: method != 'GET',
        );
      }
      return response.data as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw AccountFailure(error.message, unconfirmed: method != 'GET');
    } on DioException catch (error) {
      final body = error.response?.data;
      final fields = <String, String>{};
      if (body is Map && body['errors'] is Map) {
        for (final entry in (body['errors'] as Map).entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            fields[entry.key.toString()] = entry.value.first.toString();
          }
        }
      }
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : error.response == null
          ? 'Could not confirm the request. Check your connection and try again.'
          : 'The account request could not be completed.';
      final cooldown = body is Map ? body['cooldown'] : null;
      final retry = cooldown is int
          ? cooldown
          : int.tryParse(error.response?.headers.value('retry-after') ?? '');
      final status = error.response?.statusCode;
      throw AccountFailure(
        message,
        status: status,
        code: body is Map && body['code'] is String
            ? body['code'] as String
            : null,
        requestId:
            body is Map &&
                body['request_id'] is String &&
                RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$')
                    .hasMatch(body['request_id'])
            ? body['request_id'] as String
            : null,
        fields: fields,
        retryAfterSeconds: retry != null && retry >= 0 && retry <= 86400
            ? retry
            : null,
        unconfirmed: method != 'GET' && (status == null || status >= 500),
      );
    }
  }
}
