import 'dart:async';

import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_models.dart';
import 'package:bagoo_rider_mobile/features/settings/data/settings_repository.dart';

const initialSettingsRevision =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const savedSettingsRevision =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Map<String, dynamic> settingsWire({
  String? phone,
  String revision = initialSettingsRevision,
  bool verified = true,
}) => {
  'data': {
    'account_id': '7',
    'revision': revision,
    'profile': {
      'name': 'Test Rider',
      'email': 'rider@example.com',
      'phone': phone,
      'email_verified': verified,
    },
    'capabilities': {
      'update_contact': true,
      'change_password': true,
      'manage_emails': true,
    },
    'emails': [
      {
        'id': '1',
        'email': 'rider@example.com',
        'is_original': true,
        'verified': verified,
        'preferred': true,
      },
    ],
    'managed_details': {'available': false},
  },
};

SettingsSnapshot decodeSettings(Map<String, dynamic> response) =>
    SettingsSnapshot.decode(
      response,
      accountId: '7',
      originalEmail: 'rider@example.com',
    );

class TestSettingsRepository implements SettingsRepository {
  @override
  bool available = true;
  bool verified = true;
  int phoneCalls = 0,
      passwordCalls = 0,
      sendCalls = 0,
      confirmCalls = 0,
      manageCalls = 0;
  String? phone;
  String revision = initialSettingsRevision;
  AccountFailure? readFailure, mutationFailure;
  Completer<SettingsSnapshot>? pendingPhone;
  Completer<void>? pendingPassword;
  @override
  Future<SettingsSnapshot> read() async {
    if (readFailure != null) throw readFailure!;
    return decodeSettings(
      settingsWire(phone: phone, revision: revision, verified: verified),
    );
  }

  @override
  Future<SettingsSnapshot> updatePhone(String? phone, String revision) async {
    phoneCalls++;
    if (pendingPhone != null) return pendingPhone!.future;
    if (mutationFailure != null) throw mutationFailure!;
    this.phone = phone;
    this.revision = savedSettingsRevision;
    return read();
  }

  @override
  Future<void> changePassword(
    String current,
    String next,
    String confirmation,
  ) async {
    passwordCalls++;
    if (pendingPassword != null) return pendingPassword!.future;
    if (mutationFailure != null) throw mutationFailure!;
  }

  @override
  Future<EmailChallenge> sendEmailCode(
    String email,
    String currentPassword,
  ) async {
    sendCalls++;
    if (mutationFailure != null) throw mutationFailure!;
    return const EmailChallenge(cooldown: 60, expiresIn: 600);
  }

  @override
  Future<SettingsSnapshot> confirmEmail(
    String email,
    String currentPassword,
    String code,
  ) async {
    confirmCalls++;
    if (mutationFailure != null) throw mutationFailure!;
    return read();
  }

  @override
  Future<SettingsSnapshot> preferEmail(
    String id,
    String currentPassword,
  ) async {
    manageCalls++;
    return read();
  }

  @override
  Future<SettingsSnapshot> removeEmail(
    String id,
    String currentPassword,
  ) async {
    manageCalls++;
    return read();
  }
}
