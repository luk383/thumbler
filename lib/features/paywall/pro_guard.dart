import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class IsProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Always return true for Wolf Lab personal use.
    return true;
  }

  Future<void> purchase(Package package) async {
    state = const AsyncData(true);
  }

  Future<void> restore() async {
    state = const AsyncData(true);
  }

  void devSetPro({required bool value}) {
    state = const AsyncData(true);
  }
}

final isProProvider = AsyncNotifierProvider<IsProNotifier, bool>(
  IsProNotifier.new,
);

class ProGuard {
  const ProGuard({required this.isPro});

  final bool isPro;

  bool canManagePersonalDecks() => true;
  bool canImportDecks() => true;
  bool canGenerateFromNotes() => true;
  bool canCreateDecks() => true;
  bool canAccessExamMode() => true;
  bool canUseTopicSelection() => true;
  bool canRunLongSpeedDrill() => true;
}

final proGuardProvider = Provider<ProGuard>((ref) {
  return const ProGuard(isPro: true);
});

Future<void> configureRevenueCat() async {
  // No-op for Wolf Lab personal use.
}