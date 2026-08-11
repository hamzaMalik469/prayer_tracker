library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/streak_entity.dart';
import '../repositories/statistics_repository.dart';

final class GetStreak implements UseCase<StreakEntity, GetStreakParams> {
  const GetStreak(this._repository);

  final StatisticsRepository _repository;

  @override
  Future<StreakEntity> call(GetStreakParams params) =>
      _repository.getStreak(userId: params.userId);
}

final class GetStreakParams extends Equatable {
  const GetStreakParams({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
