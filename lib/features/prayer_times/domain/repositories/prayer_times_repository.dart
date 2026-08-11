library;

import '../../../../features/settings/domain/entities/location_settings_entity.dart';
import '../../../../features/settings/domain/entities/prayer_settings_entity.dart';
import '../entities/daily_prayer_times_entity.dart';

abstract interface class PrayerTimesRepository {
  /// Calculates prayer times for [date] using [location] and [settings].
  /// This must work offline — no network call should be made.
  Future<DailyPrayerTimesEntity> getPrayerTimes({
    required DateTime date,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  });

  /// Returns prayer times for a range of dates.
  Future<List<DailyPrayerTimesEntity>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  });
}
