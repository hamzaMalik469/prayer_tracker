library;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/onboarding_state_entity.dart';
import '../../domain/usecases/check_onboarding_status.dart';
import '../../domain/usecases/complete_onboarding.dart';

final class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    required CheckOnboardingStatus checkOnboardingStatus,
    required CompleteOnboarding completeOnboarding,
  })  : _checkOnboardingStatus = checkOnboardingStatus,
        _completeOnboarding = completeOnboarding;

  final CheckOnboardingStatus _checkOnboardingStatus;
  final CompleteOnboarding _completeOnboarding;

  OnboardingStateEntity _state = const OnboardingStateEntity.initial();
  bool _isLoading = false;
  bool _isChecking = true;

  OnboardingStateEntity get state => _state;
  bool get isLoading => _isLoading;
  bool get isChecking => _isChecking;
  bool get isOnboardingCompleted => _state.isCompleted;

  Future<void> checkStatus() async {
    _isChecking = true;
    notifyListeners();

    try {
      final completed = await _checkOnboardingStatus();
      _state = _state.copyWith(isCompleted: completed);
    } catch (e) {
      AppLogger.error('Failed to check onboarding status', error: e, tag: 'OnboardingProvider');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void markCalculationMethodSelected() {
    _state = _state.copyWith(hasSelectedCalculationMethod: true);
    notifyListeners();
  }

  void markMadhabSelected() {
    _state = _state.copyWith(hasSelectedMadhab: true);
    notifyListeners();
  }

  void markLocationConfigured() {
    _state = _state.copyWith(hasConfiguredLocation: true);
    notifyListeners();
  }

  void markNotificationPermissionHandled() {
    _state = _state.copyWith(hasGrantedNotificationPermission: true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _completeOnboarding();
      _state = _state.copyWith(isCompleted: true);
    } catch (e) {
      AppLogger.error('Failed to complete onboarding', error: e, tag: 'OnboardingProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
