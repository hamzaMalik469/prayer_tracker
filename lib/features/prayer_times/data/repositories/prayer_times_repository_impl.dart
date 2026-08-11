library;

import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../../domain/entities/daily_prayer_times_entity.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/prayer_times_local_datasource.dart';

final class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl({
    required PrayerTimesLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final PrayerTimesLocalDataSource _dataSource;

  @override
  Future<DailyPrayerTimesEntity> getPrayerTimes({
    required DateTime date,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) async {
    return _dataSource.calculate(
      date: date,
      location: location,
      settings: settings,
    );
  }

  @override
  Future<List<DailyPrayerTimesEntity>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) async {
    final results = <DailyPrayerTimesEntity>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      results.add(
        _dataSource.calculate(
          date: current,
          location: location,
          settings: settings,
        ),
      );
      current = current.add(const Duration(days: 1));
    }

    return results;
  }
}
