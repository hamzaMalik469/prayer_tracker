library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

final class CreateAccount implements UseCase<UserEntity, CreateAccountParams> {
  const CreateAccount(this._repository);

  final AuthRepository _repository;

  @override
  Future<UserEntity> call(CreateAccountParams params) =>
      _repository.createAccountWithEmailAndPassword(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
}

final class CreateAccountParams extends Equatable {
  const CreateAccountParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}
