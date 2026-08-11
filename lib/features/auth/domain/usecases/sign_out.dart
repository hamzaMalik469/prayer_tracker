library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

final class SignOut implements NoParamsUseCase<void> {
  const SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call() => _repository.signOut();
}
