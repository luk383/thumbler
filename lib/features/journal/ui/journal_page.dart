import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../goals/state/goals_notifier.dart';
import '../../habits/state/habits_notifier.dart';
import '../domain/journal_entry.dart';
import '../state/journal_notifier.dart';

class JournalPage extends ConsumerWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JournalEntryPage()),
        ),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Scrivi'),
      ),
      body: entries.isEmpty
          ? _EmptyState(onWrite: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalEntryPage()),
            ))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EntryCard(entries[i]),
            ),
    );
  }
}

// ── Entry card ────────────────────────────────────────────────────────────────

class _EntryCard extends ConsumerWidget {
  const _EntryCard(this.entry);
  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final d = entry.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminare questa nota?'),
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
      onDismissed: (_) => ref.read(journalProvider.notifier).delete(entry.id),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => JournalEntryPage(existingEntry: entry)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (entry.mood != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(entry.mood!.emoji,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    Text(dateStr,
                        style: Theme.of(context).textTheme.labelSmall),
                    const Spacer(),
                    if (entry.goalId != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.flag, size: 13, color: cs.primary),
                      ),
                    if (entry.habitId != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_circle,
                            size: 13, color: cs.primary),
                      ),
                    if (entry.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          entry.tags.take(2).map((t) => '#$t').join(' '),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.preview,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Entry form ────────────────────────────────────────────────────────────────

class JournalEntryPage extends ConsumerStatefulWidget {
  const JournalEntryPage({super.key, this.existingEntry});
  final JournalEntry? existingEntry;

  @override
  ConsumerState<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends ConsumerState<JournalEntryPage> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _tagsCtrl;
  JournalMood? _mood;
  String? _goalId;
  String? _habitId;

  @override
  void initState() {
    super.initState();
    _textCtrl =
        TextEditingController(text: widget.existingEntry?.text ?? '');
    _tagsCtrl = TextEditingController(
        text: widget.existingEntry?.tags.join(', ') ?? '');
    _mood = widget.existingEntry?.mood;
    _goalId = widget.existingEntry?.goalId;
    _habitId = widget.existingEntry?.habitId;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_textCtrl.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final entry = JournalEntry(
      id: widget.existingEntry?.id ??
          'journal_${DateTime.now().millisecondsSinceEpoch}',
      text: _textCtrl.text.trim(),
      mood: _mood,
      tags: tags,
      goalId: _goalId,
      habitId: _habitId,
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
    );
    ref.read(journalProvider.notifier).save(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEntry != null;
    final goals = ref.watch(goalsProvider).where((g) => !g.completed).toList();
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica nota' : 'Nuova nota'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Salva')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mood selector
          Text('Come stai?', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: JournalMood.values
                .map((m) => GestureDetector(
                      onTap: () =>
                          setState(() => _mood = _mood == m ? null : m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _mood == m
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        ),
                        child: Text('${m.emoji} ${m.label}',
                            style: Theme.of(context).textTheme.labelMedium),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Text
          TextFormField(
            controller: _textCtrl,
            maxLines: 10,
            autofocus: !isEdit,
            decoration: const InputDecoration(
              hintText: 'Cosa hai in mente?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Tags
          TextFormField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(
              labelText: 'Tag (separati da virgola)',
              hintText: 'es. lavoro, studio, riflessione',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 14),

          // Goal link
          if (goals.isNotEmpty)
            DropdownButtonFormField<String?>(
              initialValue: _goalId,
              decoration: const InputDecoration(
                labelText: 'Collega a obiettivo (opz.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nessuno')),
                ...goals.map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.area.emoji} ${g.title}',
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _goalId = v),
            ),

          if (goals.isNotEmpty) const SizedBox(height: 14),

          // Habit link
          if (habits.isNotEmpty)
            DropdownButtonFormField<String?>(
              initialValue: _habitId,
              decoration: const InputDecoration(
                labelText: 'Collega ad abitudine (opz.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nessuna')),
                ...habits.map((h) => DropdownMenuItem(
                      value: h.id,
                      child: Text('${h.emoji} ${h.name}',
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _habitId = v),
            ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(isEdit ? 'Salva modifiche' : 'Salva nota'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onWrite});
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✍️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nessuna nota',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Scrivi pensieri, insight e idee',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Scrivi'),
            ),
          ],
        ),
      );
}
