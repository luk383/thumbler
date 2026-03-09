/// Base class for all domain-level failures.
///
/// Failures are typed errors that propagate through layers without throwing
/// exceptions. Each subtype signals a distinct failure category so callers
/// can react appropriately.
abstract class Failure {
  const Failure({required this.message, this.code});

  /// Human-readable description of what went wrong.
  final String message;

  /// Optional machine-readable code (e.g. HTTP status, DB error code).
  final String? code;

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Input did not satisfy business or format rules.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// A persistence operation failed (read, write, migration, …).
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

/// A remote call failed due to connectivity, timeout, or a server error.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// The current user is not authenticated or lacks the required permission.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Catch-all for failures that do not fit any specific category.
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code});
}
