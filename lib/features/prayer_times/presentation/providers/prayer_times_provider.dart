library;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../../domain/entities/daily_prayer_times_entity.dart';
import '../../domain/usecases/get_prayer_times.dart';

final class PrayerTimesProvider extends ChangeNotifier {
  PrayerTimesProvider({required GetPrayerTimes getPrayerTimes})
      : _getPrayerTimes = getPrayerTimes;

  final GetPrayerTimes _getPrayerTimes;

  DailyPrayerTimesEntity? _todayTimes;
  DailyPrayerTimesEntity? _tomorrowTimes;
  bool _isLoading = false;
  String? _errorMessage;

  DailyPrayerTimesEntity? get todayTimes => _todayTimes;
  DailyPrayerTimesEntity? get tomorrowTimes => _tomorrowTimes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _todayTimes != null;

  Future<void> calculatePrayerTimes({
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final results = await Future.wait([
        _getPrayerTimes(
          GetPrayerTimesParams(
              date: now, location: location, settings: settings),
        ),
        _getPrayerTimes(
          GetPrayerTimesParams(
              date: tomorrow, location: location, settings: settings),
        ),
      ]);

      // Compute end times using the next day's Fajr for Isha end.
      _todayTimes = results[0].withEndTimes(
        nextDayFajr: results[1].fajr.time,
      );
      _tomorrowTimes = results[1].withEndTimes();

      _isLoading = false;
      notifyListeners();

      AppLogger.info(
        'Prayer times calculated with end times for '
        '${now.year}-${now.month}-${now.day}',
        tag: 'PrayerTimesProvider',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to calculate prayer times',
        error: e,
        tag: 'PrayerTimesProvider',
      );
      _isLoading = false;
      _errorMessage = 'Could not calculate prayer times. Check your location.';
      notifyListeners();
    }
  }

  Future<void> refresh({
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) =>
      calculatePrayerTimes(location: location, settings: settings);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
