/// Minimal service-locator that avoids any third-party dependency.
///
/// Use [DependencyContainer] during app bootstrap to wire concrete
/// implementations to their abstractions. Features resolve dependencies through
/// the shared singleton [instance] without coupling to specific classes.
///
/// When the project grows and a richer DI solution is needed (e.g. get_it,
/// injectable), this class can be replaced without touching call-sites that
/// already program against abstract types.
final class DependencyContainer {
  DependencyContainer._();

  /// The single shared container for the lifetime of the application.
  static final DependencyContainer instance = DependencyContainer._();

  final Map<Type, Object> _registry = {};

  /// Registers [instance] as the implementation for type [T].
  ///
  /// Overwrites any previous registration for [T].
  void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  /// Returns the registered instance for type [T].
  ///
  /// Throws [StateError] if [T] was never registered — a misconfiguration
  /// that should be caught during development, not silently swallowed.
  T resolve<T extends Object>() {
    final instance = _registry[T];
    if (instance == null) {
      throw StateError(
        'DependencyContainer: no registration found for $T. '
        'Did you forget to call register<$T>() in bootstrap?',
      );
    }
    return instance as T;
  }

  /// Removes all registrations. Useful for resetting state between tests.
  void reset() => _registry.clear();
}
