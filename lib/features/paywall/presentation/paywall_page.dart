import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/ui/app_surfaces.dart';
import '../pro_guard.dart';

void openPaywall(BuildContext context, {required String featureName}) {
  final encodedFeature = Uri.encodeComponent(featureName);
  context.push('/pro?feature=$encodedFeature');
}

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
    final isPro = ref.watch(isProProvider);
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
            _PricingCard(featureLabel: featureLabel),
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
                      'Local-only toggle for testing premium flows before RevenueCat is wired in.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(isProProvider.notifier)
                              .setPro(value: !isPro);
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

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.featureLabel});

  final String featureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      tint: const Color(0xFF12B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paywallWiringTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.paywallWiringBody(featureLabel),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_open_outlined),
              label: Text(l10n.paywallPurchaseComing),
            ),
          ),
        ],
      ),
    );
  }
}
