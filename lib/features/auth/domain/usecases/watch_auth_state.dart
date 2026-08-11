library;

import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

final class WatchAuthState implements NoParamsStreamUseCase<UserEntity?> {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  @override
  Stream<UserEntity?> call() => _repository.watchAuthState();
}
