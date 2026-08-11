library;

import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

final class SignInWithGoogle implements NoParamsUseCase<UserEntity> {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<UserEntity> call() => _repository.signInWithGoogle();
}
