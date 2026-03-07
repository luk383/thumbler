import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenue_cat_config.dart';

// ---------------------------------------------------------------------------
// IsProNotifier — AsyncNotifier backed by RevenueCat customer info stream
// ---------------------------------------------------------------------------

class IsProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      // Listen to real-time updates from RevenueCat (v9 API).
      void listener(CustomerInfo info) {
        state = AsyncData(
          info.entitlements.active.containsKey(RevenueCatConfig.entitlementId),
        );
      }
      Purchases.addCustomerInfoUpdateListener(listener);
      ref.onDispose(() => Purchases.removeCustomerInfoUpdateListener(listener));

      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);
    } catch (_) {
      // RevenueCat unavailable (e.g. placeholder key) — default to free.
      return false;
    }
  }

  /// Initiates a purchase for [package]. Throws on non-cancellation errors.
  Future<void> purchase(Package package) async {
    final prev = state.value ?? false;
    state = const AsyncLoading();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      state = AsyncData(
        result.customerInfo.entitlements.active
            .containsKey(RevenueCatConfig.entitlementId),
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      state = AsyncData(prev);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        throw Exception(e.message ?? 'Purchase failed');
      }
    } catch (e) {
      state = AsyncData(prev);
      rethrow;
    }
  }

  /// Restores previous purchases. Throws on error.
  Future<void> restore() async {
    final prev = state.value ?? false;
    state = const AsyncLoading();
    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(
        info.entitlements.active.containsKey(RevenueCatConfig.entitlementId),
      );
    } catch (e) {
      state = AsyncData(prev);
      rethrow;
    }
  }

  /// Dev-only: toggle local Pro state without RevenueCat.
  void devSetPro({required bool value}) {
    assert(!kReleaseMode, 'devSetPro must not be called in release mode');
    state = AsyncData(value);
  }
}

final isProProvider = AsyncNotifierProvider<IsProNotifier, bool>(
  IsProNotifier.new,
);

// ---------------------------------------------------------------------------
// ProGuard — centralises feature gating logic
// ---------------------------------------------------------------------------

class ProGuard {
  const ProGuard({required this.isPro});

  final bool isPro;

  bool canManagePersonalDecks() => isPro;
  bool canImportDecks() => isPro;
  bool canGenerateFromNotes() => isPro;
  bool canCreateDecks() => isPro;
  bool canAccessExamMode() => isPro;
  bool canUseTopicSelection() => isPro;
  bool canRunLongSpeedDrill() => isPro;
}

final proGuardProvider = Provider<ProGuard>((ref) {
  final isPro = ref.watch(isProProvider).value ?? false;
  return ProGuard(isPro: isPro);
});

// ---------------------------------------------------------------------------
// RevenueCat initialisation helper (called from main.dart)
// ---------------------------------------------------------------------------

Future<void> configureRevenueCat() async {
  final apiKey = Platform.isIOS
      ? RevenueCatConfig.iosApiKey
      : RevenueCatConfig.androidApiKey;

  final config = PurchasesConfiguration(apiKey);
  try {
    await Purchases.configure(config);
  } catch (_) {
    // Graceful degradation if key is placeholder or store unavailable.
  }
}
