import 'package:flutter/foundation.dart';

import '../../auth/data/account.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';

/// In-memory example only, installed by the explicit debug workspace route.
class PreviewSettingsRepository implements SettingsRepository {
  PreviewSettingsRepository(this.accountId);
  final String accountId;
  String? _phone = '+639000000000';
  int _revision = 1, _nextId = 2;
  List<ContactEmail> _emails = [
    const ContactEmail(
      id: '1',
      email: 'rider@example.test',
      original: true,
      verified: true,
      preferred: true,
    ),
  ];
  @override
  bool get available => kDebugMode;
  void _guard() {
    if (!available) {
      throw const AccountFailure('Preview settings are unavailable.');
    }
  }

  SettingsSnapshot get _snapshot => SettingsSnapshot(
    accountId: accountId,
    revision: 'preview-settings-$_revision',
    name: 'Demo Rider',
    email: 'rider@example.test',
    emailVerified: true,
    phone: _phone,
    canUpdateContact: true,
    canChangePassword: true,
    canManageEmails: true,
    emails: List.unmodifiable(_emails),
    managedAvailable: true,
    managed: const {
      'company': 'Sample logistics',
      'hub': 'Example Bayan Hub',
      'hub_code': 'DEMO-HUB',
      'barangay': 'Sample district',
      'vehicle_type': 'Motorcycle',
      'vehicle_model': null,
      'plate_number': 'SAMPLE-PLATE',
      'fleet_status': null,
      'license_number': 'SAMPLE-LICENSE',
      'registration_status': null,
    },
  );
  @override
  Future<SettingsSnapshot> read() async {
    _guard();
    return _snapshot;
  }

  @override
  Future<SettingsSnapshot> updatePhone(String? phone, String revision) async {
    _guard();
    if (revision != _snapshot.revision) {
      throw const AccountFailure(
        'Your contact details changed. Refresh before saving.',
        status: 409,
      );
    }
    if (phone != null &&
        !RegExp(r'^(09[0-9]{9}|[+]639[0-9]{9})$').hasMatch(phone)) {
      throw const AccountFailure(
        'Check the mobile number.',
        status: 422,
        fields: {'phone': 'Enter a valid Philippine mobile number.'},
      );
    }
    _phone = phone != null && phone.startsWith('09')
        ? '+63${phone.substring(1)}'
        : phone;
    _revision++;
    return _snapshot;
  }

  @override
  Future<void> changePassword(
    String current,
    String next,
    String confirmation,
  ) async {
    _guard();
    if (current.isEmpty ||
        next.runes.length < 12 ||
        next.runes.length > 128 ||
        next != confirmation) {
      throw const AccountFailure(
        'Check the sample password fields.',
        status: 422,
      );
    }
  }

  @override
  Future<EmailChallenge> sendEmailCode(
    String email,
    String currentPassword,
  ) async {
    _guard();
    if (_emails.any((e) => e.email == email)) {
      throw const AccountFailure(
        'This address already belongs to the sample account.',
        status: 422,
        fields: {'email': 'Choose another sample address.'},
      );
    }
    return const EmailChallenge(cooldown: 2, expiresIn: 600);
  }

  @override
  Future<SettingsSnapshot> confirmEmail(
    String email,
    String currentPassword,
    String code,
  ) async {
    _guard();
    if (code != '123456') {
      throw const AccountFailure(
        'Use the sample code shown in this preview.',
        status: 422,
        fields: {'code': 'The sample code is incorrect.'},
      );
    }
    if (!_emails.any((e) => e.email == email)) {
      if (_emails.length >= 6) {
        throw const AccountFailure(
          'Remove one sample address before adding another.',
          status: 422,
        );
      }
      _emails = [
        ..._emails,
        ContactEmail(
          id: '${_nextId++}',
          email: email,
          original: false,
          verified: true,
          preferred: false,
        ),
      ];
      _revision++;
    }
    return _snapshot;
  }

  @override
  Future<SettingsSnapshot> preferEmail(
    String id,
    String currentPassword,
  ) async {
    _guard();
    _emails = [
      for (final e in _emails)
        ContactEmail(
          id: e.id,
          email: e.email,
          original: e.original,
          verified: e.verified,
          preferred: e.id == id,
        ),
    ];
    _revision++;
    return _snapshot;
  }

  @override
  Future<SettingsSnapshot> removeEmail(
    String id,
    String currentPassword,
  ) async {
    _guard();
    if (_emails.any((e) => e.id == id && e.original)) {
      throw const AccountFailure(
        'The original sample email stays with the account.',
        status: 422,
      );
    }
    final preferred = _emails.any((e) => e.id == id && e.preferred);
    _emails = [
      for (final e in _emails)
        if (e.id != id)
          ContactEmail(
            id: e.id,
            email: e.email,
            original: e.original,
            verified: e.verified,
            preferred: preferred ? e.original : e.preferred,
          ),
    ];
    _revision++;
    return _snapshot;
  }
}
