import 'package:dio/dio.dart';

import '../../app/config.dart';
import 'api_failure.dart';

/// Data repositories share the current native session without reading tokens.
abstract interface class RiderSessionApi {
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
  });
}

class RiderApiClient {
  RiderApiClient(this.config, {Dio? client}) : _client = client ?? Dio() {
    _client.options.connectTimeout = const Duration(seconds: 15);
  }
  final AppConfig config;
  final Dio _client;

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    String? token,
  }) async {
    try {
      final response = await _client.request(
        '${config.origin}/$path',
        data: data,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
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
      throw AccountFailure(error.message);
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
        fields: fields,
        retryAfterSeconds: retry != null && retry >= 0 && retry <= 86400
            ? retry
            : null,
        unconfirmed: method != 'GET' && (status == null || status >= 500),
      );
    }
  }
}
