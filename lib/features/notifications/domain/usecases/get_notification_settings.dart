library;

import '../../../../core/usecase/usecase.dart';
import '../entities/notification_settings_entity.dart';
import '../repositories/notification_repository.dart';

final class GetNotificationSettings
    implements NoParamsUseCase<NotificationSettingsEntity> {
  const GetNotificationSettings(this._repository);

  final NotificationRepository _repository;

  @override
  Future<NotificationSettingsEntity> call() =>
      _repository.getNotificationSettings();
}
