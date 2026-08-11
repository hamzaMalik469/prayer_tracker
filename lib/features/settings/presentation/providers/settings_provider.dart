library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/location_settings_entity.dart';
import '../../domain/entities/prayer_settings_entity.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/save_location_settings.dart';
import '../../domain/usecases/save_prayer_settings.dart';
import '../../domain/usecases/save_theme_mode.dart';
import '../../domain/usecases/watch_settings.dart';

final class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required GetSettings getSettings,
    required WatchSettings watchSettings,
    required SavePrayerSettings savePrayerSettings,
    required SaveLocationSettings saveLocationSettings,
    required SaveThemeMode saveThemeMode,
  })  : _getSettings = getSettings,
        _watchSettings = watchSettings,
        _savePrayerSettings = savePrayerSettings,
        _saveLocationSettings = saveLocationSettings,
        _saveThemeMode = saveThemeMode;

  final GetSettings _getSettings;
  final WatchSettings _watchSettings;
  final SavePrayerSettings _savePrayerSettings;
  final SaveLocationSettings _saveLocationSettings;
  final SaveThemeMode _saveThemeMode;

  StreamSubscription<AppSettingsEntity>? _settingsSubscription;

  AppSettingsEntity _settings = const AppSettingsEntity.defaults();
  bool _isLoading = false;
  String? _errorMessage;

  AppSettingsEntity get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  PrayerSettingsEntity get prayerSettings => _settings.prayerSettings;
  LocationSettingsEntity get locationSettings => _settings.locationSettings;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialise() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _getSettings();
      _isLoading = false;
      notifyListeners();

      _settingsSubscription = _watchSettings().listen(
        (settings) {
          _settings = settings;
          notifyListeners();
        },
        onError: (Object e) {
          AppLogger.warning(
            'Settings stream error',
            error: e,
            tag: 'SettingsProvider',
          );
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load settings', error: e, tag: 'SettingsProvider');
      _isLoading = false;
      _errorMessage = 'Failed to load settings.';
      notifyListeners();
    }
  }

  Future<void> updatePrayerSettings(PrayerSettingsEntity settings) async {
    try {
      await _savePrayerSettings(SavePrayerSettingsParams(settings: settings));
    } catch (e) {
      AppLogger.error('Failed to save prayer settings', error: e, tag: 'SettingsProvider');
      _errorMessage = 'Failed to save prayer settings.';
      notifyListeners();
    }
  }

  Future<void> updateLocationSettings(LocationSettingsEntity settings) async {
    try {
      await _saveLocationSettings(
        SaveLocationSettingsParams(settings: settings),
      );
    } catch (e) {
      AppLogger.error('Failed to save location settings', error: e, tag: 'SettingsProvider');
      _errorMessage = 'Failed to save location settings.';
      notifyListeners();
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      await _saveThemeMode(SaveThemeModeParams(themeMode: mode));
    } catch (e) {
      AppLogger.error('Failed to save theme mode', error: e, tag: 'SettingsProvider');
      _errorMessage = 'Failed to save theme.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
