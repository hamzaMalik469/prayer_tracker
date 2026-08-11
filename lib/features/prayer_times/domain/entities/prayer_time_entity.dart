/// A single calculated prayer time.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Identifies one of the five obligatory prayers or auxiliary times.
enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerTypeExtension on PrayerType {
  String get identifier => switch (this) {
        PrayerType.fajr => PrayerIdentifiers.fajr,
        PrayerType.sunrise => 'sunrise',
        PrayerType.dhuhr => PrayerIdentifiers.dhuhr,
        PrayerType.asr => PrayerIdentifiers.asr,
        PrayerType.maghrib => PrayerIdentifiers.maghrib,
        PrayerType.isha => PrayerIdentifiers.isha,
      };

  String get displayName => switch (this) {
        PrayerType.fajr => 'Fajr',
        PrayerType.sunrise => 'Sunrise',
        PrayerType.dhuhr => 'Dhuhr',
        PrayerType.asr => 'Asr',
        PrayerType.maghrib => 'Maghrib',
        PrayerType.isha => 'Isha',
      };

  String get arabicName => switch (this) {
        PrayerType.fajr => 'الفجر',
        PrayerType.sunrise => 'الشروق',
        PrayerType.dhuhr => 'الظهر',
        PrayerType.asr => 'العصر',
        PrayerType.maghrib => 'المغرب',
        PrayerType.isha => 'العشاء',
      };

  /// Returns true for the five obligatory prayers (excludes Sunrise).
  bool get isObligatory => this != PrayerType.sunrise;

  /// Returns the five obligatory prayers in order.
  static List<PrayerType> get obligatory => [
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ];
}

/// A single prayer time for a given day.
final class PrayerTimeEntity extends Equatable {
  const PrayerTimeEntity({
    required this.prayerType,
    required this.time,
    required this.date,
  });

  final PrayerType prayerType;

  /// The calculated prayer time in local time.
  final DateTime time;

  /// The calendar date this prayer time belongs to.
  final DateTime date;

  @override
  List<Object> get props => [prayerType, time, date];
}
