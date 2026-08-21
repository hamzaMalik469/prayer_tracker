library;

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

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
  }) async {
    final recordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: date,
      prayerType: prayerType,
    );

    // Try local first.
    final local = await _local.getPrayerRecord(
      userId: userId,
      recordId: recordId,
    );
    if (local != null) return local;

    // For authenticated users — try remote if local is empty.
    if (!_isGuest(userId)) {
      try {
        final remote = await _remote.getPrayerRecord(
          userId: userId,
          recordId: recordId,
        );
        // Cache locally if found.
        if (remote != null) {
          await _local.upsertPrayerRecord(remote);
          await _local.markAsSynced(recordId: recordId);
        }
        return remote;
      } catch (e) {
        AppLogger.warning('Remote getPrayerRecord failed',
            error: e, tag: 'PrayerTrackingRepo');
      }
    }

    return null;
  }

  @override
  Future<DailyPrayerSummaryEntity> getDailySummary({
    required String userId,
    required DateTime date,
  }) async {
    // Always read from local — local is always up-to-date.
    final records = await _local.getPrayerRecordsForDate(
      userId: userId,
      date: date,
    );

    // If local is empty and authenticated — try pulling from remote.
    if (records.isEmpty && !_isGuest(userId)) {
      try {
        final remoteRecords = await _remote.getPrayerRecordsForDate(
          userId: userId,
          date: date,
        );
        if (remoteRecords.isNotEmpty) {
          for (final record in remoteRecords) {
            await _local.upsertPrayerRecord(record);
            await _local.markAsSynced(recordId: record.id);
          }
          return _buildSummary(date, remoteRecords);
        }
      } catch (e) {
        AppLogger.warning('Remote getDailySummary failed',
            error: e, tag: 'PrayerTrackingRepo');
      }
    }

    return _buildSummary(date, records);
  }

  @override
  Future<List<DailyPrayerSummaryEntity>> getSummariesForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Always read from local.
    final records = await _local.getPrayerRecordsForRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    // If local is empty and authenticated — pull from remote.
    if (records.isEmpty && !_isGuest(userId)) {
      try {
        final remoteRecords = await _remote.getPrayerRecordsForRange(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );
        if (remoteRecords.isNotEmpty) {
          for (final record in remoteRecords) {
            await _local.upsertPrayerRecord(record);
            await _local.markAsSynced(recordId: record.id);
          }
          return _groupByDate(startDate, endDate, remoteRecords);
        }
      } catch (e) {
        AppLogger.warning('Remote getSummariesForRange failed',
            error: e, tag: 'PrayerTrackingRepo');
      }
    }

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

    // 1. ALWAYS write locally first — this is instant and never fails.
    await _local.upsertPrayerRecord(record);

    AppLogger.debug(
      'Prayer saved locally: ${prayerType.identifier} → ${status.name}',
      tag: 'PrayerTrackingRepo',
    );

    // 2. Try to sync to Firestore if authenticated + online.
    //    This runs in background — UI already updated from local.
    if (!_isGuest(userId)) {
      _syncToRemote(
        userId: userId,
        date: date,
        prayerType: prayerType,
        status: status,
        recordId: recordId,
      );
    }

    return record;
  }

  /// Fire-and-forget remote sync — does not block the UI.
  Future<void> _syncToRemote({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
    required PrayerStatus status,
    required String recordId,
  }) async {
    try {
      final isOnline = await _hasInternetConnection();
      if (!isOnline) {
        AppLogger.debug(
          'Offline — queued for sync: $recordId',
          tag: 'PrayerTrackingRepo',
        );
        return;
      }

      await _remote.upsertPrayerRecord(
        userId: userId,
        date: date,
        prayerType: prayerType,
        status: status,
      );

      await _local.markAsSynced(recordId: recordId);

      AppLogger.debug(
        'Synced to remote: $recordId',
        tag: 'PrayerTrackingRepo',
      );
    } catch (e) {
      AppLogger.warning(
        'Remote sync failed — will retry later: $recordId',
        error: e,
        tag: 'PrayerTrackingRepo',
      );
      // Record stays unsynced — SyncService will pick it up later.
    }
  }

  /// KEY FIX: Always watch LOCAL database.
  ///
  /// Before: authenticated users watched Firestore (remote).
  /// Problem: recordPrayer writes local first → UI watched remote →
  ///          delay until Firestore confirmed → UI felt laggy or missed updates.
  ///
  /// Now: everyone watches local → instant UI update after recordPrayer.
  @override
  Stream<DailyPrayerSummaryEntity> watchDailySummary({
    required String userId,
    required DateTime date,
  }) {
    return _local
        .watchPrayerRecordsForDate(userId: userId, date: date)
        .map((records) => _buildSummary(date, records));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

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
