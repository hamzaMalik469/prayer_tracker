/// Determines the next prayer from a given moment.
///
/// This use case handles the midnight boundary correctly:
/// if all prayers for today have passed, the next prayer is
/// tomorrow's Fajr — which requires calculating tomorrow's times.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../entities/daily_prayer_times_entity.dart';
import '../entities/prayer_time_entity.dart';
import '../repositories/prayer_times_repository.dart';

final class NextPrayerResult extends Equatable {
  const NextPrayerResult({
    required this.prayer,
    required this.prayerTimes,
    required this.isNextDay,
  });

  final PrayerTimeEntity prayer;
  final DailyPrayerTimesEntity prayerTimes;

  /// True when the next prayer belongs to tomorrow's schedule.
  final bool isNextDay;

  Duration timeRemaining(DateTime now) {
    final diff = prayer.time.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  List<Object> get props => [prayer, prayerTimes, isNextDay];
}

final class GetNextPrayer
    implements UseCase<NextPrayerResult, GetNextPrayerParams> {
  const GetNextPrayer(this._repository);

  final PrayerTimesRepository _repository;

  @override
  Future<NextPrayerResult> call(GetNextPrayerParams params) async {
    final todayTimes = await _repository.getPrayerTimes(
      date: params.now,
      location: params.location,
      settings: params.settings,
    );

    final nextToday = todayTimes.nextPrayerAfter(params.now);
    if (nextToday != null) {
      return NextPrayerResult(
        prayer: nextToday,
        prayerTimes: todayTimes,
        isNextDay: false,
      );
    }

    // All prayers today have passed — get tomorrow's Fajr.
    final tomorrow = params.now.add(const Duration(days: 1));
    final tomorrowTimes = await _repository.getPrayerTimes(
      date: tomorrow,
      location: params.location,
      settings: params.settings,
    );

    return NextPrayerResult(
      prayer: tomorrowTimes.fajr,
      prayerTimes: tomorrowTimes,
      isNextDay: true,
    );
  }
}

final class GetNextPrayerParams extends Equatable {
  const GetNextPrayerParams({
    required this.now,
    required this.location,
    required this.settings,
  });

  final DateTime now;
  final LocationSettingsEntity location;
  final PrayerSettingsEntity settings;

  @override
  List<Object> get props => [now, location, settings];
}
