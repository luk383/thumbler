import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/study_storage.dart';
import '../../data/deck_pack.dart';
import '../controllers/deck_library_controller.dart';

class DeckManagementPage extends ConsumerWidget {
  const DeckManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(deckLibraryProvider);
    final packs = libraryState.packs.where((p) => p.isImportable).toList();
    final storage = StudyStorage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestisci deck'),
      ),
      body: packs.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: packs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pack = packs[index];
                final cards = storage.allForDeck(pack.id);
                final totalAnswered = cards.fold<int>(
                  0,
                  (sum, c) => sum + c.correctCount + c.wrongCount,
                );
                final totalCorrect = cards.fold<int>(
                  0,
                  (sum, c) => sum + c.correctCount,
                );
                final accuracyPct = totalAnswered == 0
                    ? null
                    : ((totalCorrect / totalAnswered) * 100).round();
                final isActive = libraryState.activeDeckId == pack.id;

                return _DeckCard(
                  pack: pack,
                  cardCount: cards.length,
                  accuracyPct: accuracyPct,
                  isActive: isActive,
                  onRename: () => _showRenameDialog(context, ref, pack),
                  onClone: () => _cloneDeck(context, ref, pack),
                  onMerge: packs.length > 1
                      ? () => _showMergeDialog(context, ref, pack, packs)
                      : null,
                  onDelete: pack.assetPath.startsWith('user://')
                      ? () => _showDeleteDialog(context, ref, pack)
                      : null,
                );
              },
            ),
    );
  }

  Future<void> _cloneDeck(
    BuildContext context,
    WidgetRef ref,
    DeckPackMeta pack,
  ) async {
    final titleCtrl =
        TextEditingController(text: '${pack.title} (copia)');
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clona deck'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Nome del nuovo deck',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, titleCtrl.text.trim()),
            child: const Text('Clona'),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    if (newTitle == null || newTitle.isEmpty) return;

    try {
      await ref
          .read(deckLibraryProvider.notifier)
          .cloneDeck(pack.id, newTitle: newTitle);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$newTitle" creato ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showMergeDialog(
    BuildContext context,
    WidgetRef ref,
    DeckPackMeta source,
    List<DeckPackMeta> allPacks,
  ) async {
    final targets = allPacks.where((p) => p.id != source.id).toList();
    DeckPackMeta? selected = targets.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Unisci deck'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le carte di "${source.title}" verranno copiate in:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DeckPackMeta>(
                initialValue: selected,
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
                items: targets
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.title,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'I duplicati (stesso ID) vengono saltati.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unisci'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected == null) return;

    try {
      final added = await ref
          .read(deckLibraryProvider.notifier)
          .mergeDeck(
            sourceDeckId: source.id,
            targetDeckId: selected!.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$added carte aggiunte a "${selected!.title}".',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    DeckPackMeta pack,
  ) async {
    final controller = TextEditingController(text: pack.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina deck'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuovo nome',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) return;
    // Only user decks can be renamed in storage; for asset decks show a message
    if (!pack.assetPath.startsWith('user://')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('I deck predefiniti non possono essere rinominati.'),
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck rinominato in "$result"')),
      );
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    DeckPackMeta pack,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina deck'),
        content: Text(
          'Sei sicuro di voler eliminare "${pack.title}"?\n'
          'Questa azione rimuoverà anche tutti i progressi associati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Remove all cards for this deck from study storage
    final storage = StudyStorage();
    final cards = storage.allForDeck(pack.id);
    for (final card in cards) {
      storage.remove(card.id, deckId: pack.id);
    }

    // Remove user deck JSON from library storage
    ref.read(deckLibraryProvider.notifier).deleteUserDeck(pack.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${pack.title}" eliminato.')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 52, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'Nessun deck disponibile',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Importa un deck dalla libreria per iniziare.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _DeckAction { clone, merge, delete }

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.pack,
    required this.cardCount,
    required this.accuracyPct,
    required this.isActive,
    required this.onRename,
    required this.onClone,
    this.onMerge,
    this.onDelete,
  });

  final DeckPackMeta pack;
  final int cardCount;
  final int? accuracyPct;
  final bool isActive;
  final VoidCallback onRename;
  final VoidCallback onClone;
  final VoidCallback? onMerge;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final acc = accuracyPct;
    final accuracyColor = acc == null
        ? cs.outline
        : acc >= 80
            ? Colors.greenAccent
            : acc >= 60
                ? Colors.orangeAccent
                : Colors.redAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ATTIVO',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    pack.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.style_outlined,
                  label: '$cardCount carte',
                ),
                const SizedBox(width: 8),
                if (acc != null)
                  _InfoChip(
                    icon: Icons.insights_outlined,
                    label: '$acc% accuratezza',
                    color: accuracyColor,
                  )
                else
                  _InfoChip(
                    icon: Icons.insights_outlined,
                    label: 'Nessun dato',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onRename,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Rinomina'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<_DeckAction>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  iconColor: cs.onSurfaceVariant,
                  tooltip: 'Altre azioni',
                  onSelected: (action) {
                    switch (action) {
                      case _DeckAction.clone:
                        onClone();
                      case _DeckAction.merge:
                        onMerge?.call();
                      case _DeckAction.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _DeckAction.clone,
                      child: ListTile(
                        leading: Icon(Icons.copy_outlined),
                        title: Text('Clona'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    if (onMerge != null)
                      const PopupMenuItem(
                        value: _DeckAction.merge,
                        child: ListTile(
                          leading: Icon(Icons.merge_outlined),
                          title: Text('Unisci in…'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: _DeckAction.delete,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            'Elimina',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: effectiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
