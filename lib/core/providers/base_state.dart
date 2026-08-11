library;

sealed class BaseState<T> {
  const BaseState();
}

final class InitialState<T> extends BaseState<T> {
  const InitialState();
}

final class LoadingState<T> extends BaseState<T> {
  const LoadingState();
}

final class SuccessState<T> extends BaseState<T> {
  const SuccessState(this.data);
  final T data;
}

final class ErrorState<T> extends BaseState<T> {
  const ErrorState(this.message);
  final String message;
}

extension BaseStateExtension<T> on BaseState<T> {
  bool get isInitial => this is InitialState<T>;
  bool get isLoading => this is LoadingState<T>;
  bool get isSuccess => this is SuccessState<T>;
  bool get isError => this is ErrorState<T>;

  T? get dataOrNull => switch (this) {
        SuccessState<T> s => s.data,
        _ => null,
      };

  String? get errorOrNull => switch (this) {
        ErrorState<T> e => e.message,
        _ => null,
      };
}
