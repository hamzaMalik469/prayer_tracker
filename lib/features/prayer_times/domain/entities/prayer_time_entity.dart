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

/// A single prayer time window with optional Jama'ah (Jama\'ah) time.
final class PrayerTimeEntity extends Equatable {
  const PrayerTimeEntity({
    required this.prayerType,
    required this.time,
    required this.date,
    this.endTime,
    this.jamaahTime,
  });

  final PrayerType prayerType;

  /// Start of the prayer window (astronomical local time).
  final DateTime time;

  /// End of the prayer window (astronomical local time).
  final DateTime? endTime;

  /// Calendar date this prayer belongs to.
  final DateTime date;

  /// Optional mosque congregational prayer time (local time).
  final DateTime? jamaahTime;

  bool get hasJamaah => jamaahTime != null;

  bool isActive(DateTime now) {
    if (endTime == null) return false;
    return now.isAfter(time) && now.isBefore(endTime!);
  }

  bool isUpcoming(DateTime now) => now.isBefore(time);

  bool hasPassed(DateTime now) {
    if (endTime == null) return now.isAfter(time);
    return now.isAfter(endTime!);
  }

  PrayerTimeEntity copyWith({
    DateTime? time,
    DateTime? endTime,
    DateTime? jamaahTime,
  }) {
    return PrayerTimeEntity(
      prayerType: prayerType,
      time: time ?? this.time,
      endTime: endTime ?? this.endTime,
      date: date,
      jamaahTime: jamaahTime ?? this.jamaahTime,
    );
  }

  @override
  List<Object?> get props => [prayerType, time, endTime, date, jamaahTime];
}
