library;

import '../../../../core/usecase/usecase.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/settings_repository.dart';

final class GetSettings implements NoParamsUseCase<AppSettingsEntity> {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<AppSettingsEntity> call() => _repository.getSettings();
}
