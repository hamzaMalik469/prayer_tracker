library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/qada_summary_entity.dart';
import '../repositories/qada_repository.dart';

final class WatchQadaSummary
    implements StreamUseCase<QadaSummaryEntity, WatchQadaSummaryParams> {
  const WatchQadaSummary(this._repository);
  final QadaRepository _repository;

  @override
  Stream<QadaSummaryEntity> call(WatchQadaSummaryParams params) =>
      _repository.watchQadaSummary(userId: params.userId);
}

final class WatchQadaSummaryParams extends Equatable {
  const WatchQadaSummaryParams({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}
