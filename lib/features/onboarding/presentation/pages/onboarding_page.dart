import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/ui/app_surfaces.dart';
import '../../../study/data/deck_library_storage.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  final _selectedInterests = <String>{'Cybersecurity'};
  var _pageIndex = 0;
  var _isFinishing = false;

  static const _interests = [
    'Cybersecurity',
    'Cloud',
    'Technology',
    'Science',
    'History',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _isFinishing = true);
    const storage = DeckLibraryStorage();
    try {
      await storage.saveOnboardingInterests(
        _selectedInterests.toList(growable: false),
      );
      await ref
          .read(deckLibraryProvider.notifier)
          .chooseDeckForInterests(_selectedInterests.toList(growable: false));
      await storage.saveOnboardingComplete(true);
      if (!mounted) return;
      context.go('/');
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _pageIndex = value),
                children: [
                  _OnboardingStep(
                    title: l10n.onboardingHeroTitle,
                    subtitle: l10n.onboardingHeroSubtitle,
                    child: const _HeroCard(),
                  ),
                  _OnboardingStep(
                    title: l10n.onboardingInterestsTitle,
                    subtitle: l10n.onboardingInterestsSubtitle,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _interests
                          .map(
                            (interest) => FilterChip(
                              label: Text(interest),
                              selected: _selectedInterests.contains(interest),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedInterests.add(interest);
                                  } else if (_selectedInterests.length > 1) {
                                    _selectedInterests.remove(interest);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pageIndex == 0)
                    TextButton(
                      onPressed: _finish,
                      child: Text(l10n.onboardingSkip),
                    ),
                  FilledButton(
                    onPressed: _isFinishing
                        ? null
                        : (_pageIndex == 0 ? _nextPage : _finish),
                    child: _isFinishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _pageIndex == 0
                                ? l10n.onboardingStartLearning
                                : l10n.onboardingStartFeed,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageIntro(title: title, subtitle: subtitle),
          const SizedBox(height: 28),
          AppGlassCard(
            padding: const EdgeInsets.all(22),
            radius: 28,
            tint: const Color(0xFF6C63FF),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStatusBadge(
          label: l10n.onboardingBadge,
          icon: Icons.bolt_rounded,
          tint: const Color(0xFFADA8FF),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingHeroBody,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingHeroFoot,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
