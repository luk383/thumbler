import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../rewards/reward_service.dart';
import '../daily_quest_notifier.dart';
import 'confetti_painter.dart';

class RewardBottomSheet extends ConsumerStatefulWidget {
  const RewardBottomSheet({super.key, required this.reward});

  final RewardType reward;

  /// Show the reward sheet and clear the pending reward when dismissed.
  static Future<void> show(BuildContext context, RewardType reward) {
    final container = ProviderScope.containerOf(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: RewardBottomSheet(reward: reward),
      ),
    );
  }

  @override
  ConsumerState<RewardBottomSheet> createState() => _RewardBottomSheetState();
}

class _RewardBottomSheetState extends ConsumerState<RewardBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<ConfettiParticle> _particles;
  bool _rewardVisible = false;

  @override
  void initState() {
    super.initState();
    _particles = ConfettiParticle.generate(60);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Staggered reveal: confetti first, then reward card fades in.
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _rewardVisible = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12101F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Confetti overlay ────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: ConfettiPainter(
                  progress: _controller.value,
                  particles: _particles,
                ),
              ),
            ),
          ),

          // ── Sheet content ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Trophy emoji
                  const Text('🏆', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.questComplete,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reward card (animated reveal)
                  AnimatedOpacity(
                    opacity: _rewardVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      offset: _rewardVisible
                          ? Offset.zero
                          : const Offset(0, 0.15),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: _RewardCard(reward: widget.reward),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(dailyQuestProvider.notifier)
                            .clearPendingReward();
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.claimReward),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward});

  final RewardType reward;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2560), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(120)),
      ),
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rewardTitle(reward.key),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.rewardDescription(reward.key),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
