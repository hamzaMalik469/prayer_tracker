/// Generates realistic demo prayer data for testing.
///
/// Creates 6 months of prayer records with varied statuses:
///   - Most prayers marked as prayed (realistic user)
///   - Some missed (especially Fajr — most commonly missed)
///   - Some prayed late
///   - Some qada completed
///   - Some not recorded
///   - A few Qada records (pending + completed)
///
/// Usage: Call DemoDataGenerator.generate() from settings or debug menu.
/// NEVER include in production builds.
library;

import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../features/prayer_times/domain/entities/prayer_time_entity.dart';
import '../../features/prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../features/qada/domain/entities/qada_record_entity.dart';
import '../extensions/date_time_extensions.dart';
import '../logging/app_logger.dart';
import '../services/local_database_service.dart';

abstract final class DemoDataGenerator {
  static final _random = Random(42); // Fixed seed for reproducible data.

  /// Generates [months] months of realistic prayer data for [userId].
  /// Clears existing data for this user first.
  static Future<DemoResult> generate({
    required String userId,
    int months = 6,
  }) async {
    final db = await LocalDatabaseService.database;

    AppLogger.info(
      'Generating $months months of demo data for $userId…',
      tag: 'DemoData',
    );

    // Clear existing data for this user.
    await db.delete(
      'prayer_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await db.delete(
      'qada_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, now.day);
    int prayerCount = 0;
    int missedCount = 0;
    int qadaCount = 0;

    // ── Generate prayer records day by day ──────────────────────────────
    var current = startDate;
    while (!current.isAfter(now)) {
      final batch = db.batch();

      for (final type in PrayerTypeExtension.obligatory) {
        final status = _randomStatus(type, current, now);
        final recordId = PrayerRecordEntity.buildId(
          userId: userId,
          date: current,
          prayerType: type,
        );

        final createdAt = DateTime(
          current.year,
          current.month,
          current.day,
          _prayerHour(type),
          _random.nextInt(59),
        );

        batch.insert(
          'prayer_records',
          {
            'id': recordId,
            'user_id': userId,
            'date': current.toLocalDateString(),
            'prayer_type': type.identifier,
            'status': status.name,
            'created_at': createdAt.millisecondsSinceEpoch,
            'updated_at': createdAt.millisecondsSinceEpoch,
            'notes': null,
            'synced': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (status == PrayerStatus.prayed ||
            status == PrayerStatus.prayedLate) {
          prayerCount++;
        } else if (status == PrayerStatus.missed) {
          missedCount++;
        }
      }

      await batch.commit(noResult: true);
      current = current.add(const Duration(days: 1));
    }

    // ── Generate Qada records ──────────────────────────────────────────
    // Pick some missed prayers and create Qada records for them.
    final missedRecords = await db.query(
      'prayer_records',
      where: "user_id = ? AND status = 'missed'",
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    // Create Qada for ~60% of missed prayers.
    final qadaCandidates =
        missedRecords.where((_) => _random.nextDouble() < 0.6).toList();

    for (final missed in qadaCandidates) {
      final dateStr = missed['date'] as String;
      final parts = dateStr.split('-');
      final missedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final prayerType = missed['prayer_type'] as String;
      final qadaId = '${userId}_${dateStr}_${prayerType}_qada';
      final createdAt = missedDate.add(Duration(days: _random.nextInt(14) + 1));

      // ~70% of Qada records are completed.
      final isCompleted = _random.nextDouble() < 0.7;
      final completedAt = isCompleted
          ? createdAt.add(Duration(days: _random.nextInt(7)))
          : null;

      final qadaStatus = isCompleted ? 'completed' : 'pending';

      await db.insert(
        'qada_records',
        {
          'id': qadaId,
          'user_id': userId,
          'missed_date': dateStr,
          'prayer_type': prayerType,
          'qada_status': qadaStatus,
          'created_at': createdAt.millisecondsSinceEpoch,
          'updated_at': (completedAt ?? createdAt).millisecondsSinceEpoch,
          'completed_at': completedAt?.millisecondsSinceEpoch,
          'notes': isCompleted ? null : 'Need to make up',
          'synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      qadaCount++;

      // If completed, update the prayer record to qadaCompleted.
      if (isCompleted) {
        final prayerRecordId = '${userId}_${dateStr}_$prayerType';
        await db.update(
          'prayer_records',
          {
            'status': PrayerStatus.qadaCompleted.name,
            'updated_at': completedAt!.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [prayerRecordId],
        );
      }
    }

    final result = DemoResult(
      daysGenerated: now.difference(startDate).inDays,
      prayersRecorded: prayerCount + missedCount,
      prayedCount: prayerCount,
      missedCount: missedCount,
      qadaRecords: qadaCount,
    );

    AppLogger.info(
      'Demo data generated: ${result.daysGenerated} days, '
      '${result.prayersRecorded} prayers, '
      '${result.qadaRecords} qada records.',
      tag: 'DemoData',
    );

    return result;
  }

  /// Generates a realistic prayer status.
  ///
  /// Probabilities vary by prayer type to simulate real behavior:
  ///   Fajr:    70% prayed, 15% missed, 8% late, 5% qadaCompleted, 2% not recorded
  ///   Dhuhr:   88% prayed, 5% missed, 4% late, 2% qadaCompleted, 1% not recorded
  ///   Asr:     85% prayed, 7% missed, 5% late, 2% qadaCompleted, 1% not recorded
  ///   Maghrib: 92% prayed, 3% missed, 3% late, 1% qadaCompleted, 1% not recorded
  ///   Isha:    82% prayed, 8% missed, 6% late, 3% qadaCompleted, 1% not recorded
  static PrayerStatus _randomStatus(
    PrayerType type,
    DateTime date,
    DateTime now,
  ) {
    // Today and yesterday might not be fully recorded.
    final daysAgo = now.difference(date).inDays;
    if (daysAgo == 0) {
      // Today: some not yet recorded.
      final hourNow = now.hour;
      final prayerHr = _prayerHour(type);
      if (hourNow < prayerHr) return PrayerStatus.notRecorded;
    }

    final r = _random.nextDouble();

    return switch (type) {
      PrayerType.fajr => r < 0.70
          ? PrayerStatus.prayed
          : r < 0.85
              ? PrayerStatus.missed
              : r < 0.93
                  ? PrayerStatus.prayedLate
                  : r < 0.98
                      ? PrayerStatus.notRecorded
                      : PrayerStatus.notRecorded,
      PrayerType.dhuhr => r < 0.88
          ? PrayerStatus.prayed
          : r < 0.93
              ? PrayerStatus.missed
              : r < 0.97
                  ? PrayerStatus.prayedLate
                  : PrayerStatus.notRecorded,
      PrayerType.asr => r < 0.85
          ? PrayerStatus.prayed
          : r < 0.92
              ? PrayerStatus.missed
              : r < 0.97
                  ? PrayerStatus.prayedLate
                  : PrayerStatus.notRecorded,
      PrayerType.maghrib => r < 0.92
          ? PrayerStatus.prayed
          : r < 0.95
              ? PrayerStatus.missed
              : r < 0.98
                  ? PrayerStatus.prayedLate
                  : PrayerStatus.notRecorded,
      PrayerType.isha => r < 0.82
          ? PrayerStatus.prayed
          : r < 0.90
              ? PrayerStatus.missed
              : r < 0.96
                  ? PrayerStatus.prayedLate
                  : PrayerStatus.notRecorded,
      PrayerType.sunrise => PrayerStatus.notRecorded,
    };
  }

  /// Approximate hour for each prayer (used for createdAt timestamps).
  static int _prayerHour(PrayerType type) => switch (type) {
        PrayerType.fajr => 5,
        PrayerType.sunrise => 6,
        PrayerType.dhuhr => 12,
        PrayerType.asr => 15,
        PrayerType.maghrib => 18,
        PrayerType.isha => 20,
      };

  /// Clears all demo data for [userId].
  static Future<void> clearAll({required String userId}) async {
    final db = await LocalDatabaseService.database;
    await db
        .delete('prayer_records', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('qada_records', where: 'user_id = ?', whereArgs: [userId]);
    AppLogger.info('Demo data cleared for $userId.', tag: 'DemoData');
  }
}

final class DemoResult {
  const DemoResult({
    required this.daysGenerated,
    required this.prayersRecorded,
    required this.prayedCount,
    required this.missedCount,
    required this.qadaRecords,
  });

  final int daysGenerated;
  final int prayersRecorded;
  final int prayedCount;
  final int missedCount;
  final int qadaRecords;
}
