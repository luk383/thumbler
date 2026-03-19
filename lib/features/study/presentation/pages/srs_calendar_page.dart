import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/study_item.dart';
import '../controllers/study_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SRS Calendar Page — upcoming review schedule for the next 14 days
// ─────────────────────────────────────────────────────────────────────────────

class SrsCalendarPage extends ConsumerWidget {
  const SrsCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    final schedule = _buildSchedule(s.items);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Review Calendar',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        elevation: 0,
      ),
      body: schedule.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              itemCount: schedule.length,
              itemBuilder: (context, i) {
                final entry = schedule[i];
                return _DaySection(
                  date: entry.date,
                  items: entry.items,
                  isToday: entry.isToday,
                  isPast: entry.isPast,
                );
              },
            ),
    );
  }

  List<_DayEntry> _buildSchedule(List<StudyItem> allItems) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Collect overdue (past) + next 14 days
    final Map<DateTime, List<StudyItem>> byDay = {};

    for (final item in allItems) {
      final reviewAt = item.nextReviewAt;
      if (reviewAt == null) continue;

      final day = DateTime(reviewAt.year, reviewAt.month, reviewAt.day);
      final cutoff = today.add(const Duration(days: 14));
      if (day.isAfter(cutoff)) continue;

      byDay.putIfAbsent(day, () => []).add(item);
    }

    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) {
      final isPast = e.key.isBefore(today);
      final isToday = e.key == today;
      return _DayEntry(date: e.key, items: e.value, isToday: isToday, isPast: isPast);
    }).toList();
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _DayEntry {
  const _DayEntry({
    required this.date,
    required this.items,
    required this.isToday,
    required this.isPast,
  });
  final DateTime date;
  final List<StudyItem> items;
  final bool isToday;
  final bool isPast;
}

// ── Day Section ───────────────────────────────────────────────────────────────

class _DaySection extends ConsumerStatefulWidget {
  const _DaySection({
    required this.date,
    required this.items,
    required this.isToday,
    required this.isPast,
  });
  final DateTime date;
  final List<StudyItem> items;
  final bool isToday;
  final bool isPast;

  @override
  ConsumerState<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends ConsumerState<_DaySection> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    // Collapse days far in the future by default
    _expanded = widget.isToday || widget.isPast || widget.items.length <= 3;
  }

  @override
  Widget build(BuildContext context) {
    final label = _dayLabel(widget.date, widget.isToday);
    final headerColor = widget.isPast
        ? Colors.redAccent
        : widget.isToday
            ? const Color(0xFF6C63FF)
            : Colors.white70;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (widget.isPast)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: headerColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.items.length} cards',
                      style: TextStyle(
                        color: headerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Card list
          if (_expanded)
            ...widget.items.map((item) => _CardRow(item: item)),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date, bool isToday) {
    if (isToday) return 'Today';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${-diff} days ago';

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

// ── Card Row ──────────────────────────────────────────────────────────────────

class _CardRow extends ConsumerWidget {
  const _CardRow({required this.item});
  final StudyItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(studyProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Category dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _categoryColor(item.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.promptText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category + (item.topic != null ? ' › ${item.topic}' : ''),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Interval badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.srsInterval == 0 ? 'new' : '${item.srsInterval}d',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
          const SizedBox(width: 6),
          // Snooze button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.snoozeCard(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Snoozed by 1 day'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.snooze_outlined, color: Colors.white38, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    final hash = category.hashCode;
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF0D8B5F),
      const Color(0xFFFF6D00),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFFB300),
    ];
    return colors[hash.abs() % colors.length];
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📅', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'No cards scheduled yet',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Start studying to build your SRS schedule.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
