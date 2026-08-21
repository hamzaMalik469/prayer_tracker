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
    required this.jamaahEnabled,
    required this.minutesBeforeJamaah,
  });

  const PrayerNotificationConfig.defaultFor(PrayerType type)
      : prayerType = type,
        enabled = true,
        minutesBefore = 0,
        minutesAfter = null,
        soundEnabled = true,
        vibrationEnabled = true,
        jamaahEnabled = true,
        minutesBeforeJamaah = 5; // 5 minutes before Jama'ah by default

  final PrayerType prayerType;
  final bool enabled;

  /// Minutes before prayer astronomical start time to send reminder.
  final int minutesBefore;

  /// Minutes after prayer time to send a follow-up reminder (Premium).
  final int? minutesAfter;

  final bool soundEnabled;
  final bool vibrationEnabled;

  /// Whether to send a reminder before the local mosque's Jama'ah time.
  final bool jamaahEnabled;

  /// Minutes before the Jama'ah time to send the reminder.
  final int minutesBeforeJamaah;

  PrayerNotificationConfig copyWith({
    bool? enabled,
    int? minutesBefore,
    int? minutesAfter,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? jamaahEnabled,
    int? minutesBeforeJamaah,
  }) {
    return PrayerNotificationConfig(
      prayerType: prayerType,
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      minutesAfter: minutesAfter ?? this.minutesAfter,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      jamaahEnabled: jamaahEnabled ?? this.jamaahEnabled,
      minutesBeforeJamaah: minutesBeforeJamaah ?? this.minutesBeforeJamaah,
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
        jamaahEnabled,
        minutesBeforeJamaah,
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
