library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

final class SendPasswordReset
    implements UseCase<void, SendPasswordResetParams> {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(SendPasswordResetParams params) =>
      _repository.sendPasswordResetEmail(email: params.email);
}

final class SendPasswordResetParams extends Equatable {
  const SendPasswordResetParams({required this.email});

  final String email;

  @override
  List<Object> get props => [email];
}
