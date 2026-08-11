library;

import '../entities/onboarding_state_entity.dart';

abstract interface class OnboardingRepository {
  /// Returns the current onboarding state from local storage.
  Future<OnboardingStateEntity> getOnboardingState();

  /// Persists the completed onboarding state.
  Future<void> completeOnboarding();

  /// Returns true when the user has previously completed onboarding.
  Future<bool> isOnboardingCompleted();
}
