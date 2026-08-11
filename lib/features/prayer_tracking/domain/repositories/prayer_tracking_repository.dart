library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/daily_prayer_summary_entity.dart';
import '../entities/prayer_record_entity.dart';

abstract interface class PrayerTrackingRepository {
  /// Returns the prayer record for a specific prayer on a specific day.
  /// Returns null if no record exists.
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
  });

  /// Returns the daily summary for [date].
  Future<DailyPrayerSummaryEntity> getDailySummary({
    required String userId,
    required DateTime date,
  });

  /// Returns summaries for a range of dates.
  Future<List<DailyPrayerSummaryEntity>> getSummariesForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Records or updates a prayer status.
  Future<PrayerRecordEntity> recordPrayer({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
    required PrayerStatus status,
  });

  /// Watches the daily summary for [date] in real time.
  Stream<DailyPrayerSummaryEntity> watchDailySummary({
    required String userId,
    required DateTime date,
  });
}
