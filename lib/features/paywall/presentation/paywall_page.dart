import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/ui/app_surfaces.dart';
import '../pro_guard.dart';

void openPaywall(BuildContext context, {required String featureName}) {
  final encodedFeature = Uri.encodeComponent(featureName);
  context.push('/pro?feature=$encodedFeature');
}

// ---------------------------------------------------------------------------
// Offerings provider
// ---------------------------------------------------------------------------

final _offeringsProvider = FutureProvider.autoDispose<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// PaywallPage
// ---------------------------------------------------------------------------

class PaywallPage extends ConsumerWidget {
  const PaywallPage({
    super.key,
    this.featureName,
    this.title = 'Unlock Thumbler Pro',
    this.subtitle,
  });

  final String? featureName;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isPro = ref.watch(isProProvider).value ?? false;
    final featureLabel = featureName ?? 'premium learning tools';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            AppPageIntro(
              title: title == 'Unlock Thumbler Pro' ? l10n.paywallTitle : title,
              subtitle: subtitle ?? l10n.paywallSubtitle(featureLabel),
              trailing: AppStatusBadge(
                label: isPro ? l10n.paywallProActive : l10n.paywallProFeature,
                icon: isPro ? Icons.check_circle_outline : Icons.lock_outline,
                tint: isPro ? const Color(0xFF12B981) : const Color(0xFFADA8FF),
              ),
            ),
            const SizedBox(height: 20),
            const _PaywallHero(),
            const SizedBox(height: 18),
            const _FeatureListCard(),
            const SizedBox(height: 18),
            if (isPro)
              _ProActiveCard()
            else
              _OfferingsSection(featureLabel: featureLabel),
            // Dev-only toggle (hidden in release builds)
            if (!kReleaseMode) ...[
              const SizedBox(height: 18),
              AppGlassCard(
                padding: const EdgeInsets.all(18),
                tint: Colors.orangeAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Developer Shortcut',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Local-only toggle for testing premium flows.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(isProProvider.notifier)
                              .devSetPro(value: !isPro);
                        },
                        icon: Icon(isPro ? Icons.toggle_on : Icons.toggle_off),
                        label: Text(
                          isPro ? 'Disable local Pro' : 'Enable local Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero + feature list (unchanged from original)
// ---------------------------------------------------------------------------

class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(22),
      radius: 26,
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusBadge(
            label: l10n.paywallHeroBadge,
            icon: Icons.bolt_rounded,
            tint: const Color(0xFFADA8FF),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.paywallHeroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.paywallHeroBody,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureListCard extends StatelessWidget {
  const _FeatureListCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final perks = [
      (
        icon: Icons.file_upload_outlined,
        title: l10n.paywallImportDecksTitle,
        copy: l10n.paywallImportDecksCopy,
      ),
      (
        icon: Icons.note_alt_outlined,
        title: l10n.paywallGenerateNotesTitle,
        copy: l10n.paywallGenerateNotesCopy,
      ),
      (
        icon: Icons.draw_outlined,
        title: l10n.paywallCreateDecksTitle,
        copy: l10n.paywallCreateDecksCopy,
      ),
      (
        icon: Icons.assignment_outlined,
        title: l10n.paywallExamModeTitle,
        copy: l10n.paywallExamModeCopy,
      ),
    ];

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paywallWhatProUnlocks,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (final perk in perks) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSurfaceIcon(
                  icon: perk.icon,
                  tint: const Color(0xFF6C63FF),
                  size: 36,
                  iconSize: 17,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perk.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        perk.copy,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (perk != perks.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pro already active card
// ---------------------------------------------------------------------------

class _ProActiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      tint: const Color(0xFF12B981),
      child: Row(
        children: [
          const AppSurfaceIcon(
            icon: Icons.verified_outlined,
            tint: Color(0xFF12B981),
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.paywallProActive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.paywallProActiveBody,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offerings section — loads packages from RevenueCat
// ---------------------------------------------------------------------------

class _OfferingsSection extends ConsumerWidget {
  const _OfferingsSection({required this.featureLabel});

  final String featureLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(_offeringsProvider);

    return offeringsAsync.when(
      loading: () => const AppGlassCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, s) => _OffersUnavailableCard(featureLabel: featureLabel),
      data: (offerings) {
        final packages = offerings?.current?.availablePackages ?? [];
        if (packages.isEmpty) {
          return _OffersUnavailableCard(featureLabel: featureLabel);
        }
        return Column(
          children: [
            for (final pkg in packages) ...[
              _PackageCard(package: pkg),
              const SizedBox(height: 12),
            ],
            _RestoreButton(),
          ],
        );
      },
    );
  }
}

class _PackageCard extends ConsumerStatefulWidget {
  const _PackageCard({required this.package});

  final Package package;

  @override
  ConsumerState<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends ConsumerState<_PackageCard> {
  bool _loading = false;

  String _periodLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.package.packageType) {
      PackageType.monthly => l10n.paywallMonthly,
      PackageType.annual => l10n.paywallAnnual,
      PackageType.lifetime => l10n.paywallLifetime,
      _ => widget.package.identifier,
    };
  }

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      await ref.read(isProProvider.notifier).purchase(widget.package);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final product = widget.package.storeProduct;

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      tint: const Color(0xFF6C63FF),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodLabel(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceString,
                  style: const TextStyle(
                    color: Color(0xFFADA8FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _loading ? null : _purchase,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.paywallSubscribe),
          ),
        ],
      ),
    );
  }
}

class _RestoreButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<_RestoreButton> {
  bool _loading = false;

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      await ref.read(isProProvider.notifier).restore();
      if (mounted) {
        final isPro = ref.read(isProProvider).value ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPro ? context.l10n.paywallRestored : context.l10n.paywallNothingToRestore,
            ),
            backgroundColor: isPro ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: _loading ? null : _restore,
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                context.l10n.paywallRestorePurchases,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
      ),
    );
  }
}

class _OffersUnavailableCard extends StatelessWidget {
  const _OffersUnavailableCard({required this.featureLabel});

  final String featureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      tint: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paywallOffersUnavailableTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.paywallOffersUnavailableBody,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
