library;

import '../entities/hijri_date_entity.dart';

abstract interface class HijriRepository {
  /// Converts a Gregorian [date] to its calculated Hijri equivalent.
  ///
  /// Note: This is a mathematical calculation (Kuwaiti algorithm).
  /// It may differ from locally announced moon-sighting dates.
  HijriDateEntity toHijri(DateTime date);

  /// Returns today's calculated Hijri date.
  HijriDateEntity todayHijri();
}
