library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

final class DeleteAccount implements NoParamsUseCase<void> {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call() => _repository.deleteAccount();
}
