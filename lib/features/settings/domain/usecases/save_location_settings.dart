library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/location_settings_entity.dart';
import '../repositories/settings_repository.dart';

final class SaveLocationSettings
    implements UseCase<void, SaveLocationSettingsParams> {
  const SaveLocationSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<void> call(SaveLocationSettingsParams params) =>
      _repository.saveLocationSettings(params.settings);
}

final class SaveLocationSettingsParams extends Equatable {
  const SaveLocationSettingsParams({required this.settings});

  final LocationSettingsEntity settings;

  @override
  List<Object> get props => [settings];
}
