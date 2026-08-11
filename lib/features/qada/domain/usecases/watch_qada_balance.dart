library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/qada_balance_entity.dart';
import '../repositories/qada_repository.dart';

final class WatchQadaBalance
    implements StreamUseCase<QadaBalanceEntity, WatchQadaBalanceParams> {
  const WatchQadaBalance(this._repository);

  final QadaRepository _repository;

  @override
  Stream<QadaBalanceEntity> call(WatchQadaBalanceParams params) =>
      _repository.watchQadaBalance(userId: params.userId);
}

final class WatchQadaBalanceParams extends Equatable {
  const WatchQadaBalanceParams({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
