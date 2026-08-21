/// flutter_local_notifications data source.
///
/// All flutter_local_notifications imports are isolated here.
/// The Domain layer never imports this package directly.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';

abstract interface class NotificationLocalDataSource {
  Future<bool> initialise();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> schedulePrayerNotifications({
    required List<_ScheduledNotification> notifications,
  });
  Future<void> cancelAll();
  Future<void> cancelNotification(int id);
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}

/// Internal model for a scheduled notification.
final class _ScheduledNotification {
  const _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final bool soundEnabled;
  final bool vibrationEnabled;
}

final class NotificationLocalDataSourceImpl
    implements NotificationLocalDataSource {
  NotificationLocalDataSourceImpl()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  @override
  Future<bool> initialise() async {
    if (_initialised) return true;

    try {
      // Initialise timezone database.
      tz.initializeTimeZones();
      _setLocalTimezone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _plugin.initialize(settings);
      _initialised = result ?? false;

      AppLogger.info(
        'Notifications initialised: $_initialised',
        tag: 'NotificationDS',
      );

      return _initialised;
    } catch (e) {
      AppLogger.error(
        'Failed to initialise notifications',
        error: e,
        tag: 'NotificationDS',
      );
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await android?.requestNotificationsPermission() ?? false;
        AppLogger.info(
          'Android notification permission: $granted',
          tag: 'NotificationDS',
        );
        return granted;
      }

      if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        AppLogger.info(
          'iOS notification permission: $granted',
          tag: 'NotificationDS',
        );
        return granted;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Failed to request notification permission',
        error: e,
        tag: 'NotificationDS',
      );
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.areNotificationsEnabled() ?? false;
        return granted;
      }

      if (Platform.isIOS) {
        // iOS: check via pending notifications as a proxy.
        // Full permission status requires permission_handler package.
        // For now return true if initialised — real check in Phase 7.
        return _initialised;
      }

      return false;
    } catch (e) {
      AppLogger.warning(
        'hasPermission check failed',
        error: e,
        tag: 'NotificationDS',
      );
      return false;
    }
  }

  @override
  Future<void> schedulePrayerNotifications({
    required List<_ScheduledNotification> notifications,
  }) async {
    if (!_initialised) await initialise();

    for (final notification in notifications) {
      final scheduledTz =
          tz.TZDateTime.from(notification.scheduledTime, tz.local);

      // Skip if the scheduled time is in the past.
      if (scheduledTz.isBefore(tz.TZDateTime.now(tz.local))) {
        AppLogger.debug(
          'Skipping past notification: ${notification.title}',
          tag: 'NotificationDS',
        );
        continue;
      }

      try {
        await _plugin.zonedSchedule(
          notification.id,
          notification.title,
          notification.body,
          scheduledTz,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_times',
              'Prayer Times',
              channelDescription:
                  'Notifications for the five daily prayer times',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: notification.vibrationEnabled,
              playSound: notification.soundEnabled,
              icon: '@mipmap/ic_launcher',
              category: AndroidNotificationCategory.reminder,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: notification.soundEnabled,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        AppLogger.debug(
          'Scheduled: ${notification.title} at ${notification.scheduledTime}',
          tag: 'NotificationDS',
        );
      } catch (e) {
        AppLogger.error(
          'Failed to schedule: ${notification.title}',
          error: e,
          tag: 'NotificationDS',
        );
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      AppLogger.info('All notifications cancelled.', tag: 'NotificationDS');
    } catch (e) {
      AppLogger.error(
        'Failed to cancel all notifications',
        error: e,
        tag: 'NotificationDS',
      );
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      AppLogger.error(
        'Failed to cancel notification $id',
        error: e,
        tag: 'NotificationDS',
      );
    }
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      AppLogger.warning(
        'getPendingNotifications failed',
        error: e,
        tag: 'NotificationDS',
      );
      return [];
    }
  }

  void _setLocalTimezone() {
    try {
      // Use the device's local timezone offset to find the matching
      // timezone name. This is a reliable approach without needing
      // flutter_native_timezone on all platforms.
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetHours = offset.inHours;
      final offsetMinutes = offset.inMinutes.remainder(60).abs();

      // Find a timezone that matches the current UTC offset.
      // Falls back to UTC if no match found.
      String? matchedZone;
      for (final zoneName in tz.timeZoneDatabase.locations.keys) {
        final location = tz.getLocation(zoneName);
        final tzNow = tz.TZDateTime.now(location);
        final tzOffset = tzNow.timeZoneOffset;

        if (tzOffset.inMinutes == offset.inMinutes) {
          matchedZone = zoneName;
          break;
        }
      }

      tz.setLocalLocation(
        tz.getLocation(matchedZone ?? 'UTC'),
      );

      AppLogger.info(
        'Timezone set to: ${matchedZone ?? 'UTC'} '
        '(offset: $offsetHours:${offsetMinutes.toString().padLeft(2, '0')})',
        tag: 'NotificationDS',
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to set local timezone, using UTC',
        error: e,
        tag: 'NotificationDS',
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}

/// Public builder used by the repository to construct scheduled notifications.
final class PrayerNotificationBuilder {
  PrayerNotificationBuilder._();

  /// Builds a list of [_ScheduledNotification] from prayer times and settings.
  static List<_ScheduledNotification> build({
    required List<PrayerTimeEntity> prayers,
    required NotificationSettingsEntity settings,
    required bool masterEnabled,
  }) {
    if (!masterEnabled) return [];

    final notifications = <_ScheduledNotification>[];

    for (final prayer in prayers) {
      if (!prayer.prayerType.isObligatory) continue;

      final config = settings.configFor(prayer.prayerType);
      if (!config.enabled) continue;

      // ── 1. Astronomical Start Time Reminder ─────────────────────────────
      final startNotificationId = _buildId(
        date: prayer.date,
        prayerType: prayer.prayerType,
        idTypeOffset: 0, // offset 0 for start times
      );

      final notificationTime =
          prayer.time.subtract(Duration(minutes: config.minutesBefore));

      notifications.add(
        _ScheduledNotification(
          id: startNotificationId,
          title: _title(prayer.prayerType),
          body: _body(prayer.prayerType, minutesBefore: config.minutesBefore),
          scheduledTime: notificationTime,
          soundEnabled: config.soundEnabled,
          vibrationEnabled: config.vibrationEnabled,
        ),
      );

      // ── 2. Mosque Jama'ah Jama\'ah Reminder ────────────────────────
      if (prayer.hasJamaah && config.jamaahEnabled) {
        final jamaahNotificationId = _buildId(
          date: prayer.date,
          prayerType: prayer.prayerType,
          idTypeOffset: 200, // offset 200 for Jama'ah times
        );

        final jamaahNotificationTime = prayer.jamaahTime!
            .subtract(Duration(minutes: config.minutesBeforeJamaah));

        notifications.add(
          _ScheduledNotification(
            id: jamaahNotificationId,
            title: '${prayer.prayerType.displayName} Jama\'ah Reminder',
            body:
                'Jama\'ah begins in ${config.minutesBeforeJamaah} minutes at mosque.',
            scheduledTime: jamaahNotificationTime,
            soundEnabled: config.soundEnabled,
            vibrationEnabled: config.vibrationEnabled,
          ),
        );
      }

      // ── 3. Post-Prayer Follow-up Reminder (Premium) ─────────────────────
      if (config.minutesAfter != null && config.minutesAfter! > 0) {
        final postId = _buildId(
          date: prayer.date,
          prayerType: prayer.prayerType,
          idTypeOffset: 500, // offset 500 for post-prayers
        );

        notifications.add(
          _ScheduledNotification(
            id: postId,
            title: '${prayer.prayerType.displayName} Reminder',
            body: 'Have you prayed ${prayer.prayerType.displayName} yet?',
            scheduledTime:
                prayer.time.add(Duration(minutes: config.minutesAfter!)),
            soundEnabled: config.soundEnabled,
            vibrationEnabled: config.vibrationEnabled,
          ),
        );
      }
    }

    return notifications;
  }

  static int _buildId({
    required DateTime date,
    required PrayerType prayerType,
    required int idTypeOffset,
  }) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    final prayerIndex = _prayerIndex(prayerType);
    final base = (dayOfYear * 10) + prayerIndex;
    return base + idTypeOffset;
  }

  static int _prayerIndex(PrayerType type) => switch (type) {
        PrayerType.fajr => 0,
        PrayerType.dhuhr => 1,
        PrayerType.asr => 2,
        PrayerType.maghrib => 3,
        PrayerType.isha => 4,
        PrayerType.sunrise => 9,
      };

  static String _title(PrayerType type) => '${type.displayName} — Time to Pray';

  static String _body(PrayerType type, {required int minutesBefore}) {
    if (minutesBefore == 0) {
      return 'It\'s time for ${type.displayName} prayer.';
    }
    return '${type.displayName} prayer begins in $minutesBefore minutes.';
  }
}
