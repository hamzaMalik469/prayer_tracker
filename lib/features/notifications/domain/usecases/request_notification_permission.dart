library;

import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

final class RequestNotificationPermission implements NoParamsUseCase<bool> {
  const RequestNotificationPermission(this._repository);

  final NotificationRepository _repository;

  @override
  Future<bool> call() => _repository.requestNotificationPermission();
}
