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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Import pre-built decks into your Study collection.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),

            ...DeckPackMeta.localPacks.map(
              (meta) => _PackCard(
                meta: meta,
                result: lib.resultFor(meta.id),
                loading: lib.isLoading(meta.id),
                onImport: () => n.importPack(meta),
              ),
            ),

            const SizedBox(height: 4),
            const Text(
              // TODO: add remote packs from Supabase (decks v2)
              'More packs coming soon.',
              style: TextStyle(color: Colors.white24, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
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
  final VoidCallback onImport;

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
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  meta.description,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (result != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '✓ $result',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11),
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
                    backgroundColor:
                        const Color(0xFF6C63FF).withAlpha(40),
                    foregroundColor: const Color(0xFFADA8FF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onImport,
                  child:
                      Text(result != null ? 'Re-import' : 'Import'),
                ),
        ],
      ),
    );
  }
}
