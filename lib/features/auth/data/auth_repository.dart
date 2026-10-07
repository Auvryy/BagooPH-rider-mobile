import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';

import '../../../app/config.dart';
import '../../../core/security/token_store.dart';
import 'account.dart';

abstract interface class AuthRepository {
  Future<RiderAccount?> restore();
  Future<RiderAccount> login(String email, String password);
  Future<RiderAccount> register(
    Map<String, String> fields,
    Map<String, XFile> files,
  );
  Future<RiderAccount> refresh();
  Future<void> logout();
  Future<void> sendCode(String email);
  Future<String> verifyCode(String email, String code);
  Future<Map<String, dynamic>> registrationOptions();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.config, this.store, {Dio? client})
    : _client = client ?? Dio() {
    _client.options.connectTimeout = const Duration(seconds: 15);
  }
  final AppConfig config;
  final TokenStore store;
  final Dio _client;
  String? _token;

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? data,
    String? token,
  }) async {
    try {
      final base = config.origin;
      final response = await _client.request(
        '${base.toString()}/$path',
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
        throw const AccountFailure(
          'The account service returned an unexpected response.',
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
      throw AccountFailure(
        message,
        status: error.response?.statusCode,
        fields: fields,
      );
    }
  }

  Future<RiderAccount> _accept(Map<String, dynamic> response) async {
    final data = response['data'] as Map<String, dynamic>;
    RiderAccount.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const AccountFailure('The session response could not be verified.');
    }
    try {
      await store.write(token);
    } catch (_) {
      try {
        await _request('auth/tokens/current', method: 'DELETE', token: token);
      } catch (_) {}
      throw const AccountFailure(
        'Secure session storage is unavailable. Please try again after it is available.',
      );
    }
    _token = token;
    try {
      return await refresh();
    } on AccountFailure catch (error) {
      if (error.invalidSession) {
        await store.clear();
        _token = null;
      }
      rethrow;
    }
  }

  @override
  Future<RiderAccount> login(String email, String password) async => _accept(
    await _request(
      'auth/tokens',
      method: 'POST',
      data: {
        'email': email.trim(),
        'password': password,
        'device_name': 'BagooPH Rider',
      },
    ),
  );
  @override
  Future<RiderAccount> register(
    Map<String, String> fields,
    Map<String, XFile> files,
  ) async {
    final data = FormData.fromMap({...fields, 'device_name': 'BagooPH Rider'});
    for (final entry in files.entries) {
      final file = entry.value;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const AccountFailure('Choose documents up to 5 MB each.');
      }
      data.files.add(
        MapEntry(
          entry.key,
          MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          ),
        ),
      );
    }
    return _accept(
      await _request('rider/applications', method: 'POST', data: data),
    );
  }

  @override
  Future<RiderAccount?> restore() async {
    try {
      _token = await store.read();
    } catch (_) {
      throw const AccountFailure('Secure session storage is unavailable.');
    }
    if (_token == null) return null;
    try {
      return await refresh();
    } on AccountFailure catch (error) {
      if (error.invalidSession) {
        await store.clear();
        _token = null;
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<RiderAccount> refresh() async {
    if (_token == null) {
      throw const AccountFailure('Please sign in again.', status: 401);
    }
    final result = await _request('rider/me', token: _token);
    return RiderAccount.fromJson(result['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    if (_token != null) {
      try {
        await _request('auth/tokens/current', method: 'DELETE', token: _token);
      } on AccountFailure catch (error) {
        if (!error.invalidSession) rethrow;
      }
    }
    await store.clear();
    _token = null;
  }

  @override
  Future<void> sendCode(String email) async {
    final result = await _request(
      'rider/registration/email/send',
      method: 'POST',
      data: {'email': email.trim()},
    );
    if (result['success'] != true) {
      throw const AccountFailure(
        'The verification code was not sent. Try again.',
      );
    }
  }

  @override
  Future<String> verifyCode(String email, String code) async {
    final result = await _request(
      'rider/registration/email/verify',
      method: 'POST',
      data: {'email': email.trim(), 'code': code.trim()},
    );
    if (result['success'] != true || result['token'] is! String) {
      throw const AccountFailure(
        'Your email verification could not be confirmed.',
      );
    }
    return result['token'] as String;
  }

  @override
  Future<Map<String, dynamic>> registrationOptions() async =>
      (await _request('rider/registration/options'))['data']
          as Map<String, dynamic>;
}
