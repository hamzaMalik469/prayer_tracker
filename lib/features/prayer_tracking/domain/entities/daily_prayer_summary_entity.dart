/// Summary of prayer completion for a single day.
library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import 'prayer_record_entity.dart';

final class DailyPrayerSummaryEntity extends Equatable {
  const DailyPrayerSummaryEntity({
    required this.date,
    required this.records,
  });

  final DateTime date;

  /// Map of PrayerType → PrayerRecordEntity for this day.
  /// May be empty or partial if prayers have not been recorded yet.
  final Map<PrayerType, PrayerRecordEntity> records;

  int get prayedCount =>
      records.values.where((r) => r.status.isCompleted).length;

  int get missedCount => records.values.where((r) => r.status.isMissed).length;

  int get notRecordedCount =>
      PrayerTypeExtension.obligatory.length -
      records.length +
      records.values.where((r) => r.status == PrayerStatus.notRecorded).length;

  /// Returns true ONLY when all five prayers are explicitly recorded as prayed.
  bool get isFullyCompleted =>
      prayedCount == PrayerTypeExtension.obligatory.length;

  /// Returns true when at least one prayer is explicitly missed.
  bool get hasExplicitMiss => missedCount > 0;

  /// Completion percentage based on prayed / 5.
  double get completionPercentage =>
      prayedCount / PrayerTypeExtension.obligatory.length;

  PrayerStatus statusFor(PrayerType type) =>
      records[type]?.status ?? PrayerStatus.notRecorded;

  @override
  List<Object> get props => [date, records];
}
