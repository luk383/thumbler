import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../growth/streak/streak_notifier.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';
import '../../../growth/daily_quest/widgets/daily_quest_modal.dart';
import '../../../growth/daily_quest/widgets/reward_bottom_sheet.dart';
import '../widgets/feed_overlay.dart';
import '../widgets/lesson_card.dart';

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
      ref.read(streakProvider.notifier).recordActivity();

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

  @override
  Widget build(BuildContext context) {
    // Listen for a completed quest to show the reward bottom sheet.
    ref.listen(dailyQuestProvider.select((s) => s.pendingReward), (prev, next) {
      if (next != null && prev == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await RewardBottomSheet.show(context, next);
        });
      }
    });

    final lessonsAsync = ref.watch(lessonsProvider);
    final activeDeck = ref.watch(activeDeckMetaProvider);

    return lessonsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Something went wrong\n$error',
            style: const TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (lessons) => Scaffold(
        backgroundColor: Colors.black,
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
                            ? 'No active deck'
                            : 'No study cards available in ${activeDeck.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select another deck from Library or import a valid pack.',
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
                      ref.read(xpProvider.notifier).addXp(XpEvent.viewCard);
                      ref.read(streakProvider.notifier).recordActivity();
                    },
                    itemBuilder: (context, index) {
                      final isLast = index == lessons.length - 1;
                      return LessonCard(
                        lesson: lessons[index],
                        cardIndex: index,
                        onNext: isLast
                            ? null
                            : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              ),
                      );
                    },
                  ),

                  // ── Floating overlay: card counter + quest progress ────────
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
      ),
    );
  }
}
