import '../../../core/network/rider_api_client.dart';
import '../../auth/data/account.dart';
import 'settings_models.dart';

abstract interface class SettingsRepository {
  bool get available;
  Future<SettingsSnapshot> read();
  Future<SettingsSnapshot> updatePhone(String? phone, String revision);
  Future<void> changePassword(String current, String next, String confirmation);
  Future<EmailChallenge> sendEmailCode(String email, String currentPassword);
  Future<SettingsSnapshot> confirmEmail(
    String email,
    String currentPassword,
    String code,
  );
  Future<SettingsSnapshot> preferEmail(String id, String currentPassword);
  Future<SettingsSnapshot> removeEmail(String id, String currentPassword);
}

class UnavailableSettingsRepository implements SettingsRepository {
  const UnavailableSettingsRepository();
  @override
  bool get available => false;
  Never _unavailable() => throw const AccountFailure(
    'Account updates are not connected in the app yet. Use the Rider website.',
  );
  @override
  Future<SettingsSnapshot> read() async => _unavailable();
  @override
  Future<SettingsSnapshot> updatePhone(String? phone, String revision) async =>
      _unavailable();
  @override
  Future<void> changePassword(
    String current,
    String next,
    String confirmation,
  ) async => _unavailable();
  @override
  Future<EmailChallenge> sendEmailCode(
    String email,
    String currentPassword,
  ) async => _unavailable();
  @override
  Future<SettingsSnapshot> confirmEmail(
    String email,
    String currentPassword,
    String code,
  ) async => _unavailable();
  @override
  Future<SettingsSnapshot> preferEmail(
    String id,
    String currentPassword,
  ) async => _unavailable();
  @override
  Future<SettingsSnapshot> removeEmail(
    String id,
    String currentPassword,
  ) async => _unavailable();
}

/// Activated only by the authenticated account's settings_api_version == 1.
/// No proposed endpoint is requested from an account-only deployment.
class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(
    this.api, {
    required this.accountId,
    required this.originalEmail,
  });
  final RiderSessionApi api;
  final String accountId, originalEmail;
  @override
  bool get available => true;
  SettingsSnapshot _decode(
    Map<String, dynamic> response, {
    bool mutation = false,
  }) {
    try {
      return SettingsSnapshot.decode(
        response,
        accountId: accountId,
        originalEmail: originalEmail,
      );
    } on AccountFailure catch (failure) {
      throw AccountFailure(failure.message, unconfirmed: mutation);
    }
  }

  @override
  Future<SettingsSnapshot> read() async =>
      _decode(await api.authenticatedRequest('rider/settings'));
  @override
  Future<SettingsSnapshot> updatePhone(String? phone, String revision) async =>
      _decode(
        await api.authenticatedRequest(
          'rider/settings/profile',
          method: 'PATCH',
          data: {'phone': phone, 'revision': revision},
        ),
        mutation: true,
      );
  @override
  Future<void> changePassword(
    String current,
    String next,
    String confirmation,
  ) async {
    final result = await api.authenticatedRequest(
      'rider/settings/password',
      method: 'PUT',
      data: {
        'current_password': current,
        'password': next,
        'password_confirmation': confirmation,
      },
    );
    final data = result['data'];
    if (data is! Map ||
        data['password_changed'] != true ||
        data['reauthentication_required'] != true) {
      throw const AccountFailure(
        'The password update was not confirmed. Sign in again or use password recovery.',
        unconfirmed: true,
      );
    }
  }

  @override
  Future<EmailChallenge> sendEmailCode(
    String email,
    String currentPassword,
  ) async {
    final result = await api.authenticatedRequest(
      'rider/settings/emails/send',
      method: 'POST',
      data: {'email': email, 'current_password': currentPassword},
    );
    final cooldown = result['cooldown'];
    final expires = result['expires_in'];
    if (result['success'] != true ||
        cooldown is! int ||
        cooldown < 0 ||
        cooldown > 86400 ||
        expires is! int ||
        expires <= 0 ||
        expires > 86400) {
      throw const AccountFailure(
        'The verification request was not confirmed.',
        unconfirmed: true,
      );
    }
    return EmailChallenge(cooldown: cooldown, expiresIn: expires);
  }

  @override
  Future<SettingsSnapshot> confirmEmail(
    String email,
    String currentPassword,
    String code,
  ) async => _decode(
    await api.authenticatedRequest(
      'rider/settings/emails/confirm',
      method: 'POST',
      data: {'email': email, 'current_password': currentPassword, 'code': code},
    ),
    mutation: true,
  );
  String _addressPath(String id) {
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(id)) {
      throw const AccountFailure(
        'Choose an address from your current account.',
      );
    }
    return 'rider/settings/emails/$id';
  }

  @override
  Future<SettingsSnapshot> preferEmail(
    String id,
    String currentPassword,
  ) async => _decode(
    await api.authenticatedRequest(
      '${_addressPath(id)}/preferred',
      method: 'PATCH',
      data: {'current_password': currentPassword},
    ),
    mutation: true,
  );
  @override
  Future<SettingsSnapshot> removeEmail(
    String id,
    String currentPassword,
  ) async => _decode(
    await api.authenticatedRequest(
      _addressPath(id),
      method: 'DELETE',
      data: {'current_password': currentPassword},
    ),
    mutation: true,
  );
}
