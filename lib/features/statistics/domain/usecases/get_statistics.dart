library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_statistics_entity.dart';
import '../repositories/statistics_repository.dart';

final class GetStatistics
    implements UseCase<PrayerStatisticsEntity, GetStatisticsParams> {
  const GetStatistics(this._repository);

  final StatisticsRepository _repository;

  @override
  Future<PrayerStatisticsEntity> call(GetStatisticsParams params) =>
      _repository.getStatistics(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
}

final class GetStatisticsParams extends Equatable {
  const GetStatisticsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [userId, startDate, endDate];
}
