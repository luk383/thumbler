import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../goals/state/goals_notifier.dart';
import '../domain/habit.dart';
import '../state/habits_notifier.dart';

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    // Only habits scheduled for today count in the denominator
    final todayHabits = habits.where((h) => h.isScheduledToday).toList();
    final doneToday = todayHabits.where((h) => h.isDoneToday).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abitudini'),
        bottom: habits.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: LinearProgressIndicator(
                    value: todayHabits.isEmpty ? 0 : doneToday / todayHabits.length,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: habits.isEmpty
          ? _EmptyState(onAdd: () => _showAddDialog(context, ref))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oggi — $doneToday/${todayHabits.length} completate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _todayLabel(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: habits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _HabitTile(habits[i]),
                  ),
                ),
              ],
            ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return '${days[now.weekday - 1]} ${now.day}/${now.month}';
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    var emoji = '✅';
    String? selectedGoalId;
    String? reminderTime;
    List<int> selectedDays = [];
    final goals = ref.read(goalsProvider).where((g) => !g.completed).toList();

    const dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nuova abitudine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji picker (quick set)
                Wrap(
                  spacing: 8,
                  children: ['✅', '📚', '🏃', '💧', '🧘', '💤', '🥗', '✍️']
                      .map((e) => GestureDetector(
                            onTap: () => setS(() => emoji = e),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: emoji == e
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome abitudine',
                    hintText: 'es. Leggere 20 minuti',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                // Scheduled days row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giorni (vuoto = ogni giorno)',
                      style: Theme.of(ctx).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: List.generate(7, (i) {
                        final selected = selectedDays.contains(i);
                        return FilterChip(
                          label: Text(dayLabels[i]),
                          selected: selected,
                          onSelected: (v) {
                            setS(() {
                              if (v) {
                                selectedDays = [...selectedDays, i]..sort();
                              } else {
                                selectedDays = selectedDays.where((d) => d != i).toList();
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          labelPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),
                  ],
                ),
                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedGoalId,
                    decoration: const InputDecoration(
                      labelText: 'Collega a obiettivo (opz.)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nessuno')),
                      ...goals.map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(
                              '${g.area.emoji} ${g.title}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (v) => setS(() => selectedGoalId = v),
                  ),
                ],
                const SizedBox(height: 12),
                // Reminder row
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Promemoria'),
                  subtitle: Text(reminderTime ?? 'Nessuno'),
                  onTap: () async {
                    final initial = reminderTime != null
                        ? () {
                            final parts = reminderTime!.split(':');
                            return TimeOfDay(
                              hour: int.tryParse(parts[0]) ?? 9,
                              minute: int.tryParse(
                                      parts.length > 1 ? parts[1] : '0') ??
                                  0,
                            );
                          }()
                        : const TimeOfDay(hour: 9, minute: 0);
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: initial,
                    );
                    if (picked != null) {
                      setS(() {
                        reminderTime =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  trailing: reminderTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setS(() => reminderTime = null),
                        )
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(habitsProvider.notifier).addHabit(
                      name: nameCtrl.text.trim(),
                      emoji: emoji,
                      goalId: selectedGoalId,
                      reminderTime: reminderTime,
                      scheduledDays: selectedDays,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Habit tile ────────────────────────────────────────────────────────────────

class _HabitTile extends ConsumerWidget {
  const _HabitTile(this.habit);
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final done = habit.isDoneToday;
    final scheduledToday = habit.isScheduledToday;
    final streak = habit.computedStreak;

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Elimina abitudine?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elimina')),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(habitsProvider.notifier).delete(habit.id),
      child: Card(
        margin: EdgeInsets.zero,
        color: !scheduledToday
            ? cs.surfaceContainerHighest.withAlpha(60)
            : done
                ? cs.primaryContainer.withAlpha(80)
                : null,
        child: ListTile(
          onTap: () => _showHeatmap(context),
          leading: Opacity(
            opacity: scheduledToday ? 1.0 : 0.4,
            child: Text(habit.emoji, style: const TextStyle(fontSize: 26)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: !scheduledToday
                        ? cs.outline.withAlpha(120)
                        : done
                            ? cs.outline
                            : null,
                  ),
                ),
              ),
              if (streak > 1) ...[
                const SizedBox(width: 6),
                Text(
                  '🔥 $streak',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
          subtitle: !scheduledToday
              ? Text(
                  'Non in programma oggi',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.outline.withAlpha(120),
                      ),
                )
              : habit.currentStreak > 0
                  ? Text('🔥 ${habit.currentStreak} giorni consecutivi',
                      style: Theme.of(context).textTheme.labelSmall)
                  : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!scheduledToday)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: cs.outline.withAlpha(120),
                  ),
                )
              else if (habit.reminderTime != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
              if (scheduledToday)
                GestureDetector(
                  onTap: () =>
                      ref.read(habitsProvider.notifier).toggleToday(habit.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? cs.primary : Colors.transparent,
                      border: Border.all(
                        color: done ? cs.primary : cs.outline,
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                )
              else
                // Not scheduled: show a disabled circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: cs.outline.withAlpha(60),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHeatmap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HabitHeatmapSheet(habit: habit),
    );
  }
}

// ── Habit Heatmap ─────────────────────────────────────────────────────────────

class _HabitHeatmapSheet extends StatelessWidget {
  const _HabitHeatmapSheet({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Show 5 weeks (35 days) back from today
    const days = 35;
    final cells = List.generate(days, (i) {
      final d = now.subtract(Duration(days: days - 1 - i));
      return (date: d, done: habit.isDoneOn(d));
    });

    // Weekday labels: L M M G V S D
    const dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    // Align grid so first cell starts on correct weekday
    final firstDay = cells.first.date;
    final offset = (firstDay.weekday - 1) % 7; // Mon=0

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.75,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '🔥 Streak: ${habit.computedStreak}  ·  Best: ${habit.longestStreak}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Day labels row
          Row(
            children: dayLabels
                .map((l) => Expanded(
                      child: Center(
                        child: Text(l,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: cs.outline)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // Grid — 5 rows of 7
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: offset + cells.length,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox.shrink();
              final cell = cells[i - offset];
              final isToday = cell.date.year == now.year &&
                  cell.date.month == now.month &&
                  cell.date.day == now.day;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: cell.done
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                ),
                child: cell.done
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('Non completata',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 16),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('Completata',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nessuna abitudine',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Costruisci una routine quotidiana',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi abitudine'),
            ),
          ],
        ),
      );
}
