import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../../../features/paywall/pro_guard.dart';
import '../controllers/deck_library_controller.dart';
import '../controllers/study_controller.dart';
import '../widgets/deck_library_sheet.dart';

// ============================================================================
// Study Launcher Page
// Always shows: header, category chips, topic chips, preview, start buttons,
// and the Library card — regardless of whether the deck is empty.
// ============================================================================

class StudyLauncherPage extends ConsumerWidget {
  const StudyLauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    final n = ref.read(studyProvider.notifier);
    final activeDeck = ref.watch(activeDeckMetaProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            // ── Header ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            const Text(
              'Study',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeDeck == null
                  ? '${s.items.length} cards in deck'
                  : '${activeDeck.title} · ${s.items.length} cards',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _StudySnapshot(state: s),
            const SizedBox(height: 24),

            // ── Empty banner (deck empty) ────────────────────────────────
            if (s.items.isEmpty) ...[
              _EmptyBanner(onSeed: n.seedStarterCards),
              const SizedBox(height: 28),
            ],

            // ── Category chips ───────────────────────────────────────────
            _LauncherSection(
              label: 'Category',
              child: s.categories.isEmpty
                  ? const Text(
                      'Import a pack or add cards from Feed to see categories.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    )
                  : _ChipRow(
                      chips: ['All', ...s.categories],
                      selected: s.selectedCategory ?? 'All',
                      onSelect: (v) {
                        if (v != 'All') {
                          if (!ref
                              .read(proGuardProvider)
                              .canUseTopicSelection()) {
                            _showProDialog(context, 'Category filtering');
                            return;
                          }
                        }
                        n.setCategory(v == 'All' ? null : v);
                      },
                    ),
            ),

            // ── Topic chips (only when category selected + topics exist) ─
            if (s.selectedCategory != null && s.topics.isNotEmpty) ...[
              const SizedBox(height: 4),
              _LauncherSection(
                label: 'Topic',
                child: _ChipRow(
                  chips: ['All topics', ...s.topics],
                  selected: s.selectedTopic ?? 'All topics',
                  onSelect: (v) {
                    if (v != 'All topics') {
                      if (!ref.read(proGuardProvider).canUseTopicSelection()) {
                        _showProDialog(context, 'Topic filtering');
                        return;
                      }
                    }
                    n.setTopic(v == 'All topics' ? null : v);
                  },
                ),
              ),
            ],

            // ── Session Type chips ───────────────────────────────────────
            const SizedBox(height: 4),
            _LauncherSection(
              label: 'Session type',
              child: _QueueTypeChipRow(
                selected: s.selectedQueueType,
                state: s,
                onSelect: n.setQueueType,
              ),
            ),

            // ── Preview pill ─────────────────────────────────────────────
            _PreviewPill(state: s),
            const SizedBox(height: 28),

            // ── Session settings ─────────────────────────────────────────
            _LauncherSection(
              label: 'Questions per session',
              child: _ChipRow(
                chips: const ['5', '10', '20'],
                selected: '${s.sessionLength}',
                onSelect: (v) {
                  final length = int.parse(v);
                  if (length > 10 &&
                      !ref.read(proGuardProvider).canRunLongSpeedDrill()) {
                    _showProDialog(context, 'Sessions with 20 questions');
                    return;
                  }
                  n.setSessionLength(length);
                },
              ),
            ),
            const SizedBox(height: 4),
            _LauncherSection(
              label: 'Speed timer',
              child: _ChipRow(
                chips: const ['5s', '8s', '12s'],
                selected: '${s.timerSeconds}s',
                onSelect: (v) =>
                    n.setTimerSeconds(int.parse(v.replaceAll('s', ''))),
              ),
            ),
            const SizedBox(height: 28),

            // ── Start buttons ────────────────────────────────────────────
            if (s.items.isEmpty) ...[
              _DisabledStartButton(
                icon: Icons.psychology_outlined,
                label: 'Start Study Session',
                reason: 'Import cards first',
              ),
              const SizedBox(height: 10),
              _DisabledStartButton(
                icon: Icons.bolt,
                label: 'Start Speed Drill',
                reason: 'Import cards first',
              ),
            ] else if (s.availableCount == 0) ...[
              _EmptyFilterResult(),
            ] else ...[
              _QueueStartButtons(state: s, notifier: n),
            ],

            const SizedBox(height: 32),

            // ── Library card ─────────────────────────────────────────────
            _LibraryCard(
              onOpen: () => showDeckLibrary(context),
              deckTitle: activeDeck?.title,
            ),

            // ── Debug footer ─────────────────────────────────────────────
            const SizedBox(height: 20),
            Text(
              'Study cards: ${s.items.length}',
              style: const TextStyle(color: Colors.white24, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Section wrapper
// ============================================================================

class _LauncherSection extends StatelessWidget {
  const _LauncherSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================================
// Empty banner
// ============================================================================

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.onSeed});
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          const Text('📚', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          const Text(
            'No cards in Study yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Go to Feed and tap 'Add to Study', or import a pack with the Library button below.",
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withAlpha(40)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSeed,
              icon: const Icon(Icons.auto_awesome, size: 15),
              label: const Text('Add 5 starter cards'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudySnapshot extends StatelessWidget {
  const _StudySnapshot({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) return const SizedBox.shrink();

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SnapshotStat(
              label: 'Reviewed',
              value:
                  '${state.items.where((item) => item.timesSeen > 0).length}',
            ),
          ),
          Expanded(
            child: _SnapshotStat(label: 'Due Now', value: '${state.dueCount}'),
          ),
          Expanded(
            child: _SnapshotStat(label: 'Weak', value: '${state.weakCount}'),
          ),
        ],
      ),
    );
  }
}

class _SnapshotStat extends StatelessWidget {
  const _SnapshotStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

// ============================================================================
// Preview pill
// ============================================================================

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.state});
  final StudyState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) return const SizedBox.shrink();

    final String label;
    if (state.selectedCategory == null) {
      label = 'All topics';
    } else if (state.selectedTopic != null) {
      label = '${state.selectedCategory} › ${state.selectedTopic}';
    } else {
      label = state.selectedCategory!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(55)),
      ),
      child: Text(
        '$label  ·  Total: ${state.availableCount}  ·  Due: ${state.dueCount}  ·  Weak: ${state.weakCount}  ·  New: ${state.newCount}',
        style: const TextStyle(
          color: Color(0xFFADA8FF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Start buttons
// ============================================================================

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.accentColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor ?? Colors.white70,
            side: BorderSide(
              color: accentColor ?? Colors.white.withAlpha(50),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _DisabledStartButton extends StatelessWidget {
  const _DisabledStartButton({
    required this.icon,
    required this.label,
    required this.reason,
  });
  final IconData icon;
  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.35,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 8),
            Text(
              '$label  ($reason)',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Library card
// ============================================================================

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.onOpen, this.deckTitle});
  final VoidCallback onOpen;
  final String? deckTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.library_books_outlined,
                color: Color(0xFFADA8FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deckTitle ?? 'Library / Import Packs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    deckTitle == null
                        ? 'Browse and import any JSON pack found in assets/decks/.'
                        : 'This is the active deck for Feed, Study and Exam.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Empty filter result
// ============================================================================

class _EmptyFilterResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: const Text(
        'No cards match the current category/topic selection.',
        style: TextStyle(color: Colors.white54, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Shared chip widgets
// ============================================================================

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.chips,
    required this.selected,
    required this.onSelect,
  });
  final List<String> chips;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (c) => _Chip(
                label: c,
                selected: c == selected,
                onTap: () => onSelect(c),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withAlpha(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Queue type chip row
// ============================================================================

class _QueueTypeChipRow extends StatelessWidget {
  const _QueueTypeChipRow({
    required this.selected,
    required this.state,
    required this.onSelect,
  });
  final SessionQueueType selected;
  final StudyState state;
  final void Function(SessionQueueType) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SessionQueueType.values.map((type) {
          final count = switch (type) {
            SessionQueueType.due => state.dueCount,
            SessionQueueType.weak => state.weakCount,
            SessionQueueType.newCards => state.newCount,
            SessionQueueType.random => state.availableCount,
          };
          final isSelected = type == selected;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 13,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${type.label} $count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Start buttons — queue-type aware
// ============================================================================

class _QueueStartButtons extends StatelessWidget {
  const _QueueStartButtons({required this.state, required this.notifier});
  final StudyState state;
  final StudyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final queueCount = state.queueCount;
    final queueLabel = state.selectedQueueType.label;
    final hasCards = queueCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary SRS start button
        if (!hasCards) ...[
          _EmptyQueueBanner(queueType: state.selectedQueueType),
          const SizedBox(height: 10),
          _StartButton(
            icon: Icons.psychology_outlined,
            label: 'Review Random instead',
            outlined: true,
            onPressed: () {
              notifier.setQueueType(SessionQueueType.random);
              notifier.setMode(StudyMode.srs);
              notifier.startSession();
            },
          ),
        ] else
          _StartButton(
            icon: Icons.psychology_outlined,
            label: 'Study $queueLabel  ($queueCount cards)',
            onPressed: () {
              notifier.setMode(StudyMode.srs);
              notifier.startSession();
            },
          ),
        const SizedBox(height: 10),
        // Speed Drill always available if cards exist
        _StartButton(
          icon: Icons.bolt,
          label: hasCards
              ? 'Speed Drill  ($queueLabel · $queueCount cards)'
              : 'Speed Drill  (all ${state.availableCount} cards)',
          outlined: true,
          accentColor: const Color(0xFF6C63FF),
          onPressed: () {
            notifier.setMode(StudyMode.speed);
            if (!hasCards) {
              notifier.startSession(reviewAnyway: true);
            } else {
              notifier.startSession();
            }
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Empty queue banner (per queue type)
// ============================================================================

class _EmptyQueueBanner extends StatelessWidget {
  const _EmptyQueueBanner({required this.queueType});
  final SessionQueueType queueType;

  @override
  Widget build(BuildContext context) {
    final (emoji, message) = switch (queueType) {
      SessionQueueType.due => (
        '🎉',
        'No cards due for review. Great job!\nCome back later, or switch to Random.',
      ),
      SessionQueueType.weak => (
        '💪',
        'No weak cards found.\nKeep studying to track your mistakes.',
      ),
      SessionQueueType.newCards => (
        '📭',
        'No new cards left.\nImport a deck pack or add from Feed.',
      ),
      SessionQueueType.random => ('🃏', 'No cards available.'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Pro dialog
// ============================================================================

void _showProDialog(BuildContext context, String featureName) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1730),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text(
            'Pro Feature',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
        ],
      ),
      content: Text(
        '$featureName is available for Pro users.',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Maybe later',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
          ),
          // TODO: navigate to paywall / RevenueCat purchase flow
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Upgrade to Pro'),
        ),
      ],
    ),
  );
}
