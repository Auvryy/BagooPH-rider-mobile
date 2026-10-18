import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../app/config.dart';
import 'api_failure.dart';
import 'request_budget.dart';
import 'wire.dart';

/// Data repositories share the current native session without reading tokens.
abstract interface class RiderSessionApi {
  Future<Map<String, dynamic>> authenticatedRequest(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, String> headers = const {},
  });
}

abstract interface class RiderEvidenceSessionApi {
  Future<PrivateApiBytes> authenticatedEvidence(String path);
}

class PrivateApiBytes {
  PrivateApiBytes(Uint8List bytes, this.mimeType, {this.requestId})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final Uint8List bytes;
  final String mimeType;
  final String? requestId;
}

class RiderApiClient {
  RiderApiClient(this.config, {Dio? client}) : _client = client ?? Dio() {
    _client.options.connectTimeout = const Duration(seconds: 15);
  }
  final AppConfig config;
  final Dio _client;
  final NativeRequestBudget _budget = NativeRequestBudget();

  /// A bounded first-party download. JSON errors are decoded before any viewer
  /// sees bytes; redirects, foreign paths and public-storage URLs are rejected.
  Future<PrivateApiBytes> evidence(String path, {required String token}) async {
    final handover = RegExp(r'^rider/handover-issues/([1-9][0-9]*)/evidence$')
        .firstMatch(path);
    final trip = RegExp(
      r'^rider/trips/trip-([1-9][0-9]*)/(checkpoints|attempts)/([1-9][0-9]*)/proof$',
    ).firstMatch(path);
    if ((handover == null || handover.end != path.length) &&
        (trip == null || trip.end != path.length)) {
      throw const AccountFailure('The evidence path could not be verified.');
    }
    if (handover != null) Wire.id(handover[1]);
    if (trip != null) {
      Wire.id(trip[1]);
      Wire.id(trip[3]);
    }
    _budget.reserve('GET');
    try {
      final response = await _client.get<ResponseBody>(
        '${config.origin}/$path',
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final mime = response.headers
          .value('content-type')
          ?.split(';')
          .first
          .trim();
      if (mime == 'application/json') {
        final data = jsonDecode(
          utf8.decode(await _bounded(response.data!, 65536)),
        );
        throw _responseFailure(
          data,
          response.statusCode,
          response.headers,
          'GET',
        );
      }
      final cache =
          response.headers.value('cache-control')?.toLowerCase() ?? '';
      if (![
            'image/jpeg',
            'image/png',
            'image/webp',
            if (handover != null) 'application/pdf',
          ].contains(mime) ||
          !cache.split(',').map((s) => s.trim()).contains('private') ||
          !cache.split(',').map((s) => s.trim()).contains('no-store') ||
          response.headers.value('x-content-type-options')?.toLowerCase() !=
              'nosniff') {
        throw const AccountFailure(
          'The private evidence response could not be verified.',
        );
      }
      final bytes = await _bounded(response.data!, 5242880);
      if (bytes.isEmpty) {
        throw const AccountFailure('The evidence document is unavailable.');
      }
      final requestId = response.headers.value('x-request-id');
      return PrivateApiBytes(
        bytes,
        mime!,
        requestId: _safeRequestId(requestId),
      );
    } on DioException catch (error) {
      Object? data = error.response?.data;
      if (data is ResponseBody) {
        try {
          data = jsonDecode(utf8.decode(await _bounded(data, 65536)));
        } catch (_) {
          data = null;
        }
      }
      throw _responseFailure(
        data,
        error.response?.statusCode,
        error.response?.headers,
        'GET',
      );
    } on FormatException {
      throw const AccountFailure(
        'The private evidence response could not be verified.',
      );
    }
  }

  Future<Uint8List> _bounded(ResponseBody body, int limit) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      if (builder.length + chunk.length > limit) {
        throw const AccountFailure(
          'The evidence response exceeds its allowed size.',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  String? _safeRequestId(Object? value) =>
      value is String &&
          RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$')
              .hasMatch(value)
      ? value
      : null;

  AccountFailure _responseFailure(
    Object? body,
    int? status,
    Headers? headers,
    String method,
  ) {
    final fields = <String, String>{};
    if (body is Map && body['errors'] is Map) {
      for (final entry in (body['errors'] as Map).entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          fields[entry.key.toString()] = entry.value.first.toString();
        }
      }
    }
    final cooldown = body is Map ? body['cooldown'] : null;
    final retry = cooldown is int
        ? cooldown
        : int.tryParse(headers?.value('retry-after') ?? '');
    if (status == 429 && retry != null) _budget.defer(retry);
    return AccountFailure(
      body is Map && body['message'] is String
          ? body['message'] as String
          : status == null
          ? 'Could not confirm the request. Check your connection and try again.'
          : 'The account request could not be completed.',
      status: status,
      code: body is Map && body['code'] is String
          ? body['code'] as String
          : null,
      requestId: _safeRequestId(body is Map ? body['request_id'] : null),
      fields: fields,
      retryAfterSeconds: retry != null && retry >= 0 && retry <= 86400
          ? retry
          : null,
      unconfirmed: method != 'GET' && (status == null || status >= 500),
    );
  }

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
      throw _responseFailure(
        error.response?.data,
        error.response?.statusCode,
        error.response?.headers,
        method,
      );
    }
  }
}
