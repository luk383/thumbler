import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';
import '../../../growth/daily_quest/widgets/daily_quest_modal.dart';
import '../../../growth/daily_quest/widgets/reward_bottom_sheet.dart';
import '../widgets/feed_overlay.dart';
import '../widgets/lesson_card.dart';
import '../controllers/feed_queue_controller.dart';
import '../controllers/feed_controller.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Award XP for the first card shown (page 0 never triggers onPageChanged).
      ref.read(xpProvider.notifier).addXp(XpEvent.viewCard);

      // Show today's quest modal 500ms after first load (once per day).
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final quest = ref.read(dailyQuestProvider);
        if (!quest.modalShownToday && !quest.questCompleted) {
          ref.read(dailyQuestProvider.notifier).markModalShown();
          DailyQuestModal.show(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextCard() async {
    final currentIndex = _currentIndex;
    await ref
        .read(feedQueueProvider.notifier)
        .ensureNextPageAvailable(currentIndex);
    if (!mounted) return;

    final total = ref.read(feedQueueProvider).asData?.value.length ?? 0;
    if (currentIndex >= total - 1) return;

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Listen for a completed quest to show the reward bottom sheet.
    ref.listen(dailyQuestProvider.select((s) => s.pendingReward), (prev, next) {
      if (next != null && prev == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await RewardBottomSheet.show(context, next);
        });
      }
    });

    ref.listen(activeDeckIdProvider, (previous, next) {
      if (previous == next) return;
      ref.read(feedProvider.notifier).reset();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      if (mounted) {
        setState(() => _currentIndex = 0);
      }
    });

    final lessonsAsync = ref.watch(feedQueueProvider);
    final activeDeck = ref.watch(activeDeckMetaProvider);

    return lessonsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            l10n.feedLoadError(error.toString()),
            style: const TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (lessons) {
        final currentLesson = lessons.isEmpty
            ? null
            : lessons[_currentIndex.clamp(0, lessons.length - 1)];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: lessons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: Colors.white38,
                          size: 42,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          activeDeck == null
                              ? l10n.noActiveDeckTitle
                              : l10n.noStudyCardsTitle(activeDeck.title),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noStudyCardsMessage,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // ── Main scrollable feed ──────────────────────────────────
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: lessons.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        unawaited(
                          ref
                              .read(feedQueueProvider.notifier)
                              .ensureNextPageAvailable(index),
                        );
                        ref.read(xpProvider.notifier).addXp(XpEvent.viewCard);
                      },
                      itemBuilder: (context, index) {
                        return LessonCard(
                          key: ValueKey(lessons[index].id),
                          lesson: lessons[index],
                          cardIndex: index,
                          onNext: () => unawaited(_goToNextCard()),
                        );
                      },
                    ),

                    // ── Floating overlay: card counter + quest progress ────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 132,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 16),
                          child: FeedMotivationBanner(
                            currentIndex: _currentIndex,
                            total: lessons.length,
                            currentLesson: currentLesson,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 16),
                          child: FeedOverlay(
                            currentIndex: _currentIndex,
                            total: lessons.length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
