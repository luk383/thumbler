import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../goals/state/goals_notifier.dart';
import '../../habits/state/habits_notifier.dart';
import '../../journal/state/journal_notifier.dart';
import '../../study/data/study_storage.dart';
import '../../study/domain/study_item.dart';
import '../../study/presentation/controllers/deck_library_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  bool _cardMatches(StudyItem c, String q) {
    if (c.promptText.toLowerCase().contains(q)) return true;
    if (c.explanationText?.toLowerCase().contains(q) == true) return true;
    if (c.userNote?.toLowerCase().contains(q) == true) return true;
    if (c.category.toLowerCase().contains(q)) return true;
    if (c.topic?.toLowerCase().contains(q) == true) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider);
    final journal = ref.watch(journalProvider);
    final activeDeckId = ref.watch(activeDeckIdProvider);
    final allCards = StudyStorage().allForDeck(activeDeckId);

    final q = _query;

    final filteredCards = q.isEmpty
        ? <_SearchResult>[]
        : allCards
            .where((c) => _cardMatches(c, q))
            .map((c) => _SearchResult(
                  icon: c.isStarred ? Icons.star_rounded : Icons.school_outlined,
                  iconColor: c.isStarred ? Colors.amber : null,
                  title: c.promptText,
                  subtitle: c.category +
                      (c.explanationText != null &&
                              c.explanationText!.toLowerCase().contains(q)
                          ? ' · dalla spiegazione'
                          : '') +
                      (c.userNote != null &&
                              c.userNote!.toLowerCase().contains(q)
                          ? ' · dalla nota'
                          : ''),
                  onTap: () => context.go('/study'),
                ))
            .toList();

    final filteredHabits = q.isEmpty
        ? <_SearchResult>[]
        : habits
            .where((h) =>
                h.name.toLowerCase().contains(q) ||
                h.emoji.toLowerCase().contains(q))
            .map((h) => _SearchResult(
                  icon: Icons.check_circle_outline,
                  title: '${h.emoji} ${h.name}',
                  subtitle: h.currentStreak > 0
                      ? '🔥 ${h.currentStreak} giorni'
                      : null,
                  onTap: () => context.push('/habits'),
                ))
            .toList();

    final filteredGoals = q.isEmpty
        ? <_SearchResult>[]
        : goals
            .where((g) =>
                g.title.toLowerCase().contains(q) ||
                g.area.label.toLowerCase().contains(q))
            .map((g) => _SearchResult(
                  icon: Icons.flag_outlined,
                  title: '${g.area.emoji} ${g.title}',
                  subtitle: g.completed ? 'Completato ✅' : 'In corso',
                  onTap: () => context.push('/goals'),
                ))
            .toList();

    final filteredJournal = q.isEmpty
        ? <_SearchResult>[]
        : journal
            .where((e) =>
                e.preview.toLowerCase().contains(q) ||
                (e.tags.any((t) => t.toLowerCase().contains(q))))
            .map((e) => _SearchResult(
                  icon: Icons.book_outlined,
                  title: e.preview,
                  subtitle: _formatDate(e.createdAt),
                  onTap: () => context.push('/journal'),
                ))
            .toList();

    final totalResults = filteredCards.length +
        filteredHabits.length +
        filteredGoals.length +
        filteredJournal.length;

    final hasResults = totalResults > 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Cerca carte, abitudini, obiettivi, diario…',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: q.isEmpty
          ? _EmptyState()
          : !hasResults
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nessun risultato per "$_query"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        '$totalResults risultat${totalResults == 1 ? 'o' : 'i'}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                    if (filteredCards.isNotEmpty) ...[
                      _SectionHeader('Carte', filteredCards.length),
                      ...filteredCards.map(_buildTile),
                    ],
                    if (filteredHabits.isNotEmpty) ...[
                      _SectionHeader('Abitudini', filteredHabits.length),
                      ...filteredHabits.map(_buildTile),
                    ],
                    if (filteredGoals.isNotEmpty) ...[
                      _SectionHeader('Obiettivi', filteredGoals.length),
                      ...filteredGoals.map(_buildTile),
                    ],
                    if (filteredJournal.isNotEmpty) ...[
                      _SectionHeader('Diario', filteredJournal.length),
                      ...filteredJournal.map(_buildTile),
                    ],
                  ],
                ),
    );
  }

  Widget _buildTile(_SearchResult result) {
    return ListTile(
      leading: Icon(result.icon, color: result.iconColor),
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: result.onTap,
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Icon(
          Icons.search,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'Cerca in tutto Wolf Lab',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Flashcard (testo, spiegazione, note)\nAbitudini, obiettivi, voci di diario',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ...[
          ('🃏', 'Carte', 'Cerca nel testo, spiegazione e note'),
          ('✅', 'Abitudini', 'Cerca per nome o emoji'),
          ('🎯', 'Obiettivi', 'Cerca per titolo o area'),
          ('📔', 'Diario', 'Cerca nel testo e nei tag'),
        ].map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(e.$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.$2,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      e.$3,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}
