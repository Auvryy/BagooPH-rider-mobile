import '../../auth/data/account.dart';

bool isSettingsEmailId(String value) =>
    value.length <= 19 &&
    RegExp(r'^[1-9][0-9]*$').stringMatch(value) == value &&
    (value.length < 19 || value.compareTo('9223372036854775807') <= 0);

bool isSettingsRevision(String value) =>
    value.length == 64 && RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

class SettingsIdentity {
  const SettingsIdentity(this.accountId, {this.preview = false});
  final String accountId;
  final bool preview;
  @override
  bool operator ==(Object other) =>
      other is SettingsIdentity &&
      other.accountId == accountId &&
      other.preview == preview;
  @override
  int get hashCode => Object.hash(accountId, preview);
}

class ContactEmail {
  const ContactEmail({
    required this.id,
    required this.email,
    required this.original,
    required this.verified,
    required this.preferred,
  });
  final String id, email;
  final bool original, verified, preferred;
}

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.accountId,
    required this.revision,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.phone,
    required this.canUpdateContact,
    required this.canChangePassword,
    required this.canManageEmails,
    required this.emails,
    required this.managedAvailable,
    this.managed = const {},
  });
  final String accountId, revision, name, email;
  final String? phone;
  final bool emailVerified,
      canUpdateContact,
      canChangePassword,
      canManageEmails;
  final bool managedAvailable;
  final List<ContactEmail> emails;
  final Map<String, String?> managed;

  static const managedLabels = {
    'company': 'Company',
    'hub': 'Bayan Hub',
    'hub_code': 'Hub code',
    'barangay': 'Assigned barangay',
    'vehicle_type': 'Vehicle type',
    'vehicle_model': 'Vehicle model',
    'plate_number': 'Plate number',
    'fleet_status': 'Fleet status',
    'license_number': 'License number',
    'registration_status': 'Registration review',
  };

  /// Backend settings v1 is enabled only when the deployed account advertises it.
  factory SettingsSnapshot.decode(
    Map<String, dynamic> response, {
    required String accountId,
    required String originalEmail,
  }) {
    Never invalid() => throw const AccountFailure(
      'The account settings response could not be verified.',
    );
    Map<String, dynamic> object(Object? value) =>
        value is Map<String, dynamic> ? value : invalid();
    String text(Object? value) =>
        value is String && value.isNotEmpty ? value : invalid();
    bool flag(Object? value) => value is bool ? value : invalid();
    String? optional(Object? value) =>
        value == null || value is String ? value as String? : invalid();
    final data = object(response['data']);
    final profile = object(data['profile']);
    final caps = object(data['capabilities']);
    final details = object(data['managed_details']);
    final owner = text(data['account_id']);
    final email = text(profile['email']);
    final revision = text(data['revision']);
    if (owner != accountId ||
        email != originalEmail ||
        !isSettingsRevision(revision)) {
      invalid();
    }
    if (data['emails'] is! List) invalid();
    final ids = <String>{};
    final emails = <ContactEmail>[];
    for (final entry in data['emails'] as List) {
      final row = object(entry);
      final id = text(row['id']);
      if (!isSettingsEmailId(id) || !ids.add(id)) invalid();
      emails.add(
        ContactEmail(
          id: id,
          email: text(row['email']),
          original: flag(row['is_original']),
          verified: flag(row['verified']),
          preferred: flag(row['preferred']),
        ),
      );
    }
    final original = emails.where((e) => e.original).toList();
    final preferred = emails.where((e) => e.preferred).toList();
    final verified = flag(profile['email_verified']);
    if (original.length != 1 ||
        original.single.email != email ||
        original.single.verified != verified ||
        preferred.length != 1 ||
        (!preferred.single.verified && !preferred.single.original) ||
        emails.length > 6) {
      invalid();
    }
    final available = flag(details['available']);
    if (!profile.containsKey('phone') ||
        (available &&
            managedLabels.keys.any((key) => !details.containsKey(key)))) {
      invalid();
    }
    return SettingsSnapshot(
      accountId: owner,
      revision: revision,
      name: text(profile['name']),
      email: email,
      emailVerified: verified,
      phone: optional(profile['phone']),
      canUpdateContact: flag(caps['update_contact']),
      canChangePassword: flag(caps['change_password']) && verified,
      canManageEmails: flag(caps['manage_emails']),
      emails: List.unmodifiable(emails),
      managedAvailable: available,
      managed: Map.unmodifiable({
        for (final key in managedLabels.keys)
          key: available ? optional(details[key]) : null,
      }),
    );
  }
}

class EmailChallenge {
  const EmailChallenge({required this.cooldown, required this.expiresIn});
  final int cooldown, expiresIn;
}
