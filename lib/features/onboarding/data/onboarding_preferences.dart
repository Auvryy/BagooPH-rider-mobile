import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingPreferences {
  Future<bool> readSeen();
  Future<void> writeSeen(bool seen);
}

class LocalOnboardingPreferences implements OnboardingPreferences {
  static const key = 'bagoo.rider.onboarding-complete.v1';
  @override
  Future<bool> readSeen() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;
  @override
  Future<void> writeSeen(bool seen) async {
    await (await SharedPreferences.getInstance()).setBool(key, seen);
  }
}
