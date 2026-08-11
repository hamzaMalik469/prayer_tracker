/// Hijri (Islamic) date entity.
///
/// Computed using the standard Kuwaiti algorithm — a mathematical
/// approximation. Civil/calculated Hijri dates can differ from
/// locally announced moon-sighting dates.
///
/// The app must NOT present a calculated date as an authoritative
/// religious determination.
library;

import 'package:equatable/equatable.dart';

enum HijriMonth {
  muharram,
  safar,
  rabiAlAwwal,
  rabiAlThani,
  jumadaAlAwwal,
  jumadaAlThani,
  rajab,
  shaban,
  ramadan,
  shawwal,
  dhulQadah,
  dhulHijjah,
}

extension HijriMonthExtension on HijriMonth {
  int get number => index + 1;

  String get displayName => switch (this) {
        HijriMonth.muharram => 'Muharram',
        HijriMonth.safar => 'Safar',
        HijriMonth.rabiAlAwwal => "Rabi' Al-Awwal",
        HijriMonth.rabiAlThani => "Rabi' Al-Thani",
        HijriMonth.jumadaAlAwwal => 'Jumada Al-Awwal',
        HijriMonth.jumadaAlThani => 'Jumada Al-Thani',
        HijriMonth.rajab => 'Rajab',
        HijriMonth.shaban => "Sha'ban",
        HijriMonth.ramadan => 'Ramadan',
        HijriMonth.shawwal => 'Shawwal',
        HijriMonth.dhulQadah => "Dhul Qa'dah",
        HijriMonth.dhulHijjah => 'Dhul Hijjah',
      };

  String get arabicName => switch (this) {
        HijriMonth.muharram => 'محرم',
        HijriMonth.safar => 'صفر',
        HijriMonth.rabiAlAwwal => 'ربيع الأول',
        HijriMonth.rabiAlThani => 'ربيع الثاني',
        HijriMonth.jumadaAlAwwal => 'جمادى الأولى',
        HijriMonth.jumadaAlThani => 'جمادى الثانية',
        HijriMonth.rajab => 'رجب',
        HijriMonth.shaban => 'شعبان',
        HijriMonth.ramadan => 'رمضان',
        HijriMonth.shawwal => 'شوال',
        HijriMonth.dhulQadah => 'ذو القعدة',
        HijriMonth.dhulHijjah => 'ذو الحجة',
      };

  static HijriMonth fromNumber(int number) {
    assert(number >= 1 && number <= 12, 'Month number must be 1–12');
    return HijriMonth.values[number - 1];
  }
}

final class HijriDateEntity extends Equatable {
  const HijriDateEntity({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final HijriMonth month;
  final int day;

  String get formatted => '$day ${month.displayName} $year AH';
  String get shortFormatted => '$day ${month.displayName} $year';

  @override
  List<Object> get props => [year, month, day];
}
