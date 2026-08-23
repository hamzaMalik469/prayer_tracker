library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times_entity.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../repositories/notification_repository.dart';

final class SchedulePrayerNotifications
    implements UseCase<void, SchedulePrayerNotificationsParams> {
  const SchedulePrayerNotifications(this._repository);

  final NotificationRepository _repository;

  @override
  Future<void> call(SchedulePrayerNotificationsParams params) =>
      _repository.scheduleNotifications(
        prayerTimes: params.prayerTimes,
        settings: params.settings,
        unrecordedPrayersToday: params.unrecordedPrayersToday,
        currentStreak: params.currentStreak,
        todayCompleted: params.todayCompleted,
      );
}

final class SchedulePrayerNotificationsParams extends Equatable {
  const SchedulePrayerNotificationsParams({
    required this.prayerTimes,
    required this.settings,
    this.unrecordedPrayersToday = const [],
    this.currentStreak = 0,
    this.todayCompleted = false,
  });

  final DailyPrayerTimesEntity prayerTimes;
  final NotificationSettingsEntity settings;
  final List<String> unrecordedPrayersToday;
  final int currentStreak;
  final bool todayCompleted;

  @override
  List<Object> get props => [
        prayerTimes,
        settings,
        unrecordedPrayersToday,
        currentStreak,
        todayCompleted,
      ];
}
