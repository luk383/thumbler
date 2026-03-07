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
final isProProvider = NotifierProvider<IsProNotifier, bool>(IsProNotifier.new);

// ---------------------------------------------------------------------------
// ProGuard — centralises feature gating logic
// ---------------------------------------------------------------------------

class ProGuard {
  const ProGuard({required this.isPro});

  final bool isPro;

  /// Personal deck creation and imports are Pro-only.
  bool canManagePersonalDecks() => isPro;

  /// JSON deck imports are Pro-only.
  bool canImportDecks() => isPro;

  /// Notes-to-deck generation is Pro-only.
  bool canGenerateFromNotes() => isPro;

  /// Manual deck creation is Pro-only.
  bool canCreateDecks() => isPro;

  /// Exam mode is Pro-only in the public launch build.
  bool canAccessExamMode() => isPro;

  /// Topic filtering in Study mode is Pro-only.
  bool canUseTopicSelection() => isPro;

  /// Speed Drill sessions longer than 10 questions are Pro-only.
  bool canRunLongSpeedDrill() => isPro;
}

final proGuardProvider = Provider<ProGuard>((ref) {
  return ProGuard(isPro: ref.watch(isProProvider));
});
