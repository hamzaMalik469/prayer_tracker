library;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times_entity.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/cancel_all_notifications.dart';
import '../../domain/usecases/get_notification_settings.dart';
import '../../domain/usecases/request_notification_permission.dart';
import '../../domain/usecases/save_notification_settings.dart';
import '../../domain/usecases/schedule_prayer_notifications.dart';

final class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    required NotificationRepository repository,
    required GetNotificationSettings getNotificationSettings,
    required SaveNotificationSettings saveNotificationSettings,
    required SchedulePrayerNotifications schedulePrayerNotifications,
    required CancelAllNotifications cancelAllNotifications,
    required RequestNotificationPermission requestNotificationPermission,
  })  : _repository = repository,
        _getNotificationSettings = getNotificationSettings,
        _saveNotificationSettings = saveNotificationSettings,
        _schedulePrayerNotifications = schedulePrayerNotifications,
        _cancelAllNotifications = cancelAllNotifications,
        _requestPermission = requestNotificationPermission;

  final NotificationRepository _repository;
  final GetNotificationSettings _getNotificationSettings;
  final SaveNotificationSettings _saveNotificationSettings;
  final SchedulePrayerNotifications _schedulePrayerNotifications;
  final CancelAllNotifications _cancelAllNotifications;
  final RequestNotificationPermission _requestPermission;

  NotificationSettingsEntity _settings = NotificationSettingsEntity.defaults();
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  NotificationSettingsEntity get settings => _settings;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get masterEnabled => _settings.masterEnabled;
  String? get errorMessage => _errorMessage;

  Future<void> initialise() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _getNotificationSettings();
      _hasPermission = await _repository.hasNotificationPermission();
    } catch (e) {
      AppLogger.error('Failed to initialise notifications',
          error: e, tag: 'NotificationProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPermission() async {
    try {
      _hasPermission = await _requestPermission();
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      AppLogger.error('Permission request failed',
          error: e, tag: 'NotificationProvider');
      return false;
    }
  }

  /// Calculates dynamic indicators and schedules notifications.
  Future<void> scheduleForDays({
    required DailyPrayerTimesEntity today,
    required DailyPrayerTimesEntity tomorrow,
    DailyPrayerSummaryEntity? todaySummary,
    int currentStreak = 0,
  }) async {
    if (!_settings.masterEnabled || !_hasPermission) return;

    try {
      await _cancelAllNotifications();

      // Determine unrecorded prayers & completeness for today
      final List<String> unrecordedList = [];
      bool todayCompleted = false;

      if (todaySummary != null) {
        todayCompleted = todaySummary.isFullyCompleted;
        for (final type in PrayerTypeExtension.obligatory) {
          if (todaySummary.statusFor(type) == PrayerStatus.notRecorded) {
            unrecordedList.add(type.displayName);
          }
        }
      } else {
        // Fallback if no summary is loaded yet
        unrecordedList
            .addAll(PrayerTypeExtension.obligatory.map((t) => t.displayName));
      }

      // Schedule today (with tracking check and streak saver)
      await _schedulePrayerNotifications(
        SchedulePrayerNotificationsParams(
          prayerTimes: today,
          settings: _settings,
          unrecordedPrayersToday: unrecordedList,
          currentStreak: currentStreak,
          todayCompleted: todayCompleted,
        ),
      );

      // Schedule tomorrow (standard core alarms only)
      await _schedulePrayerNotifications(
        SchedulePrayerNotificationsParams(
          prayerTimes: tomorrow,
          settings: _settings,
          unrecordedPrayersToday: const [],
          currentStreak: 0,
          todayCompleted: true, // Suppress streak protector for tomorrow
        ),
      );

      AppLogger.info('Notifications rescheduled with current tracking checks.',
          tag: 'NotificationProvider');
    } catch (e) {
      AppLogger.error('Failed to schedule notifications',
          error: e, tag: 'NotificationProvider');
      _errorMessage = 'Could not schedule prayer notifications.';
      notifyListeners();
    }
  }

  Future<void> setMasterEnabled({required bool enabled}) async {
    _settings = _settings.copyWith(masterEnabled: enabled);
    notifyListeners();
    await _saveNotificationSettings(
      SaveNotificationSettingsParams(settings: _settings),
    );
    if (!enabled) {
      await _cancelAllNotifications();
    }
  }

  Future<void> updatePrayerConfig({
    required PrayerNotificationConfig config,
    DailyPrayerTimesEntity? todayTimes,
    DailyPrayerTimesEntity? tomorrowTimes,
    DailyPrayerSummaryEntity? todaySummary,
    int currentStreak = 0,
  }) async {
    final updatedConfigs =
        Map<PrayerType, PrayerNotificationConfig>.from(_settings.prayerConfigs);
    updatedConfigs[config.prayerType] = config;

    _settings = _settings.copyWith(prayerConfigs: updatedConfigs);
    notifyListeners();

    await _saveNotificationSettings(
      SaveNotificationSettingsParams(settings: _settings),
    );

    if (todayTimes != null && tomorrowTimes != null) {
      await scheduleForDays(
        today: todayTimes,
        tomorrow: tomorrowTimes,
        todaySummary: todaySummary,
        currentStreak: currentStreak,
      );
    }
  }

  Future<void> rescheduleAfterSettingsChange({
    required DailyPrayerTimesEntity today,
    required DailyPrayerTimesEntity tomorrow,
    DailyPrayerSummaryEntity? todaySummary,
    int currentStreak = 0,
  }) =>
      scheduleForDays(
        today: today,
        tomorrow: tomorrow,
        todaySummary: todaySummary,
        currentStreak: currentStreak,
      );

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
