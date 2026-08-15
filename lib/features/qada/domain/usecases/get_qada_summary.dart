library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/qada_summary_entity.dart';
import '../repositories/qada_repository.dart';

final class GetQadaSummary
    implements UseCase<QadaSummaryEntity, GetQadaSummaryParams> {
  const GetQadaSummary(this._repository);
  final QadaRepository _repository;

  @override
  Future<QadaSummaryEntity> call(GetQadaSummaryParams params) =>
      _repository.getQadaSummary(userId: params.userId);
}

final class GetQadaSummaryParams extends Equatable {
  const GetQadaSummaryParams({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}
