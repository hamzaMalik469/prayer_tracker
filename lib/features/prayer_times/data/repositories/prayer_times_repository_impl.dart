library;

import '../../../../core/di/injection_container.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../../domain/entities/daily_prayer_times_entity.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/prayer_times_custom_datasource.dart';
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
    final calculated = _dataSource.calculate(
      date: date,
      location: location,
      settings: settings,
    );

    // Pull optional mosque Jama'ah times from the local storage
    final jamaahDS = sl<PrayerTimesCustomDataSource>();
    final jamaahMap = await jamaahDS.getCustomTimes();

    return calculated.withEndAndJamaahTimes(
      rawJamaahMap: jamaahMap,
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

    final jamaahDS = sl<PrayerTimesCustomDataSource>();
    final jamaahMap = await jamaahDS.getCustomTimes();

    while (!current.isAfter(end)) {
      final calculated = _dataSource.calculate(
        date: current,
        location: location,
        settings: settings,
      );
      results.add(
        calculated.withEndAndJamaahTimes(rawJamaahMap: jamaahMap),
      );
      current = current.add(const Duration(days: 1));
    }

    return results;
  }
}
