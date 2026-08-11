library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/data/datasources/prayer_tracking_remote_datasource.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../domain/entities/prayer_statistics_entity.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/usecases/calculate_streak.dart';

final class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl({
    required PrayerTrackingRemoteDataSource prayerDataSource,
    required CalculateStreak calculateStreak,
  })  : _prayerDataSource = prayerDataSource,
        _calculateStreak = calculateStreak;

  final PrayerTrackingRemoteDataSource _prayerDataSource;
  final CalculateStreak _calculateStreak;

  @override
  Future<PrayerStatisticsEntity> getStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await _prayerDataSource.getPrayerRecordsForRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return _computeStatistics(
      records: records,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<StreakEntity> getStreak({required String userId}) async {
    final today = DateTime.now();
    final yearAgo = today.subtract(const Duration(days: 365));

    final records = await _prayerDataSource.getPrayerRecordsForRange(
      userId: userId,
      startDate: yearAgo,
      endDate: today,
    );

    final summaries = _groupRecordsIntoDailySummaries(
      records: records,
      startDate: yearAgo,
      endDate: today,
    );

    return _calculateStreak(
      CalculateStreakParams(summaries: summaries, today: today),
    );
  }

  @override
  Stream<StreakEntity> watchStreak({required String userId}) {
    final today = DateTime.now();
    return _prayerDataSource
        .watchPrayerRecordsForDate(userId: userId, date: today)
        .asyncMap((_) => getStreak(userId: userId));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  PrayerStatisticsEntity _computeStatistics({
    required List<PrayerRecordEntity> records,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    int totalPrayed = 0;
    int totalMissed = 0;
    int totalNotRecorded = 0;

    final perPrayerPrayed = <PrayerType, int>{};
    final perPrayerMissed = <PrayerType, int>{};
    final perPrayerDays = <PrayerType, int>{};

    for (final record in records) {
      final type = record.prayerType;
      perPrayerDays[type] = (perPrayerDays[type] ?? 0) + 1;

      if (record.status.isCompleted) {
        totalPrayed++;
        perPrayerPrayed[type] = (perPrayerPrayed[type] ?? 0) + 1;
      } else if (record.status.isMissed) {
        totalMissed++;
        perPrayerMissed[type] = (perPrayerMissed[type] ?? 0) + 1;
      } else {
        totalNotRecorded++;
      }
    }

    final days = endDate.difference(startDate).inDays + 1;

    final perPrayerConsistency = <PrayerType, PrayerConsistencyEntity>{};
    for (final type in PrayerTypeExtension.obligatory) {
      final prayed = perPrayerPrayed[type] ?? 0;
      final missed = perPrayerMissed[type] ?? 0;
      final recorded = perPrayerDays[type] ?? 0;

      perPrayerConsistency[type] = PrayerConsistencyEntity(
        prayerType: type,
        totalDays: days,
        prayedCount: prayed,
        missedCount: missed,
        notRecordedCount: days - recorded,
      );
    }

    // Find most missed prayer.
    PrayerType? mostMissed;
    int maxMissed = 0;
    for (final entry in perPrayerMissed.entries) {
      if (entry.value > maxMissed) {
        maxMissed = entry.value;
        mostMissed = entry.key;
      }
    }

    return PrayerStatisticsEntity(
      periodStart: startDate,
      periodEnd: endDate,
      totalPrayed: totalPrayed,
      totalMissed: totalMissed,
      totalNotRecorded: totalNotRecorded,
      totalDays: days,
      currentStreak: 0,
      longestStreak: 0,
      perPrayerConsistency: perPrayerConsistency,
      bestDay: null,
      mostMissedPrayer: mostMissed,
    );
  }

  List<DailyPrayerSummaryEntity> _groupRecordsIntoDailySummaries({
    required List<PrayerRecordEntity> records,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Group records by date string key.
    final grouped = <String, List<PrayerRecordEntity>>{};
    for (final record in records) {
      final key =
          '${record.date.year}-${record.date.month}-${record.date.day}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final summaries = <DailyPrayerSummaryEntity>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      final key = '${current.year}-${current.month}-${current.day}';
      final dayRecords = grouped[key] ?? [];

      final recordMap = <PrayerType, PrayerRecordEntity>{};
      for (final record in dayRecords) {
        recordMap[record.prayerType] = record;
      }

      summaries.add(
        DailyPrayerSummaryEntity(date: current, records: recordMap),
      );
      current = current.add(const Duration(days: 1));
    }

    return summaries;
  }
}
