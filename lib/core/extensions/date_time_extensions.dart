library;

extension DateTimeExtensions on DateTime {
  DateTime get localDateOnly => DateTime(year, month, day);

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isBeforeDayOf(DateTime other) {
    final thisDay = localDateOnly;
    final otherDay = other.localDateOnly;
    return thisDay.isBefore(otherDay);
  }

  bool isAfterDayOf(DateTime other) {
    final thisDay = localDateOnly;
    final otherDay = other.localDateOnly;
    return thisDay.isAfter(otherDay);
  }

  String toLocalDateString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get nextDay => DateTime(year, month, day + 1);

  DateTime get previousDay => DateTime(year, month, day - 1);
}
