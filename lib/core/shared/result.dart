import 'failure.dart';

/// A discriminated union representing either a successful value [T] or a
/// [Failure]. Prefer returning [Result] over throwing exceptions in domain
/// and data layers.
sealed class Result<T> {
  const Result();

  /// Returns `true` when this result holds a value.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` when this result holds a failure.
  bool get isFailure => this is FailureResult<T>;

  /// Exhaustive pattern-match over the two possible states.
  ///
  /// ```dart
  /// result.when(
  ///   success: (value) => print(value),
  ///   failure: (f) => print(f.message),
  /// );
  /// ```
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      FailureResult<T>(failure: final f) => failure(f),
    };
  }

  /// Transforms the success value while leaving a failure untouched.
  ///
  /// ```dart
  /// final lengths = result.map((s) => s.length);
  /// ```
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Success(transform(value)),
      FailureResult<T>(:final failure) => FailureResult(failure),
    };
  }
}

/// The successful branch of [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// The failure branch of [Result].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}

/// Represents the absence of a meaningful return value.
///
/// Use [Result<Unit>] instead of [Result<void>] to keep generic type
/// parameters concrete. Return [Unit.value] inside a [Success]:
/// ```dart
/// return const Success(Unit.value);
/// ```
final class Unit {
  const Unit._();

  /// The singleton instance.
  static const Unit value = Unit._();
}
