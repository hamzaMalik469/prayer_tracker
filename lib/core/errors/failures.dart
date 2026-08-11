library;

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure()
      : super(message: 'You must be signed in to perform this action.');
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'A network error occurred.', super.code});
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

final class SyncFailure extends Failure {
  const SyncFailure({required super.message, super.code});
}

final class LocationFailure extends Failure {
  const LocationFailure({required super.message, super.code});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

final class PrayerCalculationFailure extends Failure {
  const PrayerCalculationFailure({required super.message, super.code});
}

final class NotificationFailure extends Failure {
  const NotificationFailure({required super.message, super.code});
}

final class SubscriptionFailure extends Failure {
  const SubscriptionFailure({required super.message, super.code});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code,
  });
}
