import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/paywall/pro_guard.dart';
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
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.items.length} cards in deck',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
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
                      if (!ref
                          .read(proGuardProvider)
                          .canUseTopicSelection()) {
                        _showProDialog(context, 'Topic filtering');
                        return;
                      }
                    }
                    n.setTopic(v == 'All topics' ? null : v);
                  },
                ),
              ),
            ],

            // ── Preview pill ─────────────────────────────────────────────
            const SizedBox(height: 12),
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
              // SRS — check due count
              if (s.dueCount == 0 && s.selectedMode != StudyMode.speed) ...[
                _NoDueCards(),
                const SizedBox(height: 10),
                _StartButton(
                  icon: Icons.psychology_outlined,
                  label: 'Review anyway',
                  outlined: true,
                  onPressed: () {
                    n.setMode(StudyMode.srs);
                    n.startSession(reviewAnyway: true);
                  },
                ),
              ] else
                _StartButton(
                  icon: Icons.psychology_outlined,
                  label:
                      'Start Study  (${s.dueCount} due)',
                  onPressed: () {
                    n.setMode(StudyMode.srs);
                    n.startSession();
                  },
                ),
              const SizedBox(height: 10),
              _StartButton(
                icon: Icons.bolt,
                label: 'Start Speed Drill',
                outlined: true,
                accentColor: const Color(0xFF6C63FF),
                onPressed: () {
                  n.setMode(StudyMode.speed);
                  n.startSession();
                },
              ),
            ],

            const SizedBox(height: 32),

            // ── Library card ─────────────────────────────────────────────
            _LibraryCard(onOpen: () => showDeckLibrary(context)),

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
                fontSize: 15,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Go to Feed and tap 'Add to Study', or import a pack with the Library button below.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
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
        border:
            Border.all(color: const Color(0xFF6C63FF).withAlpha(55)),
      ),
      child: Text(
        '$label  ·  Total: ${state.availableCount}  ·  Due: ${state.dueCount}',
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
                width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
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
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                  fontWeight: FontWeight.w600),
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
  const _LibraryCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF6C63FF).withAlpha(60)),
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
              child: const Icon(Icons.library_books_outlined,
                  color: Color(0xFFADA8FF), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library / Import Packs',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Starter Pack · Exam Pack · more coming soon',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 11),
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
// No cards due
// ============================================================================

class _NoDueCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No cards due for review.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('Great job! Come back later or review anyway.',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
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
  const _ChipRow(
      {required this.chips,
      required this.selected,
      required this.onSelect});
  final List<String> chips;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => _Chip(
                  label: c,
                  selected: c == selected,
                  onTap: () => onSelect(c),
                ))
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
// Pro dialog
// ============================================================================

void _showProDialog(BuildContext context, String featureName) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1730),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Pro Feature',
              style: TextStyle(color: Colors.white, fontSize: 17)),
        ],
      ),
      content: Text(
        '$featureName is available for Pro users.',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Maybe later',
              style: TextStyle(color: Colors.white54)),
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
