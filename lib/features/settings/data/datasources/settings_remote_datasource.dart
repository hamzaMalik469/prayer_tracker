/// Firestore settings sync data source.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/location_settings_entity.dart';
import '../../domain/entities/prayer_settings_entity.dart';

abstract interface class SettingsRemoteDataSource {
  Future<void> syncSettingsToCloud({
    required String userId,
    required AppSettingsEntity settings,
  });
  Future<AppSettingsEntity?> fetchSettingsFromCloud({required String userId});
}

final class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _prefsDoc(String userId) => _firestore
      .collection(FirestoreCollections.users)
      .doc(userId)
      .collection(FirestoreCollections.settings)
      .doc(FirestoreDocuments.preferences);

  @override
  Future<void> syncSettingsToCloud({
    required String userId,
    required AppSettingsEntity settings,
  }) async {
    try {
      await _prefsDoc(userId).set(
        _settingsToMap(settings),
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.warning('syncSettingsToCloud failed',
          error: e, tag: 'SettingsRemoteDS');
    }
  }

  @override
  Future<AppSettingsEntity?> fetchSettingsFromCloud({
    required String userId,
  }) async {
    try {
      final snap = await _prefsDoc(userId).get();
      if (!snap.exists || snap.data() == null) return null;
      return _settingsFromMap(snap.data()!);
    } catch (e) {
      AppLogger.warning('fetchSettingsFromCloud failed',
          error: e, tag: 'SettingsRemoteDS');
      return null;
    }
  }

  Map<String, dynamic> _settingsToMap(AppSettingsEntity settings) => {
        FirestoreFields.calculationMethod:
            settings.prayerSettings.calculationMethod.name,
        FirestoreFields.madhab: settings.prayerSettings.madhab.name,
        FirestoreFields.highLatitudeRule:
            settings.prayerSettings.highLatitudeRule.name,
        FirestoreFields.themeMode: switch (settings.themeMode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
        FirestoreFields.locationMode: settings.locationSettings.mode.name,
        FirestoreFields.latitude: settings.locationSettings.latitude,
        FirestoreFields.longitude: settings.locationSettings.longitude,
        FirestoreFields.cityName: settings.locationSettings.cityName,
        FirestoreFields.notificationsEnabled: settings.notificationsEnabled,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      };

  AppSettingsEntity _settingsFromMap(Map<String, dynamic> map) {
    CalculationMethodEntity method;
    try {
      method = CalculationMethodEntity.values.byName(
        map[FirestoreFields.calculationMethod] as String? ?? '',
      );
    } catch (_) {
      method = CalculationMethodEntity.muslimWorldLeague;
    }

    MadhabEntity madhab;
    try {
      madhab = MadhabEntity.values.byName(
        map[FirestoreFields.madhab] as String? ?? '',
      );
    } catch (_) {
      madhab = MadhabEntity.shafi;
    }

    HighLatitudeRuleEntity highLat;
    try {
      highLat = HighLatitudeRuleEntity.values.byName(
        map[FirestoreFields.highLatitudeRule] as String? ?? '',
      );
    } catch (_) {
      highLat = HighLatitudeRuleEntity.none;
    }

    final themeStr = map[FirestoreFields.themeMode] as String?;
    final themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final locationModeStr = map[FirestoreFields.locationMode] as String?;
    final locationMode = locationModeStr == 'manual'
        ? LocationMode.manual
        : LocationMode.automatic;

    return AppSettingsEntity(
      prayerSettings: PrayerSettingsEntity(
        calculationMethod: method,
        madhab: madhab,
        highLatitudeRule: highLat,
      ),
      locationSettings: LocationSettingsEntity(
        mode: locationMode,
        latitude:
            (map[FirestoreFields.latitude] as num?)?.toDouble() ?? 21.3891,
        longitude:
            (map[FirestoreFields.longitude] as num?)?.toDouble() ?? 39.8579,
        cityName: map[FirestoreFields.cityName] as String?,
      ),
      themeMode: themeMode,
      notificationsEnabled:
          map[FirestoreFields.notificationsEnabled] as bool? ?? true,
    );
  }
}
