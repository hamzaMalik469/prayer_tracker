library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

final class CheckOnboardingStatus implements NoParamsUseCase<bool> {
  const CheckOnboardingStatus(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<bool> call() => _repository.isOnboardingCompleted();
}