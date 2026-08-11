library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/qada_balance_entity.dart';
import '../repositories/qada_repository.dart';

final class GetQadaBalance
    implements UseCase<QadaBalanceEntity, GetQadaBalanceParams> {
  const GetQadaBalance(this._repository);

  final QadaRepository _repository;

  @override
  Future<QadaBalanceEntity> call(GetQadaBalanceParams params) =>
      _repository.getQadaBalance(userId: params.userId);
}

final class GetQadaBalanceParams extends Equatable {
  const GetQadaBalanceParams({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
