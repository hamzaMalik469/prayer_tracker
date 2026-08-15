/// Local-first prayer tracking repository.
///
/// Write strategy:
///   1. Always write to local SQLite first.
///   2. If authenticated (non-guest) → also write to Firestore.
///   3. On reconnect → SyncService pushes unsynced local records.
library;

import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/daily_prayer_summary_entity.dart';
import '../../domain/entities/prayer_record_entity.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../datasources/prayer_tracking_local_datasource.dart';
import '../datasources/prayer_tracking_remote_datasource.dart';

final class PrayerTrackingRepositoryImpl implements PrayerTrackingRepository {
  const PrayerTrackingRepositoryImpl({
    required PrayerTrackingLocalDataSource localDataSource,
    required PrayerTrackingRemoteDataSource remoteDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource;

  final PrayerTrackingLocalDataSource _local;
  final PrayerTrackingRemoteDataSource _remote;

  bool _isGuest(String userId) => GuestUserHelper.isGuestId(userId);

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
    return _local.getPrayerRecord(userId: userId, recordId: recordId);
  }

  @override
  Future<DailyPrayerSummaryEntity> getDailySummary({
    required String userId,
    required DateTime date,
  }) async {
    final records = await _local.getPrayerRecordsForDate(
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
    final records = await _local.getPrayerRecordsForRange(
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
  }) async {
    final now = DateTime.now();
    final recordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: date,
      prayerType: prayerType,
    );

    // Check if record already exists locally.
    final existing = await _local.getPrayerRecord(
      userId: userId,
      recordId: recordId,
    );

    final record = existing != null
        ? existing.copyWith(status: status, updatedAt: now)
        : PrayerRecordEntity(
            id: recordId,
            userId: userId,
            date: date,
            prayerType: prayerType,
            status: status,
            createdAt: now,
            updatedAt: now,
          );

    // 1. Always write locally first.
    await _local.upsertPrayerRecord(record);

    // 2. Write to Firestore if not a guest user.
    if (!_isGuest(userId)) {
      try {
        await _remote.upsertPrayerRecord(
          userId: userId,
          date: date,
          prayerType: prayerType,
          status: status,
        );
        // Mark as synced if remote write succeeded.
        await _local.markAsSynced(recordId: recordId);
      } catch (e) {
        AppLogger.warning(
          'Remote write failed — record queued for sync.',
          error: e,
          tag: 'PrayerTrackingRepo',
        );
        // Local record remains unsynced — SyncService will retry.
      }
    }

    return record;
  }

  @override
  Stream<DailyPrayerSummaryEntity> watchDailySummary({
    required String userId,
    required DateTime date,
  }) {
    // For guests: watch local SQLite.
    if (_isGuest(userId)) {
      return _local
          .watchPrayerRecordsForDate(userId: userId, date: date)
          .map((records) => _buildSummary(date, records));
    }

    // For authenticated: watch Firestore (has offline persistence).
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
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      grouped.putIfAbsent(key, () => []).add(r);
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
