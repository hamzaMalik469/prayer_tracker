/// Prayer statistics computed from historical prayer records.
library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

/// Per-prayer consistency statistics.
final class PrayerConsistencyEntity extends Equatable {
  const PrayerConsistencyEntity(
      {required this.prayerType,
      required this.totalDays,
      required this.prayedCount,
      required this.missedCount,
      required this.latePrayedCount,
      required this.notRecordedCount,
      required this.qadaCount});

  final PrayerType prayerType;
  final int totalDays;
  final int prayedCount;
  final int latePrayedCount;
  final int missedCount;
  final int notRecordedCount;
  final int qadaCount;

  double get consistencyPercentage =>
      totalDays == 0 ? 0 : (prayedCount + latePrayedCount / 2) / totalDays;

  @override
  List<Object> get props => [
        prayerType,
        totalDays,
        prayedCount,
        missedCount,
        notRecordedCount,
      ];
}

/// Overall prayer statistics for a given period.
final class PrayerStatisticsEntity extends Equatable {
  const PrayerStatisticsEntity({
    required this.periodStart,
    required this.periodEnd,
    required this.totalPrayed,
    required this.totalMissed,
    required this.totalLatePrayed,
    required this.totalQadaPrayed,
    required this.totalNotRecorded,
    required this.totalDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.perPrayerConsistency,
    required this.bestDay,
    required this.mostMissedPrayer,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalPrayed;
  final int totalMissed;
  final int totalLatePrayed;
  final int totalQadaPrayed;
  final int totalNotRecorded;
  final int totalDays;
  final int currentStreak;
  final int longestStreak;

  /// Per-prayer breakdown. Map key is PrayerType.
  final Map<PrayerType, PrayerConsistencyEntity> perPrayerConsistency;

  /// The day with the highest completion in the period.
  final DateTime? bestDay;

  /// The prayer most frequently missed (or null if no misses).
  final PrayerType? mostMissedPrayer;

  double get overallCompletionPercentage {
    final total = totalPrayed + totalMissed + totalNotRecorded;
    return total == 0 ? 0 : totalPrayed / total;
  }

  int get totalPossible => totalDays * 5;

  @override
  List<Object?> get props => [
        periodStart,
        periodEnd,
        totalPrayed,
        totalMissed,
        totalLatePrayed,
        totalQadaPrayed,
        totalNotRecorded,
        totalDays,
        currentStreak,
        longestStreak,
        perPrayerConsistency,
        bestDay,
        mostMissedPrayer,
      ];
}
