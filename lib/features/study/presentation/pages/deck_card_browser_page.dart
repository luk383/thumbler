import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/study_item.dart';
import '../controllers/study_controller.dart';

// ============================================================================
// Filter enum
// ============================================================================

enum _CardFilter { all, starred, weak, due, cloze }

// ============================================================================
// Page
// ============================================================================

class DeckCardBrowserPage extends ConsumerStatefulWidget {
  const DeckCardBrowserPage({super.key});

  @override
  ConsumerState<DeckCardBrowserPage> createState() =>
      _DeckCardBrowserPageState();
}

class _DeckCardBrowserPageState extends ConsumerState<DeckCardBrowserPage> {
  _CardFilter _filter = _CardFilter.all;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StudyItem> _applyFilters(List<StudyItem> items) {
    final now = DateTime.now();
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      // Search
      if (q.isNotEmpty && !item.promptText.toLowerCase().contains(q)) {
        return false;
      }
      // Filter
      switch (_filter) {
        case _CardFilter.all:
          return true;
        case _CardFilter.starred:
          return item.isStarred;
        case _CardFilter.weak:
          return item.wrongCount > 0 &&
              (item.correctCount == 0 ||
                  item.wrongCount / (item.correctCount + item.wrongCount) >
                      0.4);
        case _CardFilter.due:
          return item.nextReviewAt == null ||
              item.nextReviewAt!.isBefore(now);
        case _CardFilter.cloze:
          return item.contentType == ContentType.clozeCard;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(studyProvider).items;
    final filtered = _applyFilters(allItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Browser'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cerca carte...',
                hintStyle: TextStyle(
                  color: Colors.white.withAlpha(80),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withAlpha(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'Tutte',
                  selected: _filter == _CardFilter.all,
                  onTap: () => setState(() => _filter = _CardFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Starred',
                  icon: Icons.star_rounded,
                  selected: _filter == _CardFilter.starred,
                  onTap: () => setState(() => _filter = _CardFilter.starred),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Deboli',
                  icon: Icons.trending_down_rounded,
                  selected: _filter == _CardFilter.weak,
                  onTap: () => setState(() => _filter = _CardFilter.weak),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Da ripassare',
                  icon: Icons.schedule_rounded,
                  selected: _filter == _CardFilter.due,
                  onTap: () => setState(() => _filter = _CardFilter.due),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cloze',
                  icon: Icons.auto_fix_high_rounded,
                  selected: _filter == _CardFilter.cloze,
                  onTap: () => setState(() => _filter = _CardFilter.cloze),
                ),
              ],
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} carte',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _CardTile(
                        item: item,
                        onTap: () => context.push('/card-editor', extra: item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets
// ============================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(48) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent.withAlpha(120) : Colors.white.withAlpha(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? accent : Colors.white54,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? accent : Colors.white54,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.item, required this.onTap});

  final StudyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDue = item.nextReviewAt == null ||
        item.nextReviewAt!.isBefore(DateTime.now());
    final accuracy = item.timesSeen == 0
        ? null
        : item.correctCount / item.timesSeen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _typeColor(item.contentType).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _typeIcon(item.contentType),
                size: 18,
                color: _typeColor(item.contentType),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.promptText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      if (item.topic != null) ...[
                        const Text(
                          ' · ',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          item.topic!,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Stats column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.isStarred)
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFD700),
                  ),
                const SizedBox(height: 2),
                if (isDue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Due',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (accuracy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(accuracy * 100).round()}%',
                    style: TextStyle(
                      color: accuracy >= 0.7
                          ? Colors.greenAccent.withAlpha(180)
                          : Colors.orangeAccent.withAlpha(180),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ContentType type) {
    switch (type) {
      case ContentType.clozeCard:
        return Icons.auto_fix_high_rounded;
      case ContentType.examQuestion:
        return Icons.quiz_outlined;
      case ContentType.microCard:
        return Icons.style_outlined;
    }
  }

  Color _typeColor(ContentType type) {
    switch (type) {
      case ContentType.clozeCard:
        return const Color(0xFF6C63FF);
      case ContentType.examQuestion:
        return Colors.orangeAccent;
      case ContentType.microCard:
        return Colors.tealAccent;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text(
            'Nessuna carta trovata',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
