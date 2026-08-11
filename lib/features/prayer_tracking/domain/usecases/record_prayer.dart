library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/prayer_record_entity.dart';
import '../repositories/prayer_tracking_repository.dart';

final class RecordPrayer
    implements UseCase<PrayerRecordEntity, RecordPrayerParams> {
  const RecordPrayer(this._repository);

  final PrayerTrackingRepository _repository;

  @override
  Future<PrayerRecordEntity> call(RecordPrayerParams params) =>
      _repository.recordPrayer(
        userId: params.userId,
        date: params.date,
        prayerType: params.prayerType,
        status: params.status,
      );
}

final class RecordPrayerParams extends Equatable {
  const RecordPrayerParams({
    required this.userId,
    required this.date,
    required this.prayerType,
    required this.status,
  });

  final String userId;
  final DateTime date;
  final PrayerType prayerType;
  final PrayerStatus status;

  @override
  List<Object> get props => [userId, date, prayerType, status];
}
