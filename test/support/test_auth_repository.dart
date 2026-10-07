import 'package:bagoo_rider_mobile/features/auth/data/account.dart';
import 'package:bagoo_rider_mobile/features/auth/data/auth_repository.dart';
import 'package:file_selector/file_selector.dart';

class TestAuthRepository implements AuthRepository {
  RiderAccount? account;
  int loginCalls = 0, logoutCalls = 0, registrationCalls = 0;
  AccountFailure? loginFailure;
  static const approved = RiderAccount(
    id: '7',
    name: 'Test Rider',
    email: 'rider@example.com',
    status: 'active',
    kycStatus: 'approved',
    approved: true,
    emailVerified: true,
  );
  @override
  Future<RiderAccount?> restore() async => account;
  @override
  Future<RiderAccount> login(String email, String password) async {
    loginCalls++;
    if (loginFailure != null) throw loginFailure!;
    return account = approved;
  }

  @override
  Future<RiderAccount> register(
    Map<String, String> fields,
    Map<String, XFile> files,
  ) async {
    registrationCalls++;
    return account = RiderAccount(
      id: '8',
      name: fields['name']!,
      email: fields['email']!,
      status: 'pending_approval',
      kycStatus: 'pending_approval',
      approved: false,
      emailVerified: true,
    );
  }

  @override
  Future<RiderAccount> refresh() async => account!;
  @override
  Future<void> logout() async {
    logoutCalls++;
    account = null;
  }

  @override
  Future<void> sendCode(String email) async {}
  @override
  Future<String> verifyCode(String email, String code) async =>
      'test-email-verification';
  @override
  Future<Map<String, dynamic>> registrationOptions() async => {
    'vehicle_types': ['Motorcycle', 'Scooter', 'Sedan / Van'],
  };
}
