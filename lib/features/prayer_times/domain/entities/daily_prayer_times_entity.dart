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

  List<PrayerTimeEntity> get all => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  List<PrayerTimeEntity> get obligatory => [fajr, dhuhr, asr, maghrib, isha];

  PrayerTimeEntity forType(PrayerType type) => switch (type) {
        PrayerType.fajr => fajr,
        PrayerType.sunrise => sunrise,
        PrayerType.dhuhr => dhuhr,
        PrayerType.asr => asr,
        PrayerType.maghrib => maghrib,
        PrayerType.isha => isha,
      };

  PrayerTimeEntity? nextPrayerAfter(DateTime now) {
    for (final prayer in all) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    return null;
  }

  PrayerTimeEntity? currentPrayer(DateTime now) {
    for (final prayer in obligatory.reversed) {
      if (prayer.isActive(now)) return prayer;
    }
    return null;
  }

  /// Appends calculated astronomical end times and preserves or applies Jama'ah times.
  DailyPrayerTimesEntity withEndTimes({
    DateTime? nextDayFajr,
    Map<String, String>? rawJamaahMap,
  }) {
    DateTime? parseJamaah(PrayerType type, DateTime prayerDate) {
      if (rawJamaahMap == null) return forType(type).jamaahTime;
      final timeStr = rawJamaahMap[type.identifier];
      if (timeStr == null || timeStr.isEmpty) return forType(type).jamaahTime;

      try {
        final parts = timeStr.split(':');
        return DateTime(
          prayerDate.year,
          prayerDate.month,
          prayerDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      } catch (_) {
        return forType(type).jamaahTime;
      }
    }

    return DailyPrayerTimesEntity(
      date: date,
      fajr: fajr.copyWith(
        endTime: sunrise.time,
        jamaahTime: parseJamaah(PrayerType.fajr, date),
      ),
      sunrise: sunrise,
      dhuhr: dhuhr.copyWith(
        endTime: asr.time,
        jamaahTime: parseJamaah(PrayerType.dhuhr, date),
      ),
      asr: asr.copyWith(
        endTime: maghrib.time,
        jamaahTime: parseJamaah(PrayerType.asr, date),
      ),
      maghrib: maghrib.copyWith(
        endTime: isha.time,
        jamaahTime: parseJamaah(PrayerType.maghrib, date),
      ),
      isha: isha.copyWith(
        endTime:
            nextDayFajr ?? isha.endTime ?? date.add(const Duration(days: 1)),
        jamaahTime: parseJamaah(PrayerType.isha, date),
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Alias for repository usage
  DailyPrayerTimesEntity withEndAndJamaahTimes({
    DateTime? nextDayFajr,
    Map<String, String>? rawJamaahMap,
  }) =>
      withEndTimes(
        nextDayFajr: nextDayFajr,
        rawJamaahMap: rawJamaahMap,
      );

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
