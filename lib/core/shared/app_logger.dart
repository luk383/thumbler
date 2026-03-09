// ignore_for_file: avoid_print

/// Severity levels used by [AppLogger].
enum LogLevel { debug, info, warning, error }

/// Contract for application-wide logging.
///
/// Depend on this abstraction in feature and core code. Swap the concrete
/// implementation (e.g. remote crash reporter) without touching callers.
abstract interface class AppLogger {
  /// Fine-grained diagnostic information, typically only useful in dev.
  void debug(String message, {Object? error, StackTrace? stackTrace});

  /// General operational events (startup, feature toggled, …).
  void info(String message, {Object? error, StackTrace? stackTrace});

  /// Something unexpected happened but the app can continue.
  void warning(String message, {Object? error, StackTrace? stackTrace});

  /// A serious problem that likely impacts the user or data integrity.
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// Lightweight logger that writes to the standard console output.
///
/// Suitable for development and testing. Replace with a production logger
/// (e.g. wrapping a crash-reporting SDK) via [DependencyContainer].
final class ConsoleLogger implements AppLogger {
  const ConsoleLogger();

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error, stackTrace);

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error, stackTrace);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error, stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO ]',
      LogLevel.warning => '[WARN ]',
      LogLevel.error => '[ERROR]',
    };

    print('$prefix $message');
    if (error != null) print('       error: $error');
    if (stackTrace != null) print('       stack: $stackTrace');
  }
}
