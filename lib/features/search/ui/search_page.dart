import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../goals/state/goals_notifier.dart';
import '../../habits/state/habits_notifier.dart';
import '../../journal/state/journal_notifier.dart';
import '../../study/data/study_storage.dart';

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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider);
    final journal = ref.watch(journalProvider);
    final allCards = StudyStorage().all();

    final q = _query;

    final filteredCards = q.isEmpty
        ? <_SearchResult>[]
        : allCards
            .where((c) => c.promptText.toLowerCase().contains(q))
            .map((c) => _SearchResult(
                  icon: Icons.school_outlined,
                  title: c.promptText,
                  subtitle: c.category,
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
            .where((g) => g.title.toLowerCase().contains(q))
            .map((g) => _SearchResult(
                  icon: Icons.flag_outlined,
                  title: '${g.area.emoji} ${g.title}',
                  subtitle: g.completed ? 'Completato' : 'In corso',
                  onTap: () => context.push('/goals'),
                ))
            .toList();

    final filteredJournal = q.isEmpty
        ? <_SearchResult>[]
        : journal
            .where((e) => e.preview.toLowerCase().contains(q))
            .map((e) => _SearchResult(
                  icon: Icons.book_outlined,
                  title: e.preview,
                  subtitle: _formatDate(e.createdAt),
                  onTap: () => context.push('/journal'),
                ))
            .toList();

    final hasResults = filteredCards.isNotEmpty ||
        filteredHabits.isNotEmpty ||
        filteredGoals.isNotEmpty ||
        filteredJournal.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Cerca carte, abitudini, obiettivi...',
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Cerca carte, abitudini, obiettivi...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
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
                    if (filteredCards.isNotEmpty) ...[
                      _SectionHeader('Carte'),
                      ...filteredCards.map(_buildTile),
                    ],
                    if (filteredHabits.isNotEmpty) ...[
                      _SectionHeader('Abitudini'),
                      ...filteredHabits.map(_buildTile),
                    ],
                    if (filteredGoals.isNotEmpty) ...[
                      _SectionHeader('Obiettivi'),
                      ...filteredGoals.map(_buildTile),
                    ],
                    if (filteredJournal.isNotEmpty) ...[
                      _SectionHeader('Diario'),
                      ...filteredJournal.map(_buildTile),
                    ],
                  ],
                ),
    );
  }

  Widget _buildTile(_SearchResult result) {
    return ListTile(
      leading: Icon(result.icon),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}
