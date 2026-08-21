/// Local SQLite data source for Qada records.
library;

import 'package:prayers_tracker_plus/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../../core/extensions/date_time_extensions.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/services/local_database_service.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';

abstract interface class QadaLocalDataSource {
  Future<QadaSummaryEntity> getSummary({required String userId});
  Future<QadaRecordEntity> addRecord(QadaRecordEntity record);
  Future<QadaRecordEntity> updateRecord(QadaRecordEntity record);
  Future<void> deleteRecord({required String recordId});
  Future<List<QadaRecordEntity>> getUnsyncedRecords({required String userId});
  Future<void> markAsSynced({required String recordId});
  Stream<QadaSummaryEntity> watchSummary({required String userId});
}

final class QadaLocalDataSourceImpl implements QadaLocalDataSource {
  const QadaLocalDataSourceImpl();

  Future<Database> get _db => LocalDatabaseService.database;

  @override
  Future<QadaSummaryEntity> getSummary({required String userId}) async {
    final db = await _db;
    final rows = await db.query(
      'qada_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    final pending = <QadaRecordEntity>[];
    final completed = <QadaRecordEntity>[];

    for (final row in rows) {
      final record = _fromRow(row);
      if (record == null) continue;
      if (record.isPending) {
        pending.add(record);
      } else {
        completed.add(record);
      }
    }

    return QadaSummaryEntity(
      pendingRecords: pending,
      completedRecords: completed,
    );
  }

  @override
  Future<QadaRecordEntity> addRecord(QadaRecordEntity record) async {
    final db = await _db;
    await db.insert(
      'qada_records',
      _toRow(record, synced: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.debug(
      'Local Qada add: ${record.prayerType.identifier} '
      '${record.missedDate.toLocalDateString()}',
      tag: 'QadaLocalDS',
    );
    return record;
  }

  @override
  Future<QadaRecordEntity> updateRecord(QadaRecordEntity record) async {
    final db = await _db;
    await db.update(
      'qada_records',
      _toRow(record, synced: false),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
  }

  @override
  Future<void> deleteRecord({required String recordId}) async {
    final db = await _db;
    await db.delete(
      'qada_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  @override
  Future<List<QadaRecordEntity>> getUnsyncedRecords({
    required String userId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'qada_records',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
    );
    return rows.map(_fromRow).whereType<QadaRecordEntity>().toList();
  }

  @override
  Future<void> markAsSynced({required String recordId}) async {
    final db = await _db;
    await db.update(
      'qada_records',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  @override
  Stream<QadaSummaryEntity> watchSummary({required String userId}) {
    // Use a shorter polling interval for better UX.
    // ignore: inference_failure_on_instance_creation
    return Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) => getSummary(userId: userId))
        .distinct();
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(
    QadaRecordEntity e, {
    required bool synced,
  }) =>
      {
        'id': e.id,
        'user_id': e.userId,
        'missed_date': e.missedDate.toLocalDateString(),
        'prayer_type': e.prayerType.identifier,
        'qada_status': e.qadaStatus.name,
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'updated_at': e.updatedAt.millisecondsSinceEpoch,
        'completed_at': e.completedAt?.millisecondsSinceEpoch,
        'notes': e.notes,
        'synced': synced ? 1 : 0,
      };

  QadaRecordEntity? _fromRow(Map<String, dynamic> row) {
    try {
      final dateStr = row['missed_date'] as String;
      final parts = dateStr.split('-');
      final missedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      PrayerType prayerType;
      try {
        prayerType = _parsePrayerType(row['prayer_type'] as String);
      } catch (_) {
        prayerType = PrayerType.fajr;
      }

      QadaStatus qadaStatus;
      try {
        qadaStatus = QadaStatus.values.byName(row['qada_status'] as String);
      } catch (_) {
        qadaStatus = QadaStatus.pending;
      }

      final completedAtMs = row['completed_at'] as int?;

      return QadaRecordEntity(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        missedDate: missedDate,
        prayerType: prayerType,
        qadaStatus: qadaStatus,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
        completedAt: completedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(completedAtMs)
            : null,
        notes: row['notes'] as String?,
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to parse local Qada record — skipping.',
        error: e,
        tag: 'QadaLocalDS',
      );
      return null;
    }
  }

  PrayerType _parsePrayerType(String value) => switch (value) {
        'fajr' => PrayerType.fajr,
        'dhuhr' => PrayerType.dhuhr,
        'asr' => PrayerType.asr,
        'maghrib' => PrayerType.maghrib,
        'isha' => PrayerType.isha,
        _ => throw ArgumentError('Unknown prayer type: $value'),
      };
}
