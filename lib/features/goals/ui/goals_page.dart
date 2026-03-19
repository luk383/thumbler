import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/state/habits_notifier.dart';
import '../../journal/domain/journal_entry.dart';
import '../../journal/state/journal_notifier.dart';
import '../../journal/ui/journal_page.dart';
import '../domain/goal.dart';
import '../state/goals_notifier.dart';
import 'goal_form_page.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final active = goals.where((g) => !g.completed).toList();
    final done = goals.where((g) => g.completed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Obiettivi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoalFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo obiettivo'),
      ),
      body: goals.isEmpty
          ? _EmptyState(onAdd: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalFormPage()),
            ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader('In corso (${active.length})'),
                  ...active.map((g) => _GoalCard(g)),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionHeader('Completati (${done.length})'),
                  ...done.map((g) => _GoalCard(g)),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard(this.goal);
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalDetailPage(goal: goal)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.area.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: goal.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                  ),
                  if (goal.completed)
                    Icon(Icons.check_circle, color: cs.primary, size: 20),
                ],
              ),
              if (goal.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  goal.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (goal.milestones.isNotEmpty) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: goal.progress,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.doneCount}/${goal.milestones.length} milestone',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              if (goal.targetDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(goal.targetDate!),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Detail page ──────────────────────────────────────────────────────────────

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read from provider so it reacts to updates
    final current = ref.watch(goalsProvider).firstWhere(
          (g) => g.id == goal.id,
          orElse: () => goal,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.area.emoji} ${current.area.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => GoalFormPage(existingGoal: current)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, current.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(current.title,
              style: Theme.of(context).textTheme.headlineSmall),
          if (current.description != null) ...[
            const SizedBox(height: 8),
            Text(current.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),

          // Milestones
          if (current.milestones.isNotEmpty) ...[
            Text('Milestones',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: current.progress,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            ...current.milestones.map((m) => CheckboxListTile(
                  value: m.done,
                  onChanged: (_) => ref
                      .read(goalsProvider.notifier)
                      .toggleMilestone(current.id, m.id),
                  title: Text(
                    m.text,
                    style: TextStyle(
                      decoration:
                          m.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
          ],

          const SizedBox(height: 20),

          // Linked habits
          _LinkedHabitsSection(goalId: current.id),

          const SizedBox(height: 20),

          // Linked journal entries
          _LinkedJournalSection(goalId: current.id),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                ref.read(goalsProvider.notifier).toggleCompleted(current.id),
            icon: Icon(current.completed
                ? Icons.restart_alt
                : Icons.check_circle_outline),
            label: Text(current.completed
                ? 'Segna come in corso'
                : 'Segna come completato'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina obiettivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              ref.read(goalsProvider.notifier).delete(id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

// ── Linked habits section ─────────────────────────────────────────────────────

class _LinkedHabitsSection extends ConsumerWidget {
  const _LinkedHabitsSection({required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref
        .watch(habitsProvider)
        .where((h) => h.goalId == goalId)
        .toList();

    if (linked.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Abitudini collegate',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...linked.map((h) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(h.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(h.name),
              subtitle: h.currentStreak > 0
                  ? Text('🔥 ${h.currentStreak} giorni',
                      style: Theme.of(context).textTheme.labelSmall)
                  : null,
              trailing: h.isDoneToday
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary, size: 20)
                  : Icon(Icons.radio_button_unchecked,
                      color: Theme.of(context).colorScheme.outline, size: 20),
            )),
      ],
    );
  }
}

// ── Linked journal entries ────────────────────────────────────────────────────

class _LinkedJournalSection extends ConsumerWidget {
  const _LinkedJournalSection({required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref
        .watch(journalProvider)
        .where((e) => e.goalId == goalId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (linked.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Note collegate', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...linked.take(3).map((e) {
          final d = e.createdAt;
          final dateStr =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(e.mood?.emoji ?? '📓',
                style: const TextStyle(fontSize: 20)),
            title: Text(
              e.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(dateStr,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.outline)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JournalEntryPage(existingEntry: e),
              ),
            ),
          );
        }),
        if (linked.length > 3)
          TextButton(
            onPressed: null,
            child: Text('+ ${linked.length - 3} altre note'),
          ),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: cs.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun obiettivo attivo',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Definisci un obiettivo per dare direzione al tuo studio.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Crea obiettivo'),
            ),
          ],
        ),
      ),
    );
  }
}
