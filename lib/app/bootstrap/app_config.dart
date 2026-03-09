/// Identifies the runtime environment the app is operating in.
enum Environment {
  /// Local development — verbose logging, debug tools enabled.
  dev,

  /// Production release — minimal logging, no debug tooling.
  prod,
}

/// Immutable configuration holder populated once at startup.
///
/// Extend this class with environment-specific values (API base URLs, feature
/// flags, timeouts) as the project grows. Keep it free of business logic.
final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.version,
  });

  final Environment environment;

  /// Display name of the application.
  final String appName;

  /// Semantic version string (e.g. "1.0.0+42").
  final String version;

  /// Convenience getter — `true` when running in development.
  bool get isDev => environment == Environment.dev;

  /// Convenience getter — `true` when running in production.
  bool get isProd => environment == Environment.prod;

  @override
  String toString() =>
      'AppConfig(env: ${environment.name}, app: $appName, version: $version)';
}
