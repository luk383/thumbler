/// RevenueCat configuration constants.
///
/// Replace the placeholder API keys with the ones from the RevenueCat dashboard:
/// https://app.revenuecat.com → Project → API keys
///
/// The entitlement ID must match the one you create in RevenueCat
/// (e.g. Dashboard → Entitlements → "pro").
class RevenueCatConfig {
  /// iOS public SDK key (starts with "appl_")
  static const String iosApiKey = 'appl_REPLACE_ME';

  /// Android public SDK key (starts with "goog_")
  static const String androidApiKey = 'goog_REPLACE_ME';

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const String entitlementId = 'pro';
}
