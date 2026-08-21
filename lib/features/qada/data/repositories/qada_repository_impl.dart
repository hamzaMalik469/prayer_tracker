library;

import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/data/datasources/prayer_tracking_local_datasource.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';
import '../../domain/repositories/qada_repository.dart';
import '../datasources/qada_local_datasource.dart';
import '../datasources/qada_remote_datasource.dart';

final class QadaRepositoryImpl implements QadaRepository {
  const QadaRepositoryImpl({
    required QadaLocalDataSource localDataSource,
    required QadaRemoteDataSource remoteDataSource,
    required PrayerTrackingLocalDataSource prayerLocalDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _prayerLocal = prayerLocalDataSource;

  final QadaLocalDataSource _local;
  final QadaRemoteDataSource _remote;
  final PrayerTrackingLocalDataSource _prayerLocal;

  bool _isGuest(String userId) => GuestUserHelper.isGuestId(userId);

  @override
  Future<QadaSummaryEntity> getQadaSummary({required String userId}) async {
    // Try local first.
    final localSummary = await _local.getSummary(userId: userId);

    // If local has data or is guest, return local.
    if (localSummary.total > 0 || _isGuest(userId)) {
      return localSummary;
    }

    // For authenticated users with empty local — try pulling from remote.
    try {
      final remoteSummary = await _remote.getSummary(userId: userId);
      if (remoteSummary.total > 0) {
        // Cache remote records locally.
        for (final record in remoteSummary.pendingRecords) {
          await _local.addRecord(record);
          await _local.markAsSynced(recordId: record.id);
        }
        for (final record in remoteSummary.completedRecords) {
          await _local.addRecord(record);
          await _local.markAsSynced(recordId: record.id);
        }
        AppLogger.info(
          'Pulled ${remoteSummary.total} Qada records from remote to local.',
          tag: 'QadaRepo',
        );
        return remoteSummary;
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch remote Qada records.',
        error: e,
        tag: 'QadaRepo',
      );
    }

    return localSummary;
  }

  @override
  Stream<QadaSummaryEntity> watchQadaSummary({required String userId}) =>
      _local.watchSummary(userId: userId);

  @override
  Future<QadaRecordEntity> addQadaRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  }) async {
    final now = DateTime.now();
    final qadaId = QadaRecordEntity.buildId(
      userId: userId,
      missedDate: missedDate,
      prayerType: prayerType,
    );

    final record = QadaRecordEntity(
      id: qadaId,
      userId: userId,
      missedDate: missedDate,
      prayerType: prayerType,
      qadaStatus: QadaStatus.pending,
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );

    // 1. Always write to local SQLite first.
    await _local.addRecord(record);

    // 2. Also mark the prayer as missed in local prayer records.
    final prayerRecordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: missedDate,
      prayerType: prayerType,
    );

    final existingPrayer = await _prayerLocal.getPrayerRecord(
      userId: userId,
      recordId: prayerRecordId,
    );

    // Only set to missed if not already completed.
    if (existingPrayer == null || !existingPrayer.status.isCompleted) {
      final prayerRecord = PrayerRecordEntity(
        id: prayerRecordId,
        userId: userId,
        date: missedDate,
        prayerType: prayerType,
        status: PrayerStatus.missed,
        createdAt: existingPrayer?.createdAt ?? now,
        updatedAt: now,
      );
      await _prayerLocal.upsertPrayerRecord(prayerRecord);
    }

    AppLogger.info(
      'Qada added locally: ${prayerType.identifier} '
      'on ${missedDate.year}-${missedDate.month}-${missedDate.day}',
      tag: 'QadaRepo',
    );

    // 3. Sync to Firestore if not guest.
    if (!_isGuest(userId)) {
      try {
        await _remote.addRecord(
          userId: userId,
          missedDate: missedDate,
          prayerType: prayerType,
          notes: notes,
        );
        await _local.markAsSynced(recordId: qadaId);
      } catch (e) {
        AppLogger.warning(
          'Remote Qada add failed — queued for sync.',
          error: e,
          tag: 'QadaRepo',
        );
      }
    }

    return record;
  }

  @override
  Future<QadaRecordEntity> completeQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) async {
    final now = DateTime.now();
    final summary = await _local.getSummary(userId: userId);

    // Find the pending record locally.
    QadaRecordEntity? existing;
    for (final r in summary.pendingRecords) {
      if (r.id == qadaRecordId) {
        existing = r;
        break;
      }
    }

    if (existing == null) {
      throw Exception('Qada record not found locally: $qadaRecordId');
    }

    // 1. Update Qada record locally.
    final updated = existing.copyWith(
      qadaStatus: QadaStatus.completed,
      updatedAt: now,
      completedAt: now,
    );
    await _local.updateRecord(updated);

    // 2. Update prayer record to qadaCompleted locally.
    final prayerRecordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: missedDate,
      prayerType: prayerType,
    );

    final existingPrayer = await _prayerLocal.getPrayerRecord(
      userId: userId,
      recordId: prayerRecordId,
    );

    final prayerRecord = PrayerRecordEntity(
      id: prayerRecordId,
      userId: userId,
      date: missedDate,
      prayerType: prayerType,
      status: PrayerStatus.qadaCompleted,
      createdAt: existingPrayer?.createdAt ?? now,
      updatedAt: now,
    );
    await _prayerLocal.upsertPrayerRecord(prayerRecord);

    AppLogger.info(
      'Qada completed locally: ${prayerType.identifier} '
      'on ${missedDate.year}-${missedDate.month}-${missedDate.day}',
      tag: 'QadaRepo',
    );

    // 3. Sync to Firestore if not guest.
    if (!_isGuest(userId)) {
      try {
        await _remote.completeRecord(
          userId: userId,
          qadaRecordId: qadaRecordId,
          missedDate: missedDate,
          prayerType: prayerType,
        );
        await _local.markAsSynced(recordId: qadaRecordId);
      } catch (e) {
        AppLogger.warning(
          'Remote Qada complete failed — queued for sync.',
          error: e,
          tag: 'QadaRepo',
        );
      }
    }

    return updated;
  }

  @override
  Future<List<QadaRecordEntity>> getQadaRecordsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final summary = await _local.getSummary(userId: userId);
    final day = DateTime(date.year, date.month, date.day);

    return [
      ...summary.pendingRecords,
      ...summary.completedRecords,
    ].where((r) {
      final rd =
          DateTime(r.missedDate.year, r.missedDate.month, r.missedDate.day);
      return rd == day;
    }).toList();
  }

  @override
  Future<void> deleteQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) async {
    // Delete locally.
    await _local.deleteRecord(recordId: qadaRecordId);

    // Revert prayer record to missed locally.
    final prayerRecordId = PrayerRecordEntity.buildId(
      userId: userId,
      date: missedDate,
      prayerType: prayerType,
    );

    final existingPrayer = await _prayerLocal.getPrayerRecord(
      userId: userId,
      recordId: prayerRecordId,
    );

    if (existingPrayer != null &&
        existingPrayer.status == PrayerStatus.qadaCompleted) {
      await _prayerLocal.upsertPrayerRecord(
        existingPrayer.copyWith(
          status: PrayerStatus.missed,
          updatedAt: DateTime.now(),
        ),
      );
    }

    // Delete remotely if not guest.
    if (!_isGuest(userId)) {
      try {
        await _remote.deleteRecord(
          userId: userId,
          qadaRecordId: qadaRecordId,
          missedDate: missedDate,
          prayerType: prayerType,
        );
      } catch (e) {
        AppLogger.warning(
          'Remote Qada delete failed.',
          error: e,
          tag: 'QadaRepo',
        );
      }
    }
  }
}
