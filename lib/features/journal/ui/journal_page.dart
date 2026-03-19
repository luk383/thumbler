import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../goals/state/goals_notifier.dart';
import '../../habits/state/habits_notifier.dart';
import '../domain/journal_entry.dart';
import '../state/journal_notifier.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  JournalMood? _moodFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<JournalEntry> _filter(List<JournalEntry> entries) {
    var result = entries;
    if (_moodFilter != null) {
      result = result.where((e) => e.mood == _moodFilter).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return result;
    return result
        .where((e) =>
            e.text.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    final filtered = _filter(entries);

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
          : Column(
              children: [
                // ── Mood trend chart ──────────────────────────────────────
                _MoodTrendBar(entries: entries),

                // ── Search bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchBar(
                    controller: _searchCtrl,
                    hintText: 'Cerca nelle note…',
                    leading: const Icon(Icons.search, size: 20),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                    ],
                    onChanged: (v) => setState(() => _query = v),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                // ── Mood filter chips ─────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tutti'),
                        selected: _moodFilter == null,
                        onSelected: (_) =>
                            setState(() => _moodFilter = null),
                      ),
                      const SizedBox(width: 6),
                      ...JournalMood.values.map((mood) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Text(mood.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              label: Text(mood.label),
                              selected: _moodFilter == mood,
                              onSelected: (_) => setState(
                                () => _moodFilter =
                                    _moodFilter == mood ? null : mood,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Entry list ────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Nessuna nota trovata.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _EntryCard(filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Mood trend bar (last 14 days) ─────────────────────────────────────────────

class _MoodTrendBar extends StatelessWidget {
  const _MoodTrendBar({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build 14-day grid
    final days = List.generate(14, (i) {
      final date = now.subtract(Duration(days: 13 - i));
      return DateTime(date.year, date.month, date.day);
    });

    // Find mood per day (most recent entry with mood that day)
    JournalMood? moodForDay(DateTime day) {
      for (final entry in entries) {
        if (entry.mood == null) continue;
        final d = DateTime(
            entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
        if (d == day) return entry.mood;
      }
      return null;
    }

    final moodColors = {
      JournalMood.great: Colors.green,
      JournalMood.good: Colors.lightGreen,
      JournalMood.ok: Colors.orange,
      JournalMood.bad: Colors.red,
    };

    final hasMoodData = entries.any((e) => e.mood != null);
    if (!hasMoodData) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Umore — ultimi 14 giorni',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: days.map((day) {
              final mood = moodForDay(day);
              return Expanded(
                child: Tooltip(
                  message: mood == null
                      ? '${day.day}/${day.month}: —'
                      : '${day.day}/${day.month}: ${mood.label} ${mood.emoji}',
                  child: Container(
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: mood == null
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : moodColors[mood]!.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: mood != null
                        ? Center(
                            child: Text(mood.emoji,
                                style: const TextStyle(fontSize: 12)),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${days.first.day}/${days.first.month}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10),
              ),
              Text(
                'oggi',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: cs.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'Il diario è vuoto',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scrivi il tuo primo pensiero. Anche solo una riga.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onWrite,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Scrivi qualcosa'),
            ),
          ],
        ),
      ),
    );
  }
}
