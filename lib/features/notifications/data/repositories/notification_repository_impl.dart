library;

import '../../../prayer_times/domain/entities/daily_prayer_times_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_settings_datasource.dart';

final class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationLocalDataSource notificationDataSource,
    required NotificationSettingsDataSource settingsDataSource,
  })  : _notificationDS = notificationDataSource,
        _settingsDS = settingsDataSource;

  final NotificationLocalDataSource _notificationDS;
  final NotificationSettingsDataSource _settingsDS;

  @override
  Future<NotificationSettingsEntity> getNotificationSettings() =>
      _settingsDS.getSettings();

  @override
  Future<void> saveNotificationSettings(
    NotificationSettingsEntity settings,
  ) =>
      _settingsDS.saveSettings(settings);

  @override
  Future<void> scheduleNotifications({
    required DailyPrayerTimesEntity prayerTimes,
    required NotificationSettingsEntity settings,
    List<String> unrecordedPrayersToday = const [],
    int currentStreak = 0,
    bool todayCompleted = false,
  }) async {
    final notifications = PrayerNotificationBuilder.build(
      prayers: prayerTimes.all,
      settings: settings,
      masterEnabled: settings.masterEnabled,
      unrecordedPrayersToday: unrecordedPrayersToday,
      currentStreak: currentStreak,
      todayCompleted: todayCompleted,
    );

    await _notificationDS.schedulePrayerNotifications(
      notifications: notifications,
    );
  }

  @override
  Future<void> cancelAllNotifications() => _notificationDS.cancelAll();

  @override
  Future<bool> hasNotificationPermission() => _notificationDS.hasPermission();

  @override
  Future<bool> requestNotificationPermission() =>
      _notificationDS.requestPermission();
}
