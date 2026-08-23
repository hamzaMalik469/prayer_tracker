library;

import '../../../prayer_times/domain/entities/daily_prayer_times_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';

abstract interface class NotificationRepository {
  Future<NotificationSettingsEntity> getNotificationSettings();
  Future<void> saveNotificationSettings(NotificationSettingsEntity settings);

  Future<void> scheduleNotifications({
    required DailyPrayerTimesEntity prayerTimes,
    required NotificationSettingsEntity settings,
    List<String> unrecordedPrayersToday,
    int currentStreak,
    bool todayCompleted,
  });

  Future<void> cancelAllNotifications();
  Future<bool> hasNotificationPermission();
  Future<bool> requestNotificationPermission();
}
