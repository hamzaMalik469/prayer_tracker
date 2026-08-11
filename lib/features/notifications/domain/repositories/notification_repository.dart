library;

import '../../../prayer_times/domain/entities/daily_prayer_times_entity.dart';
import '../entities/notification_settings_entity.dart';

abstract interface class NotificationRepository {
  Future<NotificationSettingsEntity> getNotificationSettings();
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings);

  /// Schedules notifications for the given prayer times.
  /// Cancels all previously scheduled notifications first.
  Future<void> scheduleNotifications({
    required DailyPrayerTimesEntity prayerTimes,
    required NotificationSettingsEntity settings,
  });

  /// Cancels all scheduled prayer notifications.
  Future<void> cancelAllNotifications();

  /// Returns true if notification permission has been granted.
  Future<bool> hasNotificationPermission();

  /// Requests notification permission from the OS.
  Future<bool> requestNotificationPermission();
}
