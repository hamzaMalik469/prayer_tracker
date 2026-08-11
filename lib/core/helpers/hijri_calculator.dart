/// Pure Dart Hijri date calculator using the Kuwaiti algorithm.
///
/// This is a mathematical calculation. The result may differ from
/// locally announced moon-sighting dates. The application must
/// never present this as an authoritative religious determination.
///
/// Algorithm reference: Kuwaiti Ministry of Awqaf standard algorithm,
/// widely used in Islamic software. This is the same algorithm used by
/// most Hijri calendar libraries.
library;

import '../../features/hijri/domain/entities/hijri_date_entity.dart';

abstract final class HijriCalculator {
  /// Converts a Gregorian [date] to a calculated Hijri date.
  static HijriDateEntity toHijri(DateTime date) {
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    return _julianToHijri(jd);
  }

  /// Julian Day Number from Gregorian date.
  static double _gregorianToJulian(int year, int month, int day) {
    int y = year;
    int m = month;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// Hijri date from Julian Day Number (Kuwaiti algorithm).
  static HijriDateEntity _julianToHijri(double jd) {
    final jdInt = (jd + 0.5).floor();
    final l = jdInt - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) / 5316).floor() * ((50 * l2) / 17719).floor() +
        (l2 / 5670).floor() * ((43 * l2) / 15238).floor();
    final l3 = l2 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = (24 * l3) ~/ 709;
    final day = l3 - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;

    return HijriDateEntity(
      year: year,
      month: HijriMonthExtension.fromNumber(month),
      day: day,
    );
  }
}
