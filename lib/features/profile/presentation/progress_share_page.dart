import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../achievements/domain/achievement.dart';
import '../../achievements/state/achievements_notifier.dart';
import '../../growth/streak/streak_notifier.dart';
import '../../growth/xp/xp_notifier.dart';

class ProgressSharePage extends ConsumerStatefulWidget {
  const ProgressSharePage({super.key});

  @override
  ConsumerState<ProgressSharePage> createState() => _ProgressSharePageState();
}

class _ProgressSharePageState extends ConsumerState<ProgressSharePage> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/progress_card.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la condivisione: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = ref.watch(xpProvider);
    final streak = ref.watch(streakProvider);
    final unlockedIds = ref.watch(achievementsProvider);
    final totalAchievements = allAchievements.length;

    final level = xp.totalXp ~/ 100;
    final unlockedList = allAchievements
        .where((a) => unlockedIds.contains(a.id))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Condividi progresso',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _sharing ? null : _shareCard,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_outlined, color: Colors.white),
            label: const Text('Condividi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: _boundaryKey,
            child: _ProgressCard(
              totalXp: xp.totalXp,
              level: level,
              streak: streak.currentStreak,
              unlockedCount: unlockedIds.length,
              totalAchievements: totalAchievements,
              topAchievements: unlockedList,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.unlockedCount,
    required this.totalAchievements,
    required this.topAchievements,
  });

  final int totalXp;
  final int level;
  final int streak;
  final int unlockedCount;
  final int totalAchievements;
  final List<Achievement> topAchievements;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF3D3580),
            Color(0xFF0A0C11),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withAlpha(80),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name header
            Row(
              children: [
                const Text('🐺', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                const Text(
                  'Wolf Lab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // XP and level row
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    emoji: '⚡',
                    value: '$totalXp XP',
                    label: 'Totale XP',
                  ),
                ),
                Expanded(
                  child: _StatBlock(
                    emoji: '🏅',
                    value: 'Lv. $level',
                    label: 'Livello',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Streak and achievements row
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    emoji: '🔥',
                    value: '$streak giorni',
                    label: 'Streak',
                  ),
                ),
                Expanded(
                  child: _StatBlock(
                    emoji: '🏆',
                    value: '$unlockedCount / $totalAchievements',
                    label: 'Badge',
                  ),
                ),
              ],
            ),

            // Top achievements
            if (topAchievements.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Badge sbloccati',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: topAchievements.map((a) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(a.emoji,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                a.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Footer
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withAlpha(30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Studia ogni giorno. Diventa imbattibile.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
