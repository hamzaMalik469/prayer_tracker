library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_settings_entity.dart';
import '../repositories/settings_repository.dart';

final class SavePrayerSettings
    implements UseCase<void, SavePrayerSettingsParams> {
  const SavePrayerSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<void> call(SavePrayerSettingsParams params) =>
      _repository.savePrayerSettings(params.settings);
}

final class SavePrayerSettingsParams extends Equatable {
  const SavePrayerSettingsParams({required this.settings});

  final PrayerSettingsEntity settings;

  @override
  List<Object> get props => [settings];
}