import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Pro state — simple toggle, no real payment yet.
// TODO: replace with RevenueCat entitlement check (monetisation v2)
// ---------------------------------------------------------------------------

class IsProNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setPro({required bool value}) => state = value;
}

/// Whether the current user has an active Pro subscription.
final isProProvider =
    NotifierProvider<IsProNotifier, bool>(IsProNotifier.new);

// ---------------------------------------------------------------------------
// ProGuard — centralises feature gating logic
// ---------------------------------------------------------------------------

class ProGuard {
  const ProGuard({required this.isPro});

  final bool isPro;

  /// Topic filtering in Study mode is Pro-only.
  bool canUseTopicSelection() => isPro;

  /// Speed Drill sessions longer than 10 questions are Pro-only.
  bool canRunLongSpeedDrill() => isPro;
}

final proGuardProvider = Provider<ProGuard>((ref) {
  return ProGuard(isPro: ref.watch(isProProvider));
});
