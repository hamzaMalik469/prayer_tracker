library;

import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

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

  bool get isObligatory => this != PrayerType.sunrise;

  static List<PrayerType> get obligatory => [
        PrayerType.fajr,
        PrayerType.dhuhr,
        PrayerType.asr,
        PrayerType.maghrib,
        PrayerType.isha,
      ];
}

/// A single prayer time for a given day.
/// Now includes [endTime] — the time this prayer window closes.
final class PrayerTimeEntity extends Equatable {
  const PrayerTimeEntity({
    required this.prayerType,
    required this.time,
    required this.date,
    this.endTime,
    this.isCustom = false,
  });

  final PrayerType prayerType;

  /// The start time of this prayer window (local time).
  final DateTime time;

  /// The end time of this prayer window (local time).
  /// Null only for sunrise (not a prayer window).
  final DateTime? endTime;

  /// The calendar date this prayer belongs to.
  final DateTime date;

  /// True when the user has overridden this prayer time.
  final bool isCustom;

  /// Returns true when [now] falls within this prayer's window.
  bool isActive(DateTime now) {
    if (endTime == null) return false;
    return now.isAfter(time) && now.isBefore(endTime!);
  }

  /// Returns true when this prayer time has not arrived yet.
  bool isUpcoming(DateTime now) => now.isBefore(time);

  /// Returns true when this prayer window has already passed.
  bool hasPassed(DateTime now) {
    if (endTime == null) return now.isAfter(time);
    return now.isAfter(endTime!);
  }

  PrayerTimeEntity copyWith({
    DateTime? time,
    DateTime? endTime,
    bool? isCustom,
  }) {
    return PrayerTimeEntity(
      prayerType: prayerType,
      time: time ?? this.time,
      endTime: endTime ?? this.endTime,
      date: date,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  List<Object?> get props => [prayerType, time, endTime, date, isCustom];
}
