library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

final class CompleteOnboarding implements NoParamsUseCase<void> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<void> call() => _repository.completeOnboarding();
}
