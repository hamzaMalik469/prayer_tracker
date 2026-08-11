/// All prayer times for a single day.
library;

import 'package:equatable/equatable.dart';

import 'prayer_time_entity.dart';

final class DailyPrayerTimesEntity extends Equatable {
  const DailyPrayerTimesEntity({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.latitude,
    required this.longitude,
  });

  final DateTime date;
  final PrayerTimeEntity fajr;
  final PrayerTimeEntity sunrise;
  final PrayerTimeEntity dhuhr;
  final PrayerTimeEntity asr;
  final PrayerTimeEntity maghrib;
  final PrayerTimeEntity isha;
  final double latitude;
  final double longitude;

  /// All six prayer/auxiliary times in chronological order.
  List<PrayerTimeEntity> get all => [
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  /// The five obligatory prayers in order.
  List<PrayerTimeEntity> get obligatory => [
        fajr,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  /// Returns the prayer time for [type].
  PrayerTimeEntity forType(PrayerType type) => switch (type) {
        PrayerType.fajr => fajr,
        PrayerType.sunrise => sunrise,
        PrayerType.dhuhr => dhuhr,
        PrayerType.asr => asr,
        PrayerType.maghrib => maghrib,
        PrayerType.isha => isha,
      };

  /// Returns the next prayer after [now], or null if all prayers
  /// for this day have passed.
  PrayerTimeEntity? nextPrayerAfter(DateTime now) {
    for (final prayer in all) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    return null;
  }

  /// Returns the current active prayer (the most recent one whose
  /// time has passed), or null before Fajr.
  PrayerTimeEntity? currentPrayer(DateTime now) {
    PrayerTimeEntity? current;
    for (final prayer in all) {
      if (!prayer.time.isAfter(now)) {
        current = prayer;
      }
    }
    return current;
  }

  @override
  List<Object> get props => [
        date,
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        latitude,
        longitude,
      ];
}
