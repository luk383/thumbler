import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../data/deck_pack.dart';
import '../controllers/deck_library_controller.dart';

void showDeckLibrary(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F0D1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _DeckLibrarySheet(),
  );
}

class _DeckLibrarySheet extends ConsumerWidget {
  const _DeckLibrarySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(deckLibraryProvider);
    final notifier = ref.read(deckLibraryProvider.notifier);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppPageIntro(
                title: 'Library',
                subtitle: lib.activeDeck == null
                    ? 'Choose a local pack to power Feed, Study and Exam.'
                    : 'Current active deck: ${lib.activeDeck!.title}',
                trailing: lib.activeDeck == null
                    ? null
                    : const AppStatusBadge(
                        label: 'Active deck',
                        icon: Icons.layers_outlined,
                      ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                onPressed: lib.isDiscovering ? null : notifier.discoverPacks,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh library'),
              ),
              const SizedBox(height: 12),
              if (lib.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    lib.lastError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: lib.isDiscovering && lib.packs.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : lib.packs.isEmpty
                    ? const _EmptyLibraryState()
                    : ListView.builder(
                        itemCount: lib.packs.length,
                        itemBuilder: (context, index) {
                          final meta = lib.packs[index];
                          return _PackCard(
                            meta: meta,
                            isActive: lib.isActive(meta.id),
                            isLoading: lib.isLoading(meta.id),
                            result: lib.resultFor(meta.id),
                            onUseDeck: () async {
                              try {
                                await notifier.setActiveDeck(meta);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${meta.title} is now the active deck.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            onStudy: () {
                              Navigator.of(context).pop();
                              context.go('/study');
                            },
                            onExam: meta.supportsExam
                                ? () {
                                    Navigator.of(context).pop();
                                    context.go('/exam');
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.library_books_outlined, color: Colors.white30, size: 40),
            SizedBox(height: 12),
            Text(
              'No local packs found in assets/decks.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Add a JSON pack to assets/decks and refresh the library.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.meta,
    required this.isActive,
    required this.isLoading,
    required this.result,
    required this.onUseDeck,
    required this.onStudy,
    required this.onExam,
  });

  final DeckPackMeta meta;
  final bool isActive;
  final bool isLoading;
  final ImportResult? result;
  final Future<void> Function() onUseDeck;
  final VoidCallback onStudy;
  final VoidCallback? onExam;

  @override
  Widget build(BuildContext context) {
    final isUnavailable =
        meta.hasInvalidJson || meta.isStarter || !meta.hasQuestions;

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const AppStatusBadge(
                  label: 'Active',
                  icon: Icons.check_circle_outline,
                ),
            ],
          ),
          if (meta.description != null && meta.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: '${meta.questionCount} items'),
              if (meta.microCardCount > 0)
                _InfoChip(label: '${meta.microCardCount} feed/study'),
              if (meta.examQuestionCount > 0)
                _InfoChip(label: '${meta.examQuestionCount} exam'),
              _InfoChip(
                label: meta.hasInvalidJson ? 'Invalid JSON' : 'Ready',
                tint: meta.hasInvalidJson ? Colors.redAccent : Colors.white24,
              ),
              if (meta.isStarter)
                const _InfoChip(
                  label: 'Starter deck',
                  tint: Colors.orangeAccent,
                ),
              if (meta.hasInvalidJson)
                const _InfoChip(label: 'Cannot import', tint: Colors.redAccent),
              if (!meta.hasInvalidJson && isActive)
                const _InfoChip(
                  label: 'Used across Feed, Study, Exam',
                  tint: Color(0xFF6C63FF),
                ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Last import: ${result!.added} added, ${result!.updated} updated, ${result!.skipped} skipped',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          if (meta.availabilityNote != null) ...[
            const SizedBox(height: 10),
            Text(
              meta.availabilityNote!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
          if (meta.invalidJsonMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              meta.invalidJsonMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: isUnavailable || isLoading ? null : onUseDeck,
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.white12
                        : const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isActive
                              ? 'In Use'
                              : meta.isStarter || !meta.hasQuestions
                              ? 'Not Ready'
                              : 'Use Deck',
                        ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: isActive && meta.hasQuestions ? onStudy : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                child: const Text('Study'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: isActive && meta.supportsExam ? onExam : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                child: const Text('Exam'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.tint});

  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (tint ?? Colors.white24).withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (tint ?? Colors.white24).withAlpha(60)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}
