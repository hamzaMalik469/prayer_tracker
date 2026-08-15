/// Local storage for user-defined custom prayer times.
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

/// Stores custom prayer times as JSON in SharedPreferences.
///
/// Format: { "fajr": "05:30", "dhuhr": "12:15", ... }
/// Only stores overridden times — null means use calculated.
final class PrayerTimesCustomDataSourceImpl
    implements PrayerTimesCustomDataSource {
  const PrayerTimesCustomDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;
  static const _key = 'custom_prayer_times';

  @override
  Future<Map<String, String>?> getCustomTimes() async {
    try {
      final json = _prefs.getString(_key);
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      AppLogger.warning(
        'Failed to load custom prayer times',
        error: e,
        tag: 'CustomTimesDS',
      );
      return null;
    }
  }

  @override
  Future<void> saveCustomTimes(Map<String, String> times) async {
    try {
      await _prefs.setString(_key, jsonEncode(times));
      AppLogger.info('Custom prayer times saved.', tag: 'CustomTimesDS');
    } catch (e) {
      AppLogger.error(
        'Failed to save custom prayer times',
        error: e,
        tag: 'CustomTimesDS',
      );
    }
  }

  @override
  Future<void> clearCustomTimes() async {
    await _prefs.remove(_key);
    AppLogger.info('Custom prayer times cleared.', tag: 'CustomTimesDS');
  }

  @override
  Future<bool> hasCustomTimes() async {
    return _prefs.containsKey(_key);
  }
}
