library;

import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

final class GetCurrentUser implements NoParamsUseCase<UserEntity?> {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<UserEntity?> call() => _repository.getCurrentUser();
}
