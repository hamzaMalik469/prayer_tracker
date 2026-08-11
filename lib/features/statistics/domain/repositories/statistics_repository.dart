library;

import '../entities/prayer_statistics_entity.dart';
import '../entities/streak_entity.dart';

abstract interface class StatisticsRepository {
  /// Returns statistics for the given period.
  Future<PrayerStatisticsEntity> getStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Returns the current and longest streak.
  Future<StreakEntity> getStreak({required String userId});

  /// Watches the streak in real time.
  Stream<StreakEntity> watchStreak({required String userId});
}
