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
  List<PrayerTimeEntity> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  /// The five obligatory prayers in order.
  List<PrayerTimeEntity> get obligatory => [fajr, dhuhr, asr, maghrib, isha];

  PrayerTimeEntity forType(PrayerType type) => switch (type) {
        PrayerType.fajr => fajr,
        PrayerType.sunrise => sunrise,
        PrayerType.dhuhr => dhuhr,
        PrayerType.asr => asr,
        PrayerType.maghrib => maghrib,
        PrayerType.isha => isha,
      };

  /// Returns the next prayer after [now], or null if all have passed.
  PrayerTimeEntity? nextPrayerAfter(DateTime now) {
    for (final prayer in all) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    return null;
  }

  /// Returns the currently active prayer (the one whose window is open).
  PrayerTimeEntity? currentPrayer(DateTime now) {
    // Check obligatory prayers in reverse — the latest one whose
    // start time has passed and end time has not is the active one.
    for (final prayer in obligatory.reversed) {
      if (prayer.isActive(now)) return prayer;
    }
    return null;
  }

  /// Returns the most recent prayer whose start time has passed.
  PrayerTimeEntity? lastStartedPrayer(DateTime now) {
    PrayerTimeEntity? current;
    for (final prayer in all) {
      if (!prayer.time.isAfter(now)) {
        current = prayer;
      }
    }
    return current;
  }

  /// Returns a copy with end times computed from the prayer sequence.
  ///
  /// Prayer window logic:
  ///   Fajr    → ends at Sunrise
  ///   Sunrise → no window (not a prayer)
  ///   Dhuhr   → ends at Asr
  ///   Asr     → ends at Maghrib
  ///   Maghrib → ends at Isha
  ///   Isha    → ends at next day Fajr (passed as [nextDayFajr])
  DailyPrayerTimesEntity withEndTimes({DateTime? nextDayFajr}) {
    return DailyPrayerTimesEntity(
      date: date,
      fajr: fajr.copyWith(endTime: sunrise.time),
      sunrise: sunrise, // no end time — not a prayer
      dhuhr: dhuhr.copyWith(endTime: asr.time),
      asr: asr.copyWith(endTime: maghrib.time),
      maghrib: maghrib.copyWith(endTime: isha.time),
      isha: isha.copyWith(
        endTime: nextDayFajr ?? date.add(const Duration(days: 1)),
      ),
      latitude: latitude,
      longitude: longitude,
    );
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
