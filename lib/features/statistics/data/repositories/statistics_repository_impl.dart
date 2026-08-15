/// Statistics repository — local-first.
///
/// Reads from local SQLite for both guest and authenticated users.
/// Falls back to Firestore remote data source for authenticated users
/// when local data is empty (fresh install with existing cloud data).
library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/data/datasources/prayer_tracking_local_datasource.dart';
import '../../../prayer_tracking/data/datasources/prayer_tracking_remote_datasource.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/prayer_statistics_entity.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/usecases/calculate_streak.dart';

final class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl({
    required PrayerTrackingLocalDataSource localDataSource,
    required PrayerTrackingRemoteDataSource remoteDataSource,
    required CalculateStreak calculateStreak,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _calculateStreak = calculateStreak;

  final PrayerTrackingLocalDataSource _localDataSource;
  final PrayerTrackingRemoteDataSource _remoteDataSource;
  final CalculateStreak _calculateStreak;

  /// Fetches records local-first.
  /// For guests: always local.
  /// For authenticated: try local first, fall back to remote if empty.
  Future<List<PrayerRecordEntity>> _getRecords({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Always try local first.
    final localRecords = await _localDataSource.getPrayerRecordsForRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    if (localRecords.isNotEmpty) return localRecords;

    // If guest, local is the only source.
    if (GuestUserHelper.isGuestId(userId)) return localRecords;

    // For authenticated users with empty local — try remote.
    try {
      AppLogger.info(
        'Local empty for stats — fetching from remote.',
        tag: 'StatisticsRepo',
      );
      final remoteRecords = await _remoteDataSource.getPrayerRecordsForRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache remote records locally for next time.
      for (final record in remoteRecords) {
        await _localDataSource.upsertPrayerRecord(record);
        await _localDataSource.markAsSynced(recordId: record.id);
      }

      return remoteRecords;
    } catch (e) {
      AppLogger.warning(
        'Remote fetch for stats failed — returning empty.',
        error: e,
        tag: 'StatisticsRepo',
      );
      return [];
    }
  }

  @override
  Future<PrayerStatisticsEntity> getStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await _getRecords(
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

    final records = await _getRecords(
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
    // For guests: watch local via polling.
    if (GuestUserHelper.isGuestId(userId)) {
      return _localDataSource
          .watchPrayerRecordsForDate(userId: userId, date: DateTime.now())
          .asyncMap((_) => getStreak(userId: userId));
    }

    // For authenticated: watch Firestore snapshot.
    final today = DateTime.now();
    return _remoteDataSource
        .watchPrayerRecordsForDate(userId: userId, date: today)
        .asyncMap((_) => getStreak(userId: userId));
  }

  // ── Your exact computation logic — unchanged ──────────────────────────────

  PrayerStatisticsEntity _computeStatistics({
    required List<PrayerRecordEntity> records,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    int totalPrayed = 0;
    int totalMissed = 0;
    int totalLatePrayed = 0;
    int totalQadaPrayed = 0;
    int totalNotRecorded = 0;

    final perPrayerPrayed = <PrayerType, int>{};
    final perPrayerLatePrayed = <PrayerType, int>{};
    final perPrayerMissed = <PrayerType, int>{};
    final perPrayerQada = <PrayerType, int>{};
    final perPrayerDays = <PrayerType, int>{};

    for (final record in records) {
      final type = record.prayerType;
      perPrayerDays[type] = (perPrayerDays[type] ?? 0) + 1;

      switch (record.status) {
        case PrayerStatus.prayedLate:
          totalLatePrayed++;
          perPrayerLatePrayed[type] = (perPrayerLatePrayed[type] ?? 0) + 1;

        case PrayerStatus.prayed:
          totalPrayed++;
          perPrayerPrayed[type] = (perPrayerPrayed[type] ?? 0) + 1;

        case PrayerStatus.missed:
          totalMissed++;
          perPrayerMissed[type] = (perPrayerMissed[type] ?? 0) + 1;

        case PrayerStatus.qadaCompleted:
          totalQadaPrayed++;
          perPrayerQada[type] = (perPrayerQada[type] ?? 0) + 1;

        case PrayerStatus.notRecorded:
          totalNotRecorded++;
      }
    }

    final days = endDate.difference(startDate).inDays + 1;

    final perPrayerConsistency = <PrayerType, PrayerConsistencyEntity>{};
    for (final type in PrayerTypeExtension.obligatory) {
      final prayed = perPrayerPrayed[type] ?? 0;
      final missed = perPrayerMissed[type] ?? 0;
      final qada = perPrayerQada[type] ?? 0;
      final late = perPrayerLatePrayed[type] ?? 0;
      final recorded = perPrayerDays[type] ?? 0;

      perPrayerConsistency[type] = PrayerConsistencyEntity(
        prayerType: type,
        totalDays: days,
        prayedCount: prayed,
        missedCount: missed,
        qadaCount: qada,
        latePrayedCount: late,
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
      totalLatePrayed: totalLatePrayed,
      totalQadaPrayed: totalQadaPrayed,
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
    final grouped = <String, List<PrayerRecordEntity>>{};
    for (final record in records) {
      final key = '${record.date.year}-${record.date.month}-${record.date.day}';
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
