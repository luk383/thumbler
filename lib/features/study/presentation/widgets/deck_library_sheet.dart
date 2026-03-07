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
    builder: (_) => const DeckLibrarySheet(),
  );
}

class DeckLibrarySheet extends ConsumerWidget {
  const DeckLibrarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(deckLibraryProvider);
    final progressByDeck = ref.watch(deckProgressSummariesProvider);
    final notifier = ref.read(deckLibraryProvider.notifier);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    Future<void> activateDeck(DeckPackMeta meta) async {
      try {
        await notifier.setActiveDeck(meta);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${meta.title} is now the active deck.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    Future<void> goToStudy(DeckPackMeta meta) async {
      if (!lib.isActive(meta.id)) {
        await activateDeck(meta);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.go('/study');
    }

    Future<void> goToPractice(DeckPackMeta meta) async {
      if (!lib.isActive(meta.id)) {
        await activateDeck(meta);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    }

    Future<void> goToExam(DeckPackMeta meta) async {
      if (!meta.supportsExam) return;
      if (!lib.isActive(meta.id)) {
        await activateDeck(meta);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
      context.go('/exam');
    }

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
                    ? 'Discover local decks and choose what to learn next.'
                    : 'Current focus: ${lib.activeDeck!.title}',
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    : _LibraryHub(
                        packs: lib.packs,
                        activeDeckId: lib.activeDeckId,
                        isLoading: lib.isLoading,
                        resultFor: lib.resultFor,
                        progressByDeck: progressByDeck,
                        onActivate: activateDeck,
                        onStudy: goToStudy,
                        onPractice: goToPractice,
                        onExam: goToExam,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: AppEmptyStateCard(
          icon: Icons.library_books_outlined,
          title: 'No local packs found',
          message: 'Add a JSON pack to assets/decks and refresh the library.',
        ),
      ),
    );
  }
}

class _LibraryHub extends StatelessWidget {
  const _LibraryHub({
    required this.packs,
    required this.activeDeckId,
    required this.isLoading,
    required this.resultFor,
    required this.progressByDeck,
    required this.onActivate,
    required this.onStudy,
    required this.onPractice,
    required this.onExam,
  });

  final List<DeckPackMeta> packs;
  final String? activeDeckId;
  final bool Function(String packId) isLoading;
  final ImportResult? Function(String packId) resultFor;
  final Map<String, DeckProgressSummary> progressByDeck;
  final Future<void> Function(DeckPackMeta meta) onActivate;
  final Future<void> Function(DeckPackMeta meta) onStudy;
  final Future<void> Function(DeckPackMeta meta) onPractice;
  final Future<void> Function(DeckPackMeta meta) onExam;

  @override
  Widget build(BuildContext context) {
    final activeDeck = activeDeckId == null
        ? null
        : packs.cast<DeckPackMeta?>().firstWhere(
            (pack) => pack?.id == activeDeckId,
            orElse: () => null,
          );

    final certificationPacks = packs
        .where((pack) => pack.librarySection == 'Certifications')
        .toList();
    final topicPacks = packs
        .where((pack) => pack.librarySection == 'General Knowledge')
        .toList();

    final continueLearning = _continueLearningPacks(
      packs: packs,
      activeDeck: activeDeck,
      progressByDeck: progressByDeck,
    );
    final featured = _featuredPacks(
      packs: packs,
      progressByDeck: progressByDeck,
      excludedIds: {for (final pack in continueLearning) pack.id},
    );
    final pinnedIds = {
      for (final pack in continueLearning) pack.id,
      for (final pack in featured) pack.id,
    };
    final certificationBrowse = certificationPacks
        .where((pack) => !pinnedIds.contains(pack.id))
        .toList();
    final topicBrowse = topicPacks
        .where((pack) => !pinnedIds.contains(pack.id))
        .toList();

    return ListView(
      children: [
        if (continueLearning.isNotEmpty) ...[
          _LibrarySection(
            title: 'Continue Learning',
            subtitle:
                'Jump back into your active deck or anything already in progress.',
            children: continueLearning
                .map(
                  (meta) => _DeckHubCard(
                    meta: meta,
                    progress: progressByDeck[meta.id],
                    isActive: meta.id == activeDeckId,
                    isLoading: isLoading(meta.id),
                    result: resultFor(meta.id),
                    onActivate: () => onActivate(meta),
                    onStudy: () => onStudy(meta),
                    onPractice: () => onPractice(meta),
                    onExam: meta.supportsExam ? () => onExam(meta) : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
        ],
        _LibrarySection(
          title: 'Featured',
          subtitle:
              'A short list of strong starting points across certifications and broad topics.',
          children: featured
              .map(
                (meta) => _DeckHubCard(
                  meta: meta,
                  progress: progressByDeck[meta.id],
                  isActive: meta.id == activeDeckId,
                  isLoading: isLoading(meta.id),
                  result: resultFor(meta.id),
                  onActivate: () => onActivate(meta),
                  onStudy: () => onStudy(meta),
                  onPractice: () => onPractice(meta),
                  onExam: meta.supportsExam ? () => onExam(meta) : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        if (certificationBrowse.isNotEmpty)
          _LibrarySection(
            title: 'Certifications',
            subtitle:
                'Structured exam tracks such as Security+, AWS, and Linux Essentials.',
            children: certificationBrowse
                .map(
                  (meta) => _DeckHubCard(
                    meta: meta,
                    progress: progressByDeck[meta.id],
                    isActive: meta.id == activeDeckId,
                    isLoading: isLoading(meta.id),
                    result: resultFor(meta.id),
                    onActivate: () => onActivate(meta),
                    onStudy: () => onStudy(meta),
                    onPractice: () => onPractice(meta),
                    onExam: meta.supportsExam ? () => onExam(meta) : null,
                  ),
                )
                .toList(),
          ),
        if (certificationBrowse.isNotEmpty) const SizedBox(height: 18),
        if (topicBrowse.isNotEmpty)
          _LibrarySection(
            title: 'Explore Topics',
            subtitle:
                'General knowledge decks for broader learning and lightweight daily practice.',
            children: topicBrowse
                .map(
                  (meta) => _DeckHubCard(
                    meta: meta,
                    progress: progressByDeck[meta.id],
                    isActive: meta.id == activeDeckId,
                    isLoading: isLoading(meta.id),
                    result: resultFor(meta.id),
                    onActivate: () => onActivate(meta),
                    onStudy: () => onStudy(meta),
                    onPractice: () => onPractice(meta),
                    onExam: meta.supportsExam ? () => onExam(meta) : null,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _DeckHubCard extends StatelessWidget {
  const _DeckHubCard({
    required this.meta,
    required this.progress,
    required this.isActive,
    required this.isLoading,
    required this.result,
    required this.onActivate,
    required this.onStudy,
    required this.onPractice,
    required this.onExam,
  });

  final DeckPackMeta meta;
  final DeckProgressSummary? progress;
  final bool isActive;
  final bool isLoading;
  final ImportResult? result;
  final Future<void> Function() onActivate;
  final Future<void> Function() onStudy;
  final Future<void> Function() onPractice;
  final Future<void> Function()? onExam;

  @override
  Widget build(BuildContext context) {
    final status = _deckStatus(isActive: isActive, progress: progress);
    final isUnavailable =
        meta.hasInvalidJson || meta.isStarter || !meta.hasQuestions;
    final supportingLine = meta.description?.trim().isNotEmpty == true
        ? meta.description!.trim()
        : (meta.category?.trim().isNotEmpty == true
              ? meta.category!
              : meta.subtitle);
    final countLabel = meta.questionCount > 0
        ? '${meta.questionCount} questions'
        : 'Question count coming soon';
    final progressLine = progress == null || !progress!.hasImportedItems
        ? 'No saved progress yet'
        : progress!.hasProgress
        ? '${progress!.reviewedItems}/${progress!.totalItems} cards reviewed'
        : '${progress!.totalItems} cards ready to start';

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      radius: 20,
      tint: status.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSurfaceIcon(
                icon: meta.librarySection == 'Certifications'
                    ? Icons.workspace_premium_outlined
                    : Icons.explore_outlined,
                tint: status.tint,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supportingLine,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppStatusBadge(
                label: status.label,
                icon: status.icon,
                tint: status.tint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: countLabel),
              _InfoChip(
                label: meta.librarySection == 'Certifications'
                    ? (meta.examCode ?? 'Certification')
                    : 'Topic deck',
                tint: meta.librarySection == 'Certifications'
                    ? const Color(0xFF6C63FF)
                    : Colors.tealAccent,
              ),
              if (meta.isStarter)
                const _InfoChip(
                  label: 'Starter entry',
                  tint: Colors.orangeAccent,
                ),
              if (progress?.hasProgress ?? false)
                _InfoChip(
                  label: '${progress!.reviewedItems} reviewed',
                  tint: Colors.lightBlueAccent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            progressLine,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (result != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last import: ${result!.added} added, ${result!.updated} updated, ${result!.skipped} skipped',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          if (meta.availabilityNote != null) ...[
            const SizedBox(height: 8),
            Text(
              meta.availabilityNote!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
          if (meta.invalidJsonMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              meta.invalidJsonMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: isActive ? 'Study' : 'Set Active',
                icon: isLoading ? null : Icons.school_outlined,
                onPressed: isUnavailable || isLoading
                    ? null
                    : (isActive ? onStudy : onActivate),
                isPrimary: true,
                isLoading: isLoading,
              ),
              _ActionButton(
                label: 'Practice',
                icon: Icons.play_circle_outline,
                onPressed: isUnavailable || isLoading ? null : onPractice,
              ),
              if (onExam != null)
                _ActionButton(
                  label: 'Exam',
                  icon: Icons.assignment_outlined,
                  onPressed: isUnavailable || isLoading ? null : onExam,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final Future<void> Function()? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: isPrimary
          ? const Color(0xFF6C63FF)
          : const Color(0xFF171B25),
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.white10,
      disabledForegroundColor: Colors.white30,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );

    return FilledButton.icon(
      style: style,
      onPressed: onPressed == null
          ? null
          : () async {
              await onPressed!.call();
            },
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.tint = Colors.white24});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint == Colors.white24 ? Colors.white70 : tint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeckCardStatus {
  const _DeckCardStatus({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color tint;
}

_DeckCardStatus _deckStatus({
  required bool isActive,
  required DeckProgressSummary? progress,
}) {
  if (isActive) {
    return const _DeckCardStatus(
      label: 'Active',
      icon: Icons.check_circle_outline,
      tint: Color(0xFF6C63FF),
    );
  }
  if (progress?.hasProgress ?? false) {
    return const _DeckCardStatus(
      label: 'In Progress',
      icon: Icons.timelapse_outlined,
      tint: Colors.orangeAccent,
    );
  }
  return const _DeckCardStatus(
    label: 'New',
    icon: Icons.auto_awesome_outlined,
    tint: Colors.tealAccent,
  );
}

List<DeckPackMeta> _continueLearningPacks({
  required List<DeckPackMeta> packs,
  required DeckPackMeta? activeDeck,
  required Map<String, DeckProgressSummary> progressByDeck,
}) {
  final selected = <DeckPackMeta>[];
  if (activeDeck != null) {
    selected.add(activeDeck);
  }

  final progressPacks =
      packs.where((pack) {
        final progress = progressByDeck[pack.id];
        return progress?.hasProgress ?? false;
      }).toList()..sort((a, b) {
        final aProgress = progressByDeck[a.id]!;
        final bProgress = progressByDeck[b.id]!;
        final byReviewed = bProgress.reviewedItems.compareTo(
          aProgress.reviewedItems,
        );
        if (byReviewed != 0) return byReviewed;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

  for (final pack in progressPacks) {
    if (selected.any((item) => item.id == pack.id)) continue;
    selected.add(pack);
  }

  return selected.take(4).toList();
}

List<DeckPackMeta> _featuredPacks({
  required List<DeckPackMeta> packs,
  required Map<String, DeckProgressSummary> progressByDeck,
  Set<String> excludedIds = const {},
}) {
  const preferredOrder = [
    'comptia_security_plus_sy0_701_pack_20',
    'sec701_exam_simulation_90',
    'aws_cloud_practitioner_clf_c02',
    'aws_solutions_architect_associate_saa_c03',
    'linux_essentials_010_160',
    'technology_basics',
    'technology_basics_starter',
    'world_history_starter',
    'world_geography_starter',
    'basic_science_starter',
    'general_knowledge_starter',
  ];

  final byId = {for (final pack in packs) pack.id: pack};
  final featured = <DeckPackMeta>[];

  for (final id in preferredOrder) {
    final pack = byId[id];
    if (pack == null) continue;
    if (excludedIds.contains(pack.id)) continue;
    if (featured.any((existing) => existing.id == pack.id)) continue;
    if (!(pack.isImportable ||
        pack.isStarter ||
        (progressByDeck[id]?.hasImportedItems ?? false))) {
      continue;
    }
    featured.add(pack);
  }

  if (featured.length < 4) {
    for (final pack in packs) {
      if (excludedIds.contains(pack.id)) continue;
      if (featured.any((existing) => existing.id == pack.id)) continue;
      featured.add(pack);
      if (featured.length >= 4) break;
    }
  }

  return featured.take(4).toList();
}
