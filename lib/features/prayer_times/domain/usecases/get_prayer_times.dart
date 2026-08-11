library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../entities/daily_prayer_times_entity.dart';
import '../repositories/prayer_times_repository.dart';

final class GetPrayerTimes
    implements UseCase<DailyPrayerTimesEntity, GetPrayerTimesParams> {
  const GetPrayerTimes(this._repository);

  final PrayerTimesRepository _repository;

  @override
  Future<DailyPrayerTimesEntity> call(GetPrayerTimesParams params) =>
      _repository.getPrayerTimes(
        date: params.date,
        location: params.location,
        settings: params.settings,
      );
}

final class GetPrayerTimesParams extends Equatable {
  const GetPrayerTimesParams({
    required this.date,
    required this.location,
    required this.settings,
  });

  final DateTime date;
  final LocationSettingsEntity location;
  final PrayerSettingsEntity settings;

  @override
  List<Object> get props => [date, location, settings];
}
