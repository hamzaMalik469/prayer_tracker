library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/qada_record_entity.dart';
import '../entities/qada_summary_entity.dart';

abstract interface class QadaRepository {
  /// Returns all Qada records (pending + completed) for [userId].
  Future<QadaSummaryEntity> getQadaSummary({required String userId});

  /// Watches Qada records in real time.
  Stream<QadaSummaryEntity> watchQadaSummary({required String userId});

  /// Creates a Qada record for a specific missed prayer on a specific date.
  /// Also ensures the original prayer is marked as Missed.
  Future<QadaRecordEntity> addQadaRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  });

  /// Completes a Qada record:
  ///   1. Updates QadaRecord.status → completed
  ///   2. Updates original PrayerRecord.status → qadaCompleted
  /// Returns the updated QadaRecord.
  Future<QadaRecordEntity> completeQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  });

  /// Returns all Qada records for a specific date (for calendar display).
  Future<List<QadaRecordEntity>> getQadaRecordsForDate({
    required String userId,
    required DateTime date,
  });

  /// Deletes a Qada record (if added by mistake).
  Future<void> deleteQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  });
}
