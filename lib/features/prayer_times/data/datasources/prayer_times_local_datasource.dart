/// Prayer time calculation using adhan_dart.
///
/// All adhan_dart imports are isolated to this file.
/// The Domain layer never sees adhan_dart types.
///
/// Verified adhan_dart API (from package source):
///   - CalculationMethod        → enum (dubai, egyptian, karachi, etc.)
///   - CalculationMethodParameters → static methods returning CalculationParameters
///   - CalculationParameters    → class with madhab, highLatitudeRule fields
///   - HighLatitudeRule         → enum (middleOfTheNight, seventhOfTheNight, twilightAngle)
///   - Madhab                   → enum (hanafi, shafi)
///   - PrayerTimes(coordinates, date, calculationParameters) → date is DateTime
///   - PrayerTimes fields: fajr, sunrise, dhuhr, asr, maghrib, isha (DateTime?)
///   - Turkey method is named 'turkiye' in adhan_dart
///   - Morocco method exists in adhan_dart
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
      final params = _buildCalculationParameters(settings);

      // PrayerTimes accepts DateTime directly for date parameter.
      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: date,
        calculationParameters: params,
      );

      return _mapToDomainEntity(prayerTimes, date, location);
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

  // ── Calculation parameters ────────────────────────────────────────────────

  CalculationParameters _buildCalculationParameters(
    PrayerSettingsEntity settings,
  ) {
    // CalculationMethodParameters has static methods that return
    // a fully configured CalculationParameters instance.
    // This is the correct API — not CalculationMethod.x.getParameters().
    final params = _methodToParameters(settings.calculationMethod);

    // Madhab is an enum field on CalculationParameters.
    params.madhab = switch (settings.madhab) {
      MadhabEntity.hanafi => Madhab.hanafi,
      MadhabEntity.shafi => Madhab.shafi,
    };

    // HighLatitudeRule is an enum field on CalculationParameters.
    // Only override when user has selected a specific rule.
    // When none is selected, leave the method default in place.
    if (settings.highLatitudeRule != HighLatitudeRuleEntity.none) {
      params.highLatitudeRule = switch (settings.highLatitudeRule) {
        HighLatitudeRuleEntity.middleOfTheNight =>
          HighLatitudeRule.middleOfTheNight,
        HighLatitudeRuleEntity.seventhOfTheNight =>
          HighLatitudeRule.seventhOfTheNight,
        HighLatitudeRuleEntity.twilightAngle => HighLatitudeRule.twilightAngle,
        HighLatitudeRuleEntity.none =>
          HighLatitudeRule.middleOfTheNight, // unreachable
      };
    }

    return params;
  }

  /// Maps domain [CalculationMethodEntity] to adhan_dart [CalculationParameters]
  /// using [CalculationMethodParameters] static methods (verified from source).
  CalculationParameters _methodToParameters(CalculationMethodEntity method) {
    return switch (method) {
      CalculationMethodEntity.muslimWorldLeague =>
        CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethodEntity.egyptian =>
        CalculationMethodParameters.egyptian(),
      CalculationMethodEntity.karachi => CalculationMethodParameters.karachi(),
      CalculationMethodEntity.ummAlQura =>
        CalculationMethodParameters.ummAlQura(),
      CalculationMethodEntity.dubai => CalculationMethodParameters.dubai(),
      CalculationMethodEntity.moonsightingCommittee =>
        CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethodEntity.northAmerica =>
        CalculationMethodParameters.northAmerica(),
      CalculationMethodEntity.kuwait => CalculationMethodParameters.kuwait(),
      CalculationMethodEntity.qatar => CalculationMethodParameters.qatar(),
      CalculationMethodEntity.singapore =>
        CalculationMethodParameters.singapore(),
      CalculationMethodEntity.tehran => CalculationMethodParameters.tehran(),
      // adhan_dart uses 'turkiye' spelling for Turkey method.
      CalculationMethodEntity.turkey => CalculationMethodParameters.turkiye(),
      // Morocco is present in adhan_dart source.
      CalculationMethodEntity.morocco => CalculationMethodParameters.morocco(),
      CalculationMethodEntity.other => CalculationMethodParameters.other(),
    };
  }

  // ── Domain entity mapping ─────────────────────────────────────────────────

  DailyPrayerTimesEntity _mapToDomainEntity(
    PrayerTimes pt,
    DateTime date,
    LocationSettingsEntity location,
  ) {
    final localDate = DateTime(date.year, date.month, date.day);

    DateTime safeTime(DateTime? time, String prayerName) {
      if (time == null) {
        AppLogger.warning(
          'adhan_dart returned null for $prayerName on $localDate. '
          'Using midnight as fallback.',
          tag: 'PrayerTimesDS',
        );
        return localDate;
      }
      return time.toLocal();
    }

    return DailyPrayerTimesEntity(
      date: localDate,
      fajr: PrayerTimeEntity(
        prayerType: PrayerType.fajr,
        time: safeTime(pt.fajr, 'Fajr'),
        date: localDate,
      ),
      sunrise: PrayerTimeEntity(
        prayerType: PrayerType.sunrise,
        time: safeTime(pt.sunrise, 'Sunrise'),
        date: localDate,
      ),
      dhuhr: PrayerTimeEntity(
        prayerType: PrayerType.dhuhr,
        time: safeTime(pt.dhuhr, 'Dhuhr'),
        date: localDate,
      ),
      asr: PrayerTimeEntity(
        prayerType: PrayerType.asr,
        time: safeTime(pt.asr, 'Asr'),
        date: localDate,
      ),
      maghrib: PrayerTimeEntity(
        prayerType: PrayerType.maghrib,
        time: safeTime(pt.maghrib, 'Maghrib'),
        date: localDate,
      ),
      isha: PrayerTimeEntity(
        prayerType: PrayerType.isha,
        time: safeTime(pt.isha, 'Isha'),
        date: localDate,
      ),
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}
