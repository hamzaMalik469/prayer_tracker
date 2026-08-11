library;

import '../../domain/entities/onboarding_state_entity.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

final class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl({
    required OnboardingLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final OnboardingLocalDataSource _dataSource;

  @override
  Future<OnboardingStateEntity> getOnboardingState() async {
    final completed = await _dataSource.isOnboardingCompleted();
    return OnboardingStateEntity(
      isCompleted: completed,
      hasSelectedCalculationMethod: completed,
      hasSelectedMadhab: completed,
      hasConfiguredLocation: completed,
      hasGrantedNotificationPermission: false,
    );
  }

  @override
  Future<void> completeOnboarding() => _dataSource.setOnboardingCompleted();

  @override
  Future<bool> isOnboardingCompleted() => _dataSource.isOnboardingCompleted();
}
