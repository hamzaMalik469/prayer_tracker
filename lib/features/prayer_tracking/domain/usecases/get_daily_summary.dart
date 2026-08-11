library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/daily_prayer_summary_entity.dart';
import '../repositories/prayer_tracking_repository.dart';

final class GetDailySummary
    implements UseCase<DailyPrayerSummaryEntity, GetDailySummaryParams> {
  const GetDailySummary(this._repository);

  final PrayerTrackingRepository _repository;

  @override
  Future<DailyPrayerSummaryEntity> call(GetDailySummaryParams params) =>
      _repository.getDailySummary(
        userId: params.userId,
        date: params.date,
      );
}

final class GetDailySummaryParams extends Equatable {
  const GetDailySummaryParams({
    required this.userId,
    required this.date,
  });

  final String userId;
  final DateTime date;

  @override
  List<Object> get props => [userId, date];
}
