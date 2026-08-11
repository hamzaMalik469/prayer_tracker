library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/daily_prayer_summary_entity.dart';
import '../../domain/entities/prayer_record_entity.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../datasources/prayer_tracking_remote_datasource.dart';

final class PrayerTrackingRepositoryImpl implements PrayerTrackingRepository {
  const PrayerTrackingRepositoryImpl({
    required PrayerTrackingRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  final PrayerTrackingRemoteDataSource _remote;

  @override
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
  }) {
    final recordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: date,
      prayerType: prayerType,
    );
    return _remote.getPrayerRecord(userId: userId, recordId: recordId);
  }

  @override
  Future<DailyPrayerSummaryEntity> getDailySummary({
    required String userId,
    required DateTime date,
  }) async {
    final records = await _remote.getPrayerRecordsForDate(
      userId: userId,
      date: date,
    );
    return _buildSummary(date, records);
  }

  @override
  Future<List<DailyPrayerSummaryEntity>> getSummariesForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await _remote.getPrayerRecordsForRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
    return _groupByDate(startDate, endDate, records);
  }

  @override
  Future<PrayerRecordEntity> recordPrayer({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
    required PrayerStatus status,
  }) =>
      _remote.upsertPrayerRecord(
        userId: userId,
        date: date,
        prayerType: prayerType,
        status: status,
      );

  @override
  Stream<DailyPrayerSummaryEntity> watchDailySummary({
    required String userId,
    required DateTime date,
  }) {
    return _remote
        .watchPrayerRecordsForDate(userId: userId, date: date)
        .map((records) => _buildSummary(date, records));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DailyPrayerSummaryEntity _buildSummary(
    DateTime date,
    List<PrayerRecordEntity> records,
  ) {
    final map = <PrayerType, PrayerRecordEntity>{};
    for (final record in records) {
      map[record.prayerType] = record;
    }
    return DailyPrayerSummaryEntity(date: date, records: map);
  }

  List<DailyPrayerSummaryEntity> _groupByDate(
    DateTime startDate,
    DateTime endDate,
    List<PrayerRecordEntity> records,
  ) {
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
      summaries.add(_buildSummary(current, grouped[key] ?? []));
      current = current.add(const Duration(days: 1));
    }

    return summaries;
  }
}
