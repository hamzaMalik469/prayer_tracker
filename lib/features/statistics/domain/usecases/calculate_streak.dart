/// Pure domain streak calculator.
///
/// This use case performs the streak calculation entirely in memory
/// from a list of daily summaries. It has no infrastructure dependency.
///
/// Keeping this logic in the domain ensures it can be unit tested
/// without mocking Firestore, Firebase, or any external service.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../entities/streak_entity.dart';

final class CalculateStreak
    implements UseCase<StreakEntity, CalculateStreakParams> {
  const CalculateStreak();

  @override
  Future<StreakEntity> call(CalculateStreakParams params) async {
    return _calculate(
      summaries: params.summaries,
      today: params.today,
    );
  }

  StreakEntity _calculate({
    required List<DailyPrayerSummaryEntity> summaries,
    required DateTime today,
  }) {
    if (summaries.isEmpty) return const StreakEntity.zero();

    // Sort descending (most recent first).
    final sorted = List<DailyPrayerSummaryEntity>.from(summaries)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastFullyCompleted;
    DateTime? streakStart;

    // Walk backwards through history to find streaks.
    DateTime? expectedDate;

    for (final summary in sorted) {
      final isComplete = summary.isFullyCompleted;

      if (isComplete) {
        if (expectedDate == null ||
            summary.date.isSameDayAs(expectedDate) ||
            summary.date.isSameDayAs(expectedDate.previousDay)) {
          tempStreak++;
          expectedDate = summary.date.previousDay;
        } else {
          // Gap in streak.
          tempStreak = 1;
          expectedDate = summary.date.previousDay;
        }

        lastFullyCompleted ??= summary.date;
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      } else {
        // Incomplete day breaks an ascending streak only if it's
        // in the past (not today — today may still be in progress).
        if (!summary.date.isSameDayAs(today)) {
          tempStreak = 0;
          expectedDate = null;
        }
      }
    }

    // Current streak: count from today backwards.
    expectedDate = null;
    for (final summary in sorted) {
      if (!summary.date.isAfterDayOf(today)) {
        if (summary.isFullyCompleted) {
          if (expectedDate == null ||
              summary.date.isSameDayAs(expectedDate) ||
              summary.date.isSameDayAs(expectedDate.previousDay)) {
            currentStreak++;
            streakStart = summary.date;
            expectedDate = summary.date.previousDay;
          } else {
            break;
          }
        } else if (!summary.date.isSameDayAs(today)) {
          // A non-today incomplete day breaks the current streak.
          break;
        }
      }
    }

    return StreakEntity(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastFullyCompletedDate: lastFullyCompleted,
      streakStartDate: streakStart,
    );
  }
}

final class CalculateStreakParams extends Equatable {
  const CalculateStreakParams({
    required this.summaries,
    required this.today,
  });

  final List<DailyPrayerSummaryEntity> summaries;
  final DateTime today;

  @override
  List<Object> get props => [summaries, today];
}
