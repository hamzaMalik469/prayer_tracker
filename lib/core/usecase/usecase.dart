/// Base use case contracts.
///
/// Every use case in the application implements one of these interfaces.
/// This enforces a consistent call pattern and makes use cases mockable.
library;

import 'package:equatable/equatable.dart';

/// A use case that takes [Params] and returns [Type].
///
/// Use cases that require parameters must implement this.
abstract interface class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// A use case that takes no parameters.
abstract interface class NoParamsUseCase<Type> {
  Future<Type> call();
}

/// A use case that returns a [Stream] of [Type].
abstract interface class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// A use case that returns a [Stream] of [Type] with no parameters.
abstract interface class NoParamsStreamUseCase<Type> {
  Stream<Type> call();
}

/// Sentinel class for use cases that require no parameters.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
