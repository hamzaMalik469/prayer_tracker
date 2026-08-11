library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/notification_settings_entity.dart';
import '../repositories/notification_repository.dart';

final class SaveNotificationSettings
    implements UseCase<void, SaveNotificationSettingsParams> {
  const SaveNotificationSettings(this._repository);

  final NotificationRepository _repository;

  @override
  Future<void> call(SaveNotificationSettingsParams params) =>
      _repository.saveNotificationSettings(params.settings);
}

final class SaveNotificationSettingsParams extends Equatable {
  const SaveNotificationSettingsParams({required this.settings});

  final NotificationSettingsEntity settings;

  @override
  List<Object> get props => [settings];
}
