library;

import 'package:flutter/material.dart';

import '../entities/app_settings_entity.dart';
import '../entities/location_settings_entity.dart';
import '../entities/prayer_settings_entity.dart';

abstract interface class SettingsRepository {
  Future<AppSettingsEntity> getSettings();
  Stream<AppSettingsEntity> watchSettings();
  Future<void> savePrayerSettings(PrayerSettingsEntity settings);
  Future<void> saveLocationSettings(LocationSettingsEntity settings);
  Future<void> saveThemeMode(ThemeMode themeMode);
  Future<void> saveNotificationsEnabled({required bool enabled});
  Future<void> clearLocalData();
}
