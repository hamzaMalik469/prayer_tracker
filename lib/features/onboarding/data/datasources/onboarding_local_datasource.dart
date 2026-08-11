library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

abstract interface class OnboardingLocalDataSource {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();
}

final class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;

  @override
  Future<bool> isOnboardingCompleted() async =>
      _prefs.getBool(PreferenceKeys.onboardingCompleted) ?? false;

  @override
  Future<void> setOnboardingCompleted() async =>
      _prefs.setBool(PreferenceKeys.onboardingCompleted, true);
}
