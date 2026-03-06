import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/deck_pack.dart';
import '../controllers/deck_library_controller.dart';

/// Opens the Deck Library as a modal bottom sheet.
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

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

class _DeckLibrarySheet extends ConsumerWidget {
  const _DeckLibrarySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(deckLibraryProvider);
    final n = ref.read(deckLibraryProvider.notifier);
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
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

              const Text(
                'Deck Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Import pre-built decks into your Study collection.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                      onPressed: lib.isDiscovering ? null : n.discoverPacks,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh packs'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                      onPressed: n.printDiscoveredPacks,
                      icon: const Icon(Icons.terminal, size: 16),
                      label: const Text('Print discovered packs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (lib.isDiscovering)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ),
                      if (!lib.isDiscovering && lib.packs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'No JSON packs found under assets/decks/.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
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
                      ...lib.packs.map(
                        (meta) => _PackCard(
                          meta: meta,
                          result: lib.resultFor(meta.id),
                          loading: lib.isLoading(meta.id),
                          onImport: () async {
                            try {
                              await n.importPack(meta);
                              if (!context.mounted) return;
                              final result = ref
                                  .read(deckLibraryProvider)
                                  .resultFor(meta.id);
                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Imported ${result.added}, skipped ${result.skipped}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pack card row
// ---------------------------------------------------------------------------

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.meta,
    required this.result,
    required this.loading,
    required this.onImport,
  });

  final DeckPackMeta meta;
  final ImportResult? result;
  final bool loading;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Text(meta.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      meta.assetPath.split('/').last,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    if (meta.estimatedItemCount != null)
                      Text(
                        '${meta.estimatedItemCount} items',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    if (meta.hasInvalidJson)
                      Tooltip(
                        message: meta.invalidJsonMessage ?? 'Invalid JSON',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.redAccent.withAlpha(90),
                            ),
                          ),
                          child: const Text(
                            'Invalid JSON',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '✓ $result',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6C63FF),
                  ),
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF).withAlpha(40),
                    foregroundColor: const Color(0xFFADA8FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: meta.hasInvalidJson ? null : () => onImport(),
                  child: Text(result != null ? 'Re-import' : 'Import'),
                ),
        ],
      ),
    );
  }
}
