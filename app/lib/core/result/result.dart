import 'package:timefocus/core/errors/app_failure.dart';

Result<R> success<R>(R value) => Result.success(value);
Result<R> failure<R>(AppFailure error) => Result.failure(error);

/// A class that represents the result of an operation, which can be either
/// a success or a failure.
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result], completed with the specified [value].
  const factory Result.success(T value) = Success<T>._;

  /// Creates an error [Result], completed with the specified [error].
  const factory Result.failure(AppFailure error) = Failure<T>._;

  /// Converts the result to another type.
  R map<R>({
    required R Function(T value) success,
    required R Function(AppFailure error) failure,
  }) => switch (this) {
    Success(:final value) => success(value),
    Failure(:final error) => failure(error),
  };

  R match<R>({
    required R Function(T value) success,
    required R Function(AppFailure error) failure,
  }) => map(success: success, failure: failure);

  R fold<R>({
    required R Function(T value) success,
    required R Function(AppFailure error) failure,
  }) => map(success: success, failure: failure);

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the value if the result is successful, otherwise returns null.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  /// Returns the error if the result is unsuccessful, otherwise returns null.
  AppFailure? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };
}

/// Subclass of Result for values
final class Success<T> extends Result<T> {
  const Success._(this.value);

  /// Returned value in result
  final T value;

  @override
  String toString() => '$value';
}

/// Subclass of Result for errors
final class Failure<E> extends Result<E> {
  const Failure._(this.error);

  /// Returned error in result
  final AppFailure error;

  @override
  String toString() => 'Error: $error';
}
