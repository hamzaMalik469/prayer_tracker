/// Local storage for mosque Jama'ah (Jama\'ah) times.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';

abstract interface class PrayerTimesCustomDataSource {
  Future<Map<String, String>?> getCustomTimes();
  Future<void> saveCustomTimes(Map<String, String> times);
  Future<void> clearCustomTimes();
  Future<bool> hasCustomTimes();
}

final class PrayerTimesCustomDataSourceImpl
    implements PrayerTimesCustomDataSource {
  const PrayerTimesCustomDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;
  static const _key = 'mosque_jamaah_times';

  @override
  Future<Map<String, String>?> getCustomTimes() async {
    try {
      final json = _prefs.getString(_key);
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      AppLogger.warning(
        'Failed to load custom Jamaah times',
        error: e,
        tag: 'JamaahTimesDS',
      );
      return null;
    }
  }

  @override
  Future<void> saveCustomTimes(Map<String, String> times) async {
    try {
      await _prefs.setString(_key, jsonEncode(times));
      AppLogger.info('Mosque Jamaah times saved.', tag: 'JamaahTimesDS');
    } catch (e) {
      AppLogger.error(
        'Failed to save mosque Jamaah times',
        error: e,
        tag: 'JamaahTimesDS',
      );
    }
  }

  @override
  Future<void> clearCustomTimes() async {
    await _prefs.remove(_key);
    AppLogger.info('Mosque Jamaah times cleared.', tag: 'JamaahTimesDS');
  }

  @override
  Future<bool> hasCustomTimes() async {
    return _prefs.containsKey(_key);
  }
}
