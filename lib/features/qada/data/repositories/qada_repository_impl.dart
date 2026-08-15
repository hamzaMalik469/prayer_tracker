/// Local-first Qada repository.
library;

import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';
import '../../domain/repositories/qada_repository.dart';
import '../datasources/qada_local_datasource.dart';
import '../datasources/qada_remote_datasource.dart';

final class QadaRepositoryImpl implements QadaRepository {
  const QadaRepositoryImpl({
    required QadaLocalDataSource localDataSource,
    required QadaRemoteDataSource remoteDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource;

  final QadaLocalDataSource _local;
  final QadaRemoteDataSource _remote;

  bool _isGuest(String userId) => GuestUserHelper.isGuestId(userId);

  @override
  Future<QadaSummaryEntity> getQadaSummary({required String userId}) =>
      _local.getSummary(userId: userId);

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

    // Always write locally.
    await _local.addRecord(record);

    // Sync to Firestore if not guest.
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

    QadaRecordEntity? existing;
    try {
      existing = summary.pendingRecords.firstWhere(
        (r) => r.id == qadaRecordId,
      );
    } catch (_) {
      existing = null;
    }

    if (existing == null) {
      throw Exception('Qada record not found locally: $qadaRecordId');
    }

    final updated = existing.copyWith(
      qadaStatus: QadaStatus.completed,
      updatedAt: now,
      completedAt: now,
    );

    // Update locally.
    await _local.updateRecord(updated);

    // Sync to Firestore if not guest.
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
    final dateStr = '${date.year}-${date.month}-${date.day}';

    return [
      ...summary.pendingRecords,
      ...summary.completedRecords,
    ].where((r) {
      final rStr =
          '${r.missedDate.year}-${r.missedDate.month}-${r.missedDate.day}';
      return rStr == dateStr;
    }).toList();
  }

  @override
  Future<void> deleteQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) async {
    await _local.deleteRecord(recordId: qadaRecordId);

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
