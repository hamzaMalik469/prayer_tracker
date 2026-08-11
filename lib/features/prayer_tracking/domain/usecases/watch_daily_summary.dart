library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/daily_prayer_summary_entity.dart';
import '../repositories/prayer_tracking_repository.dart';

final class WatchDailySummary
    implements
        StreamUseCase<DailyPrayerSummaryEntity, WatchDailySummaryParams> {
  const WatchDailySummary(this._repository);

  final PrayerTrackingRepository _repository;

  @override
  Stream<DailyPrayerSummaryEntity> call(WatchDailySummaryParams params) =>
      _repository.watchDailySummary(
        userId: params.userId,
        date: params.date,
      );
}

final class WatchDailySummaryParams extends Equatable {
  const WatchDailySummaryParams({
    required this.userId,
    required this.date,
  });

  final String userId;
  final DateTime date;

  @override
  List<Object> get props => [userId, date];
}
