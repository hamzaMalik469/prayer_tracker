library;

import '../../../../core/usecase/usecase.dart';
import '../entities/app_settings_entity.dart';
import '../repositories/settings_repository.dart';

final class WatchSettings implements NoParamsStreamUseCase<AppSettingsEntity> {
  const WatchSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Stream<AppSettingsEntity> call() => _repository.watchSettings();
}
