import 'package:bagoo_rider_mobile/features/onboarding/data/onboarding_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Account and workspace fixtures model a returning installation. Intro-specific
// tests provide their own preference state, including first-launch failures.
void completedIntroductionFixture() => SharedPreferences.setMockInitialValues({
  LocalOnboardingPreferences.key: true,
});
