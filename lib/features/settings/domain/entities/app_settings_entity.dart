/// Consolidated application settings entity.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'location_settings_entity.dart';
import 'prayer_settings_entity.dart';

final class AppSettingsEntity extends Equatable {
  const AppSettingsEntity({
    required this.prayerSettings,
    required this.locationSettings,
    required this.themeMode,
    required this.notificationsEnabled,
  });

  const AppSettingsEntity.defaults()
      : prayerSettings = const PrayerSettingsEntity.defaults(),
        locationSettings = const LocationSettingsEntity.defaults(),
        themeMode = ThemeMode.system,
        notificationsEnabled = true;

  final PrayerSettingsEntity prayerSettings;
  final LocationSettingsEntity locationSettings;
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  AppSettingsEntity copyWith({
    PrayerSettingsEntity? prayerSettings,
    LocationSettingsEntity? locationSettings,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) {
    return AppSettingsEntity(
      prayerSettings: prayerSettings ?? this.prayerSettings,
      locationSettings: locationSettings ?? this.locationSettings,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object> get props => [
        prayerSettings,
        locationSettings,
        themeMode,
        notificationsEnabled,
      ];
}
