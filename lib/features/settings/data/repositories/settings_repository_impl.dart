library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/location_settings_entity.dart';
import '../../domain/entities/prayer_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    required SettingsRemoteDataSource remoteDataSource,
    String? userId,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _userId = userId;

  final SettingsLocalDataSource _local;
  final SettingsRemoteDataSource _remote;
  String? _userId;

  final _settingsController = StreamController<AppSettingsEntity>.broadcast();

  void updateUserId(String? userId) => _userId = userId;

  @override
  Future<AppSettingsEntity> getSettings() async {
    // Always return local first for speed.
    final local = await _loadLocalSettings();

    // If authenticated, try to merge remote settings.
    if (_userId != null) {
      final remote = await _remote.fetchSettingsFromCloud(userId: _userId!);
      if (remote != null) {
        // Remote wins — sync back to local.
        await _saveAllLocal(remote);
        return remote;
      }
    }

    return local;
  }

  @override
  Stream<AppSettingsEntity> watchSettings() => _settingsController.stream;

  @override
  Future<void> savePrayerSettings(PrayerSettingsEntity settings) async {
    await _local.savePrayerSettings(settings);
    final current = await _loadLocalSettings();
    final updated = current.copyWith(prayerSettings: settings);
    _settingsController.add(updated);
    _syncToCloud(updated);
  }

  @override
  Future<void> saveLocationSettings(LocationSettingsEntity settings) async {
    await _local.saveLocationSettings(settings);
    final current = await _loadLocalSettings();
    final updated = current.copyWith(locationSettings: settings);
    _settingsController.add(updated);
    _syncToCloud(updated);
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _local.saveThemeMode(themeMode);
    final current = await _loadLocalSettings();
    final updated = current.copyWith(themeMode: themeMode);
    _settingsController.add(updated);
    _syncToCloud(updated);
  }

  @override
  Future<void> saveNotificationsEnabled({required bool enabled}) async {
    await _local.saveNotificationsEnabled(enabled: enabled);
    final current = await _loadLocalSettings();
    final updated = current.copyWith(notificationsEnabled: enabled);
    _settingsController.add(updated);
    _syncToCloud(updated);
  }

  @override
  Future<void> clearLocalData() async {
    await _local.clearAll();
    _settingsController.add(const AppSettingsEntity.defaults());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<AppSettingsEntity> _loadLocalSettings() async {
    final prayer = await _local.getPrayerSettings();
    final location = await _local.getLocationSettings();
    final theme = await _local.getThemeMode();
    final notifications = await _local.getNotificationsEnabled();

    return AppSettingsEntity(
      prayerSettings: prayer,
      locationSettings: location,
      themeMode: theme,
      notificationsEnabled: notifications,
    );
  }

  Future<void> _saveAllLocal(AppSettingsEntity settings) async {
    await _local.savePrayerSettings(settings.prayerSettings);
    await _local.saveLocationSettings(settings.locationSettings);
    await _local.saveThemeMode(settings.themeMode);
    await _local.saveNotificationsEnabled(
      enabled: settings.notificationsEnabled,
    );
  }

  void _syncToCloud(AppSettingsEntity settings) {
    if (_userId == null) return;
    _remote.syncSettingsToCloud(userId: _userId!, settings: settings);
  }
}
