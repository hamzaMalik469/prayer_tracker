library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/daily_prayer_summary_entity.dart';
import '../repositories/prayer_tracking_repository.dart';

final class GetSummariesForRange
    implements
        UseCase<List<DailyPrayerSummaryEntity>, GetSummariesForRangeParams> {
  const GetSummariesForRange(this._repository);

  final PrayerTrackingRepository _repository;

  @override
  Future<List<DailyPrayerSummaryEntity>> call(
    GetSummariesForRangeParams params,
  ) =>
      _repository.getSummariesForRange(
        userId: params.userId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
}

final class GetSummariesForRangeParams extends Equatable {
  const GetSummariesForRangeParams({
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
