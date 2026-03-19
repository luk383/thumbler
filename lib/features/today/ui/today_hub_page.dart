import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/growth/streak/streak_notifier.dart';
import '../../../features/growth/xp/xp_notifier.dart';
import '../../../features/habits/state/habits_notifier.dart';
import '../../../features/goals/state/goals_notifier.dart';
import '../../../features/reflection/domain/reflection_entry.dart';
import '../../../features/reflection/state/reflection_notifier.dart';
import '../../../features/habits/domain/habit.dart';
import '../../../features/achievements/state/achievements_notifier.dart';
import '../../../features/study/presentation/controllers/study_controller.dart';

class TodayHubPage extends ConsumerWidget {
  const TodayHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider);
    final streak = ref.watch(streakProvider);
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider).where((g) => !g.completed).toList();
    final studyState = ref.watch(studyProvider);
    final reflections = ref.watch(reflectionProvider);

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Buongiorno'
        : hour < 18
            ? 'Buon pomeriggio'
            : 'Buonasera';

    final doneHabits = habits.where((h) => h.isDoneToday).length;
    final dueCards = studyState.dueCount;
    final ws = ReflectionEntry.currentWeekStart();
    final hasReflection = reflections.any(
      (r) => r.weekStart.isAtSameMomentAs(ws) && !r.isEmpty,
    );

    // Check for new achievements once per build (debounced by Hive comparison)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newBadges = ref.read(achievementsProvider.notifier).checkAndUnlock();
      if (newBadges.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🏆 Badge sbloccato: ${newBadges.map((b) => b.title).join(', ')}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(greeting),
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: _XpBar(xp: xp),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList.list(children: [
              // ── Study due cards ──────────────────────────────────────────
              _SectionCard(
                icon: Icons.school_outlined,
                label: 'Studio',
                trailing: dueCards > 0
                    ? _Badge('$dueCards da ripassare')
                    : const _Badge('In pari!', color: Colors.green),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.psychology_outlined,
                            label: 'Ripassa ora',
                            subtitle: dueCards > 0 ? '$dueCards carte' : 'In pari!',
                            onTap: () => context.go('/study'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.bolt,
                            label: 'Speed run',
                            subtitle: 'Allena la velocità',
                            onTap: () =>
                                context.go('/study?mode=speed&autostart=true'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.layers_outlined,
                            label: 'Feed',
                            subtitle: 'Scorri le carte',
                            onTap: () => context.push('/feed'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.timer_outlined,
                            label: 'Pomodoro',
                            subtitle: 'Focus timer',
                            onTap: () => context.push('/pomodoro'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Streak ───────────────────────────────────────────────────
              _SectionCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Streak',
                trailing: streak.currentStreak > 0
                    ? _Badge('🔥 ${streak.currentStreak} giorni')
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '${streak.answeredToday}',
                        label: 'Risposte oggi',
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        value: streak.completedToday ? '✅' : '${streak.remainingToday} rimaste',
                        label: streak.completedToday
                            ? 'Obiettivo giornaliero'
                            : 'Per completare oggi',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Habits ───────────────────────────────────────────────────
              if (habits.isNotEmpty)
                _SectionCard(
                  icon: Icons.check_circle_outline,
                  label: 'Abitudini',
                  onHeaderTap: () => context.push('/habits'),
                  trailing: _Badge(
                    '$doneHabits/${habits.length}',
                    color: doneHabits == habits.length
                        ? Colors.green
                        : Colors.orange,
                  ),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: habits.isEmpty
                            ? 0
                            : doneHabits / habits.length,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 10),
                      ...habits.take(4).map((h) => _HabitRow(h)),
                      if (habits.length > 4)
                        TextButton(
                          onPressed: () => context.push('/habits'),
                          child: Text('+ ${habits.length - 4} altre abitudini'),
                        ),
                    ],
                  ),
                ),

              if (habits.isNotEmpty) const SizedBox(height: 12),

              // ── Goals ────────────────────────────────────────────────────
              if (goals.isNotEmpty)
                _SectionCard(
                  icon: Icons.flag_outlined,
                  label: 'Obiettivi attivi',
                  onHeaderTap: () => context.push('/goals'),
                  trailing: _Badge('${goals.length}'),
                  child: Column(
                    children: goals.take(3).map((g) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(g.area.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      overflow: TextOverflow.ellipsis),
                                  if (g.milestones.isNotEmpty)
                                    LinearProgressIndicator(
                                      value: g.progress,
                                      borderRadius: BorderRadius.circular(2),
                                      minHeight: 4,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(g.progress * 100).round()}%',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              if (goals.isNotEmpty) const SizedBox(height: 12),

              // ── Reflection reminder ──────────────────────────────────────
              if (!hasReflection)
                _SectionCard(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Riflessione settimanale',
                  onHeaderTap: () => context.push('/reflection'),
                  trailing: const _Badge('Da fare', color: Colors.orange),
                  child: GestureDetector(
                    onTap: () => context.push('/reflection'),
                    child: Text(
                      'Tocca per riflettere sulla settimana →',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  const _XpBar({required this.xp});
  final XpState xp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (xp.dailyXp / dailyGoal).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('⚡ ${xp.dailyXp} / $dailyGoal XP oggi',
                style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text('Totale: ${xp.totalXp} XP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    )),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
          color: cs.primary,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.onHeaderTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onHeaderTap,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(label,
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  ?trailing,
                  if (onHeaderTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: cs.outline),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center),
        ],
      );
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow(this.habit);
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = habit.isDoneToday;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? cs.outline : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(habitsProvider.notifier).toggleToday(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: done ? cs.primary : cs.outline,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
