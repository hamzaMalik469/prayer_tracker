/// Local SQLite data source for prayer tracking.
///
/// This is the primary write target for all prayer records.
/// Firestore is a secondary sync target for authenticated users.
library;

import 'package:prayers_tracker_plus/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../../core/extensions/date_time_extensions.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/services/local_database_service.dart';
import '../../domain/entities/prayer_record_entity.dart';

abstract interface class PrayerTrackingLocalDataSource {
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required String recordId,
  });

  Future<List<PrayerRecordEntity>> getPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  });

  Future<List<PrayerRecordEntity>> getPrayerRecordsForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<PrayerRecordEntity> upsertPrayerRecord(PrayerRecordEntity record);

  Future<List<PrayerRecordEntity>> getUnsyncedRecords({
    required String userId,
  });

  Future<void> markAsSynced({required String recordId});

  Stream<List<PrayerRecordEntity>> watchPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  });
}

final class PrayerTrackingLocalDataSourceImpl
    implements PrayerTrackingLocalDataSource {
  const PrayerTrackingLocalDataSourceImpl();

  Future<Database> get _db => LocalDatabaseService.database;

  @override
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required String recordId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_records',
      where: 'id = ? AND user_id = ?',
      whereArgs: [recordId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<PrayerRecordEntity>> getPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final db = await _db;
    final dateStr = date.toLocalDateString();
    final rows = await db.query(
      'prayer_records',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, dateStr],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<PrayerRecordEntity>> getPrayerRecordsForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;
    final startStr = startDate.toLocalDateString();
    final endStr = endDate.toLocalDateString();
    final rows = await db.query(
      'prayer_records',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startStr, endStr],
      orderBy: 'date ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<PrayerRecordEntity> upsertPrayerRecord(
    PrayerRecordEntity record,
  ) async {
    final db = await _db;

    await db.insert(
      'prayer_records',
      _toRow(record, synced: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    AppLogger.debug(
      'Local upsert: ${record.prayerType.identifier} '
      '${record.date.toLocalDateString()} → ${record.status.name}',
      tag: 'PrayerLocalDS',
    );

    return record;
  }

  @override
  Future<List<PrayerRecordEntity>> getUnsyncedRecords({
    required String userId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_records',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markAsSynced({required String recordId}) async {
    final db = await _db;
    await db.update(
      'prayer_records',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // Simple in-memory stream using periodic polling.
  // For production apps, consider using a StreamController
  // triggered on every write.
  @override
  Stream<List<PrayerRecordEntity>> watchPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  }) async* {
    while (true) {
      yield await getPrayerRecordsForDate(userId: userId, date: date);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(PrayerRecordEntity e, {required bool synced}) => {
        'id': e.id,
        'user_id': e.userId,
        'date': e.date.toLocalDateString(),
        'prayer_type': e.prayerType.identifier,
        'status': e.status.name,
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'updated_at': e.updatedAt.millisecondsSinceEpoch,
        'notes': e.notes,
        'synced': synced ? 1 : 0,
      };

  PrayerRecordEntity _fromRow(Map<String, dynamic> row) {
    final dateStr = row['date'] as String;
    final parts = dateStr.split('-');
    final date = DateTime(
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

    PrayerStatus status;
    try {
      status = PrayerStatus.values.byName(row['status'] as String);
    } catch (_) {
      status = PrayerStatus.notRecorded;
    }

    return PrayerRecordEntity(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      date: date,
      prayerType: prayerType,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      notes: row['notes'] as String?,
    );
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
