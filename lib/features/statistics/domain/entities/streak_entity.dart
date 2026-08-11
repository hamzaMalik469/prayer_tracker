/// Streak calculation entity.
///
/// Streak rules (enforced here, not in UI):
///
///   A day counts toward a streak ONLY when all five obligatory prayers
///   are explicitly recorded as [PrayerStatus.prayed] or [PrayerStatus.prayedLate].
///
///   [PrayerStatus.notRecorded] does NOT count as prayed.
///   [PrayerStatus.notRecorded] does NOT break a streak automatically.
///
///   A streak is broken only when a day has at least one explicit [PrayerStatus.missed]
///   OR when a past day has zero records (assumed incomplete for streak purposes
///   only when the day is sufficiently in the past — see StreakCalculator).
///
///   Completing Qada does NOT repair historical streaks.
library;

import 'package:equatable/equatable.dart';

final class StreakEntity extends Equatable {
  const StreakEntity({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastFullyCompletedDate,
    required this.streakStartDate,
  });

  const StreakEntity.zero()
      : currentStreak = 0,
        longestStreak = 0,
        lastFullyCompletedDate = null,
        streakStartDate = null;

  /// Number of consecutive fully-completed days up to and including today.
  final int currentStreak;

  /// The all-time longest streak.
  final int longestStreak;

  /// The most recent date on which all five prayers were completed.
  final DateTime? lastFullyCompletedDate;

  /// The date the current streak started.
  final DateTime? streakStartDate;

  bool get hasActiveStreak => currentStreak > 0;

  @override
  List<Object?> get props => [
        currentStreak,
        longestStreak,
        lastFullyCompletedDate,
        streakStartDate,
      ];
}
