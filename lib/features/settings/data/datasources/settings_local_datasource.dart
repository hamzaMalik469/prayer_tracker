/// Local settings persistence using SharedPreferences.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/location_settings_entity.dart';
import '../../domain/entities/prayer_settings_entity.dart';

abstract interface class SettingsLocalDataSource {
  Future<PrayerSettingsEntity> getPrayerSettings();
  Future<void> savePrayerSettings(PrayerSettingsEntity settings);
  Future<LocationSettingsEntity> getLocationSettings();
  Future<void> saveLocationSettings(LocationSettingsEntity settings);
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled({required bool enabled});
  Future<void> clearAll();
}

final class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  const SettingsLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;

  // ── Prayer Settings ───────────────────────────────────────────────────────

  @override
  Future<PrayerSettingsEntity> getPrayerSettings() async {
    try {
      final methodStr = _prefs.getString(PreferenceKeys.calculationMethod);
      final madhabStr = _prefs.getString(PreferenceKeys.madhab);
      final highLatStr = _prefs.getString(PreferenceKeys.highLatitudeRule);

      return PrayerSettingsEntity(
        calculationMethod: _parseCalculationMethod(methodStr),
        madhab: _parseMadhab(madhabStr),
        highLatitudeRule: _parseHighLatitudeRule(highLatStr),
      );
    } catch (e) {
      AppLogger.warning('getPrayerSettings failed, returning defaults',
          error: e);
      return const PrayerSettingsEntity.defaults();
    }
  }

  @override
  Future<void> savePrayerSettings(PrayerSettingsEntity settings) async {
    await _prefs.setString(
      PreferenceKeys.calculationMethod,
      settings.calculationMethod.name,
    );
    await _prefs.setString(PreferenceKeys.madhab, settings.madhab.name);
    await _prefs.setString(
      PreferenceKeys.highLatitudeRule,
      settings.highLatitudeRule.name,
    );
  }

  // ── Location Settings ─────────────────────────────────────────────────────

  @override
  Future<LocationSettingsEntity> getLocationSettings() async {
    try {
      final modeStr = _prefs.getString(PreferenceKeys.locationMode);
      final lat = _prefs.getDouble(PreferenceKeys.lastLatitude);
      final lng = _prefs.getDouble(PreferenceKeys.lastLongitude);
      final city = _prefs.getString(PreferenceKeys.manualCityName);

      return LocationSettingsEntity(
        mode:
            modeStr == 'manual' ? LocationMode.manual : LocationMode.automatic,
        latitude: lat ?? 21.3891,
        longitude: lng ?? 39.8579,
        cityName: city,
      );
    } catch (e) {
      AppLogger.warning('getLocationSettings failed, returning defaults',
          error: e);
      return const LocationSettingsEntity.defaults();
    }
  }

  @override
  Future<void> saveLocationSettings(LocationSettingsEntity settings) async {
    await _prefs.setString(
      PreferenceKeys.locationMode,
      settings.mode.name,
    );
    await _prefs.setDouble(PreferenceKeys.lastLatitude, settings.latitude);
    await _prefs.setDouble(PreferenceKeys.lastLongitude, settings.longitude);
    if (settings.cityName != null) {
      await _prefs.setString(PreferenceKeys.manualCityName, settings.cityName!);
    }
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  @override
  Future<ThemeMode> getThemeMode() async {
    final str = _prefs.getString(PreferenceKeys.themeMode);
    return switch (str) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(
      PreferenceKeys.themeMode,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  @override
  Future<bool> getNotificationsEnabled() async =>
      _prefs.getBool(PreferenceKeys.notificationsEnabled) ?? true;

  @override
  Future<void> saveNotificationsEnabled({required bool enabled}) async =>
      _prefs.setBool(PreferenceKeys.notificationsEnabled, enabled);

  // ── Clear ─────────────────────────────────────────────────────────────────

  @override
  Future<void> clearAll() async => _prefs.clear();

  // ── Parsers ───────────────────────────────────────────────────────────────

  CalculationMethodEntity _parseCalculationMethod(String? value) {
    if (value == null) return CalculationMethodEntity.muslimWorldLeague;
    try {
      return CalculationMethodEntity.values.byName(value);
    } catch (_) {
      return CalculationMethodEntity.muslimWorldLeague;
    }
  }

  MadhabEntity _parseMadhab(String? value) {
    if (value == null) return MadhabEntity.shafi;
    try {
      return MadhabEntity.values.byName(value);
    } catch (_) {
      return MadhabEntity.shafi;
    }
  }

  HighLatitudeRuleEntity _parseHighLatitudeRule(String? value) {
    if (value == null) return HighLatitudeRuleEntity.none;
    try {
      return HighLatitudeRuleEntity.values.byName(value);
    } catch (_) {
      return HighLatitudeRuleEntity.none;
    }
  }
}
