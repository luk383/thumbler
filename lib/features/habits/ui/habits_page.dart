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
    final doneToday = habits.where((h) => h.isDoneToday).length;

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
                    value: habits.isEmpty ? 0 : doneToday / habits.length,
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
                        'Oggi — $doneToday/${habits.length} completate',
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
    final goals = ref.read(goalsProvider).where((g) => !g.completed).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nuova abitudine'),
          content: Column(
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
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(habitsProvider.notifier).add(
                      Habit(
                        id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        emoji: emoji,
                        goalId: selectedGoalId,
                        createdAt: DateTime.now(),
                      ),
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
        color: done ? cs.primaryContainer.withAlpha(80) : null,
        child: ListTile(
          leading: Text(habit.emoji, style: const TextStyle(fontSize: 26)),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? cs.outline : null,
            ),
          ),
          subtitle: habit.currentStreak > 0
              ? Text('🔥 ${habit.currentStreak} giorni consecutivi',
                  style: Theme.of(context).textTheme.labelSmall)
              : null,
          trailing: GestureDetector(
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
          ),
        ),
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
