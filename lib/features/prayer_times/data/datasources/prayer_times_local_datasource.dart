library;

import 'package:adhan_dart/adhan_dart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../../domain/entities/daily_prayer_times_entity.dart';
import '../../domain/entities/prayer_time_entity.dart';

abstract interface class PrayerTimesLocalDataSource {
  DailyPrayerTimesEntity calculate({
    required DateTime date,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  });
}

final class PrayerTimesLocalDataSourceImpl
    implements PrayerTimesLocalDataSource {
  const PrayerTimesLocalDataSourceImpl();

  @override
  DailyPrayerTimesEntity calculate({
    required DateTime date,
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) {
    try {
      final coordinates = Coordinates(location.latitude, location.longitude);

      // Build CalculationParameters using verified adhan_dart API.
      // CalculationMethodParameters has static methods returning CalculationParameters.
      final params = _buildParams(settings);

      // PrayerTimes accepts a DateTime directly — no DateComponents wrapper.
      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: date,
        calculationParameters: params,
      );

      AppLogger.debug(
        'Calculated prayer times for ${date.year}-${date.month}-${date.day} '
        'at lat:${location.latitude} lng:${location.longitude} '
        'method:${settings.calculationMethod.name} '
        'madhab:${settings.madhab.name}',
        tag: 'PrayerTimesDS',
      );

      return _map(prayerTimes, date, location);
    } catch (e, st) {
      AppLogger.error(
        'Prayer time calculation failed',
        error: e,
        stackTrace: st,
        tag: 'PrayerTimesDS',
      );
      throw const PrayerCalculationFailure(
        message: 'Could not calculate prayer times. '
            'Please check your location and settings.',
      );
    }
  }

  CalculationParameters _buildParams(PrayerSettingsEntity settings) {
    // Get base parameters from the correct static class.
    final params = _methodToParameters(settings.calculationMethod);

    // Apply Madhab — affects Asr shadow length.
    params.madhab = switch (settings.madhab) {
      MadhabEntity.hanafi => Madhab.hanafi,
      MadhabEntity.shafi  => Madhab.shafi,
    };

    // Apply high-latitude rule only when user explicitly sets one.
    if (settings.highLatitudeRule != HighLatitudeRuleEntity.none) {
      params.highLatitudeRule = switch (settings.highLatitudeRule) {
        HighLatitudeRuleEntity.middleOfTheNight  => HighLatitudeRule.middleOfTheNight,
        HighLatitudeRuleEntity.seventhOfTheNight => HighLatitudeRule.seventhOfTheNight,
        HighLatitudeRuleEntity.twilightAngle     => HighLatitudeRule.twilightAngle,
        HighLatitudeRuleEntity.none              => HighLatitudeRule.middleOfTheNight,
      };
    }

    return params;
  }

  CalculationParameters _methodToParameters(CalculationMethodEntity method) {
    return switch (method) {
      CalculationMethodEntity.muslimWorldLeague    => CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethodEntity.egyptian            => CalculationMethodParameters.egyptian(),
      CalculationMethodEntity.karachi             => CalculationMethodParameters.karachi(),
      CalculationMethodEntity.ummAlQura           => CalculationMethodParameters.ummAlQura(),
      CalculationMethodEntity.dubai               => CalculationMethodParameters.dubai(),
      CalculationMethodEntity.moonsightingCommittee => CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethodEntity.northAmerica        => CalculationMethodParameters.northAmerica(),
      CalculationMethodEntity.kuwait              => CalculationMethodParameters.kuwait(),
      CalculationMethodEntity.qatar               => CalculationMethodParameters.qatar(),
      CalculationMethodEntity.singapore           => CalculationMethodParameters.singapore(),
      CalculationMethodEntity.tehran              => CalculationMethodParameters.tehran(),
      CalculationMethodEntity.turkey              => CalculationMethodParameters.turkiye(),
      CalculationMethodEntity.morocco             => CalculationMethodParameters.morocco(),
      CalculationMethodEntity.other               => CalculationMethodParameters.other(),
    };
  }

  DailyPrayerTimesEntity _map(
    PrayerTimes pt,
    DateTime date,
    LocationSettingsEntity location,
  ) {
    final localDate = DateTime(date.year, date.month, date.day);

    DateTime safeTime(DateTime? time, String name) {
      if (time == null) {
        AppLogger.warning(
          'adhan_dart returned null for $name on $localDate. Using midnight.',
          tag: 'PrayerTimesDS',
        );
        return localDate;
      }
      // adhan_dart returns UTC — convert to local.
      return time.toLocal();
    }

    return DailyPrayerTimesEntity(
      date: localDate,
      fajr:    PrayerTimeEntity(prayerType: PrayerType.fajr,    time: safeTime(pt.fajr,    'Fajr'),    date: localDate),
      sunrise: PrayerTimeEntity(prayerType: PrayerType.sunrise, time: safeTime(pt.sunrise, 'Sunrise'), date: localDate),
      dhuhr:   PrayerTimeEntity(prayerType: PrayerType.dhuhr,   time: safeTime(pt.dhuhr,   'Dhuhr'),   date: localDate),
      asr:     PrayerTimeEntity(prayerType: PrayerType.asr,     time: safeTime(pt.asr,     'Asr'),     date: localDate),
      maghrib: PrayerTimeEntity(prayerType: PrayerType.maghrib, time: safeTime(pt.maghrib, 'Maghrib'), date: localDate),
      isha:    PrayerTimeEntity(prayerType: PrayerType.isha,    time: safeTime(pt.isha,    'Isha'),    date: localDate),
      latitude:  location.latitude,
      longitude: location.longitude,
    );
  }
}
