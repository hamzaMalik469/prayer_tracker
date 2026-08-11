/// Per-prayer notification configuration.
library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

final class PrayerNotificationConfig extends Equatable {
  const PrayerNotificationConfig({
    required this.prayerType,
    required this.enabled,
    required this.minutesBefore,
    this.minutesAfter,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  const PrayerNotificationConfig.defaultFor(PrayerType type)
      : prayerType = type,
        enabled = true,
        minutesBefore = 0,
        minutesAfter = null,
        soundEnabled = true,
        vibrationEnabled = true;

  final PrayerType prayerType;
  final bool enabled;

  /// Minutes before prayer time to send reminder. 0 = at prayer time.
  final int minutesBefore;

  /// Minutes after prayer time to send a follow-up reminder (Premium).
  /// Null = no post-prayer reminder.
  final int? minutesAfter;

  final bool soundEnabled;
  final bool vibrationEnabled;

  PrayerNotificationConfig copyWith({
    bool? enabled,
    int? minutesBefore,
    int? minutesAfter,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return PrayerNotificationConfig(
      prayerType: prayerType,
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      minutesAfter: minutesAfter ?? this.minutesAfter,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object?> get props => [
        prayerType,
        enabled,
        minutesBefore,
        minutesAfter,
        soundEnabled,
        vibrationEnabled,
      ];
}

final class NotificationSettingsEntity extends Equatable {
  const NotificationSettingsEntity({
    required this.masterEnabled,
    required this.prayerConfigs,
  });

  factory NotificationSettingsEntity.defaults() {
    return NotificationSettingsEntity(
      masterEnabled: true,
      prayerConfigs: {
        for (final type in PrayerTypeExtension.obligatory)
          type: PrayerNotificationConfig.defaultFor(type),
      },
    );
  }

  final bool masterEnabled;
  final Map<PrayerType, PrayerNotificationConfig> prayerConfigs;

  PrayerNotificationConfig configFor(PrayerType type) =>
      prayerConfigs[type] ?? PrayerNotificationConfig.defaultFor(type);

  bool isEnabledFor(PrayerType type) =>
      masterEnabled && (prayerConfigs[type]?.enabled ?? true);

  NotificationSettingsEntity copyWith({
    bool? masterEnabled,
    Map<PrayerType, PrayerNotificationConfig>? prayerConfigs,
  }) {
    return NotificationSettingsEntity(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      prayerConfigs: prayerConfigs ?? this.prayerConfigs,
    );
  }

  @override
  List<Object> get props => [masterEnabled, prayerConfigs];
}
