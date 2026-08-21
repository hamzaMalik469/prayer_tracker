library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';

abstract interface class NotificationSettingsDataSource {
  Future<NotificationSettingsEntity> getSettings();
  Future<void> saveSettings(NotificationSettingsEntity settings);
}

final class NotificationSettingsDataSourceImpl
    implements NotificationSettingsDataSource {
  const NotificationSettingsDataSourceImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _key = 'notification_settings_v1';

  @override
  Future<NotificationSettingsEntity> getSettings() async {
    try {
      final json = _prefs.getString(_key);
      if (json == null) return NotificationSettingsEntity.defaults();

      final map = jsonDecode(json) as Map<String, dynamic>;
      return _fromMap(map);
    } catch (e) {
      AppLogger.warning(
        'Failed to load notification settings, using defaults',
        error: e,
        tag: 'NotificationSettingsDS',
      );
      return NotificationSettingsEntity.defaults();
    }
  }

  @override
  Future<void> saveSettings(NotificationSettingsEntity settings) async {
    try {
      final map = _toMap(settings);
      await _prefs.setString(_key, jsonEncode(map));
    } catch (e) {
      AppLogger.error(
        'Failed to save notification settings',
        error: e,
        tag: 'NotificationSettingsDS',
      );
    }
  }

  Map<String, dynamic> _toMap(NotificationSettingsEntity settings) => {
        'masterEnabled': settings.masterEnabled,
        'prayerConfigs': {
          for (final entry in settings.prayerConfigs.entries)
            entry.key.identifier: {
              'enabled': entry.value.enabled,
              'minutesBefore': entry.value.minutesBefore,
              'minutesAfter': entry.value.minutesAfter,
              'soundEnabled': entry.value.soundEnabled,
              'vibrationEnabled': entry.value.vibrationEnabled,
              'jamaahEnabled': entry.value.jamaahEnabled,
              'minutesBeforeJamaah': entry.value.minutesBeforeJamaah,
            },
        },
      };

  NotificationSettingsEntity _fromMap(Map<String, dynamic> map) {
    final masterEnabled = map['masterEnabled'] as bool? ?? true;
    final configsMap = map['prayerConfigs'] as Map<String, dynamic>? ?? {};

    final configs = <PrayerType, PrayerNotificationConfig>{};

    for (final type in PrayerTypeExtension.obligatory) {
      final configData = configsMap[type.identifier] as Map<String, dynamic>?;

      if (configData == null) {
        configs[type] = PrayerNotificationConfig.defaultFor(type);
        continue;
      }

      configs[type] = PrayerNotificationConfig(
        prayerType: type,
        enabled: configData['enabled'] as bool? ?? true,
        minutesBefore: configData['minutesBefore'] as int? ?? 0,
        minutesAfter: configData['minutesAfter'] as int?,
        soundEnabled: configData['soundEnabled'] as bool? ?? true,
        vibrationEnabled: configData['vibrationEnabled'] as bool? ?? true,
        jamaahEnabled: configData['jamaahEnabled'] as bool? ?? true,
        minutesBeforeJamaah: configData['minutesBeforeJamaah'] as int? ?? 5,
      );
    }

    return NotificationSettingsEntity(
      masterEnabled: masterEnabled,
      prayerConfigs: configs,
    );
  }
}
