export '../../../core/network/api_failure.dart';

class RiderAccount {
  const RiderAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.kycStatus,
    required this.approved,
    required this.emailVerified,
    this.feedback,
    this.settingsApiVersion,
  });
  final String id, name, email, status, kycStatus;
  final bool approved, emailVerified;
  final String? feedback;
  final int? settingsApiVersion;
  factory RiderAccount.fromJson(Map<String, dynamic> json) {
    if (json['role'] != 'courier' ||
        json['id'] is! String ||
        json['name'] is! String ||
        json['email'] is! String ||
        json['status'] is! String ||
        json['kyc_status'] is! String ||
        json['can_access_portal'] is! bool ||
        json['email_verified'] is! bool ||
        !['active', 'pending_approval'].contains(json['status']) ||
        ![
          'approved',
          'verified',
          'pending_approval',
          'rejected',
        ].contains(json['kyc_status']) ||
        !['approved', 'holding'].contains(json['access_state']) ||
        (json['kyc_feedback'] != null && json['kyc_feedback'] is! String) ||
        (json['access_state'] == 'approved') !=
            (json['can_access_portal'] == true)) {
      throw const FormatException(
        'The account response could not be verified.',
      );
    }
    return RiderAccount(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      status: json['status'],
      kycStatus: json['kyc_status'],
      approved:
          json['can_access_portal'] == true &&
          json['access_state'] == 'approved' &&
          json['status'] == 'active' &&
          ['approved', 'verified'].contains(json['kyc_status']),
      emailVerified: json['email_verified'],
      feedback: json['kyc_feedback'],
      settingsApiVersion:
          json['settings_api_version'] is int &&
              json['settings_api_version'] == 1
          ? 1
          : null,
    );
  }
}
