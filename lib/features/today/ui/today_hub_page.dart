import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/settings/app_settings.dart';
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
    final settings = ref.watch(appSettingsProvider);
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
    final weakCards = studyState.weakCount;
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
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Cerca',
                onPressed: () => context.push('/search'),
              ),
            ],
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
              // ── Daily quote ──────────────────────────────────────────────
              const _DailyQuoteCard(),

              const SizedBox(height: 12),

              // ── Study due cards ──────────────────────────────────────────
              _SectionCard(
                icon: Icons.school_outlined,
                label: 'Studio',
                trailing: _DailyCardGoalRing(
                  answered: streak.answeredToday,
                  goal: settings.dailyCardGoal,
                ),
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
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.trending_down_outlined,
                      label: 'Carte deboli',
                      subtitle: weakCards > 0
                          ? '$weakCards da rivedere'
                          : 'Nessuna carta debole',
                      onTap: weakCards > 0
                          ? () => context.go(
                              '/study?queueType=weak&autostart=true',
                            )
                          : () => context.go('/study'),
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
                child: Column(
                  children: [
                    Row(
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
                    if (streak.freezeTokens > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('🛡️', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${streak.freezeTokens} ${streak.freezeTokens == 1 ? 'freeze' : 'freeze'} disponibil${streak.freezeTokens == 1 ? 'e' : 'i'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent.shade100,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Il freeze protegge la streak se salti un giorno. Guadagni 1 ogni 7 giorni consecutivi.',
                            child: Icon(Icons.info_outline, size: 13,
                                color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
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
                      final due = g.daysUntilDue;
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
                            if (due != null && due < 0)
                              _Badge('Scaduto', color: Colors.red)
                            else if (due != null && due == 0)
                              _Badge('Oggi!', color: Colors.red)
                            else if (due != null && due <= 7)
                              _Badge('$due giorni', color: Colors.orange)
                            else
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

class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard();

  static const _quotes = [
    ('La disciplina è il ponte tra obiettivi e risultati.', 'Jim Rohn'),
    ('Non cercare il tempo, crealo.', 'Anonimo'),
    ('Il successo è la somma di piccoli sforzi ripetuti ogni giorno.', 'R. Collier'),
    ('Studia non per superare gli altri, ma per superare te stesso.', 'Anonimo'),
    ('La conoscenza è l\'unica ricchezza che nessuno può toglierti.', 'Anonimo'),
    ('Il modo per iniziare è smettere di parlare e cominciare a fare.', 'Walt Disney'),
    ('Non importa quanto sei lento, l\'importante è non fermarsi.', 'Confucio'),
    ('Ogni giorno è una nuova opportunità di migliorare.', 'Anonimo'),
    ('Il talento è nulla senza disciplina.', 'Anonimo'),
    ('Investi in te stesso: è il rendimento più alto che puoi ottenere.', 'Warren Buffett'),
    ('Il futuro appartiene a chi crede nella bellezza dei propri sogni.', 'Eleanor Roosevelt'),
    ('Non è mai tardi per essere quello che avresti potuto essere.', 'George Eliot'),
    ('La mente è come un paracadute: funziona solo se è aperta.', 'Frank Zappa'),
    ('Chi smette di imparare è vecchio, che abbia vent\'anni o ottanta.', 'Henry Ford'),
    ('La fortuna aiuta gli audaci.', 'Virgilio'),
    ('Non rimandare a domani quello che puoi fare oggi.', 'Benjamin Franklin'),
    ('Sii il cambiamento che vuoi vedere nel mondo.', 'Mahatma Gandhi'),
    ('Il momento migliore per iniziare era ieri. Il secondo momento migliore è adesso.', 'Proverbio cinese'),
    ('Ogni esperto è stato un principiante.', 'Anonimo'),
    ('Il progresso, non la perfezione, è il vero obiettivo.', 'Anonimo'),
    ('Impara come se dovessi vivere per sempre.', 'Mahatma Gandhi'),
    ('La lettura è all\'anima quello che l\'esercizio è al corpo.', 'Joseph Addison'),
    ('Non aver paura di andare lentamente; abbi paura di fermarti.', 'Proverbio cinese'),
    ('L\'istruzione è l\'arma più potente che puoi usare per cambiare il mondo.', 'Nelson Mandela'),
    ('Chi non risica non rosica.', 'Proverbio italiano'),
    ('La perseveranza è la chiave del successo.', 'Anonimo'),
    ('Fai del tuo meglio ogni giorno e il meglio si moltiplicherà.', 'Anonimo'),
    ('La mente cresciuta da una nuova idea non tornerà mai alle sue dimensioni originali.', 'Oliver Wendell Holmes'),
    ('Sii curioso, non giudicante.', 'Walt Whitman'),
    ('Ogni passo avanti, anche il più piccolo, è un passo nella direzione giusta.', 'Anonimo'),
    ('La conoscenza è potere.', 'Francis Bacon'),
    ('Concentrati sui progressi, non sulla perfezione.', 'Bill Phillips'),
    ('L\'unico modo per fare un ottimo lavoro è amare quello che fai.', 'Steve Jobs'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final entry = _quotes[dayOfYear % _quotes.length];
    final quote = entry.$1;
    final author = entry.$2;

    return Card(
      color: cs.surfaceContainerHighest.withAlpha(80),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$quote"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '— $author',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Daily card goal ring ───────────────────────────────────────────────────────

class _DailyCardGoalRing extends StatelessWidget {
  const _DailyCardGoalRing({required this.answered, required this.goal});

  final int answered;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final progress = (answered / goal).clamp(0.0, 1.0);
    final done = answered >= goal;
    final color = done ? Colors.greenAccent : const Color(0xFF6C63FF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$answered/$goal',
          style: TextStyle(
            fontSize: 11,
            color: done ? Colors.greenAccent : Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.greenAccent)
                : null,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    const strokeWidth = 3.0;

    final bg = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
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
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(habitsProvider.notifier).toggleToday(habit.id);
            },
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
