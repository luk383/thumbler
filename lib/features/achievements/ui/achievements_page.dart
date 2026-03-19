import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement.dart';
import '../state/achievements_notifier.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(achievementsProvider);
    final cs = Theme.of(context).colorScheme;

    // Group by category
    final categories = <String, List<Achievement>>{};
    for (final a in allAchievements) {
      categories.putIfAbsent(a.category, () => []).add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Badge (${unlocked.length}/${allAchievements.length})'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: categories.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: entry.value.length,
                itemBuilder: (_, i) {
                  final a = entry.value[i];
                  final isUnlocked = unlocked.contains(a.id);
                  return _BadgeCard(
                    achievement: a,
                    isUnlocked: isUnlocked,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.achievement, required this.isUnlocked});

  final Achievement achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isUnlocked
            ? cs.primaryContainer.withAlpha(120)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: isUnlocked
            ? Border.all(color: cs.primary.withAlpha(100), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.emoji,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : Colors.transparent,
              ),
            ),
            if (!isUnlocked)
              const Icon(Icons.lock_outline, size: 32, color: Colors.grey),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? null : cs.outline,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
