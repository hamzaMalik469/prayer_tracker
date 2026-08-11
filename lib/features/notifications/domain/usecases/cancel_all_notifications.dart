library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

final class CancelAllNotifications implements NoParamsUseCase<void> {
  const CancelAllNotifications(this._repository);

  final NotificationRepository _repository;

  @override
  Future<void> call() => _repository.cancelAllNotifications();
}
