import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/book_lookup_service.dart';
import '../data/url_metadata_service.dart';
import '../domain/reading_item.dart';
import '../state/reading_notifier.dart';
import 'isbn_scanner_page.dart';

class ReadingPage extends ConsumerWidget {
  const ReadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(readingProvider);

    final reading = items.where((i) => i.status == ReadingStatus.reading).toList();
    final wishlist = items.where((i) => i.status == ReadingStatus.wishlist).toList();
    final completed = items.where((i) => i.status == ReadingStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Letture & Corsi')),
      floatingActionButton: _AddFab(
        onManual: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReadingFormPage()),
        ),
        onScanIsbn: () => _scanIsbn(context),
        onImportUrl: () => _importUrl(context),
      ),
      body: items.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (reading.isNotEmpty) ...[
                  _SectionHeader('🔖 In corso'),
                  ...reading.map((i) => _ReadingCard(i)),
                  const SizedBox(height: 12),
                ],
                if (wishlist.isNotEmpty) ...[
                  _SectionHeader('⭐ Lista desideri'),
                  ...wishlist.map((i) => _ReadingCard(i)),
                  const SizedBox(height: 12),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader('✅ Completati (${completed.length})'),
                  ...completed.map((i) => _ReadingCard(i)),
                ],
              ],
            ),
    );
  }

  Future<void> _scanIsbn(BuildContext context) async {
    final book = await Navigator.of(context).push<BookInfo>(
      MaterialPageRoute(builder: (_) => const IsbnScannerPage()),
    );
    if (book == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingFormPage(prefillFromBook: book),
      ),
    );
  }

  Future<void> _importUrl(BuildContext context) async {
    final url = await _showUrlDialog(context);
    if (url == null || url.trim().isEmpty || !context.mounted) return;

    final loading = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recupero informazioni…'),
        duration: Duration(seconds: 30),
      ),
    );

    final metadata = await UrlMetadataService().fetch(url);
    loading.close();

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingFormPage(prefillFromUrl: metadata, rawUrl: url),
      ),
    );
  }

  Future<String?> _showUrlDialog(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa da URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incolla un link YouTube, Spotify, Udemy, articolo…',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }
}

// ── FAB with speed dial ───────────────────────────────────────────────────────

class _AddFab extends StatefulWidget {
  const _AddFab({
    required this.onManual,
    required this.onScanIsbn,
    required this.onImportUrl,
  });

  final VoidCallback onManual;
  final VoidCallback onScanIsbn;
  final VoidCallback onImportUrl;

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _MiniAction(
            icon: Icons.add,
            label: 'Manuale',
            onTap: () { _toggle(); widget.onManual(); },
          ),
          const SizedBox(height: 10),
          _MiniAction(
            icon: Icons.qr_code_scanner,
            label: 'Scansiona ISBN',
            onTap: () { _toggle(); widget.onScanIsbn(); },
          ),
          const SizedBox(height: 10),
          _MiniAction(
            icon: Icons.link,
            label: 'Importa URL',
            onTap: () { _toggle(); widget.onImportUrl(); },
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: label,
            onPressed: onTap,
            child: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

// ── Reading card ──────────────────────────────────────────────────────────────

class _ReadingCard extends ConsumerWidget {
  const _ReadingCard(this.item);
  final ReadingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReadingDetailPage(item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail or emoji
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.thumbnailUrl != null
                    ? Image.network(
                        item.thumbnailUrl!,
                        width: 44,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _EmojiThumb(item.type.emoji),
                      )
                    : _EmojiThumb(item.type.emoji),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (item.author != null)
                      Text(item.author!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (item.status == ReadingStatus.reading &&
                        item.totalPages != null) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: item.progress,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.currentPage ?? 0}/${item.totalPages} pag.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<ReadingStatus>(
                icon: Icon(Icons.more_vert, color: cs.outline),
                onSelected: (s) =>
                    ref.read(readingProvider.notifier).setStatus(item.id, s),
                itemBuilder: (_) => ReadingStatus.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text('${s.emoji} ${s.label}'),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiThumb extends StatelessWidget {
  const _EmojiThumb(this.emoji);
  final String emoji;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 60,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      );
}

// ── Detail page ───────────────────────────────────────────────────────────────

class ReadingDetailPage extends ConsumerWidget {
  const ReadingDetailPage({super.key, required this.item});
  final ReadingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(readingProvider).firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.type.emoji),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReadingFormPage(existingItem: current),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(readingProvider.notifier).delete(current.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with thumbnail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (current.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    current.thumbnailUrl!,
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (current.thumbnailUrl != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (current.author != null)
                      Text(current.author!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    if (current.sourceUrl != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        current.sourceUrl!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status picker
          SegmentedButton<ReadingStatus>(
            segments: ReadingStatus.values
                .map((s) => ButtonSegment(
                      value: s,
                      label: Text('${s.emoji} ${s.label}'),
                    ))
                .toList(),
            selected: {current.status},
            onSelectionChanged: (s) => ref
                .read(readingProvider.notifier)
                .setStatus(current.id, s.first),
          ),

          // Progress slider
          if (current.status == ReadingStatus.reading &&
              current.totalPages != null) ...[
            const SizedBox(height: 20),
            Text(
              'Progresso: pagina ${current.currentPage ?? 0} / ${current.totalPages}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Slider(
              value: (current.currentPage ?? 0).toDouble(),
              max: current.totalPages!.toDouble(),
              divisions: current.totalPages,
              label: '${current.currentPage ?? 0}',
              onChanged: (v) => ref
                  .read(readingProvider.notifier)
                  .updateProgress(current.id, v.round()),
            ),
          ],

          if (current.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            Text('Note', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(current.notes!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ── Form page ─────────────────────────────────────────────────────────────────

class ReadingFormPage extends ConsumerStatefulWidget {
  const ReadingFormPage({
    super.key,
    this.existingItem,
    this.prefillFromBook,
    this.prefillFromUrl,
    this.rawUrl,
  });

  final ReadingItem? existingItem;
  final BookInfo? prefillFromBook;
  final UrlMetadata? prefillFromUrl;
  final String? rawUrl;

  @override
  ConsumerState<ReadingFormPage> createState() => _ReadingFormPageState();
}

class _ReadingFormPageState extends ConsumerState<ReadingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _notesCtrl;
  late ReadingType _type;
  late ReadingStatus _status;
  String? _thumbnailUrl;
  String? _sourceUrl;

  @override
  void initState() {
    super.initState();
    final i = widget.existingItem;
    final book = widget.prefillFromBook;
    final url = widget.prefillFromUrl;

    _titleCtrl = TextEditingController(
      text: i?.title ?? book?.title ?? url?.title ?? '',
    );
    _authorCtrl = TextEditingController(
      text: i?.author ?? book?.author ?? url?.author ?? '',
    );
    _pagesCtrl = TextEditingController(
      text: i?.totalPages?.toString() ?? book?.pages?.toString() ?? '',
    );
    _notesCtrl = TextEditingController(
      text: i?.notes ?? book?.description?.substring(
                0,
                (book.description!.length > 300)
                    ? 300
                    : book.description!.length,
              ) ??
          url?.description?.substring(
                0,
                (url.description!.length > 300)
                    ? 300
                    : url.description!.length,
              ) ??
          '',
    );
    _type = i?.type ?? url?.type ?? ReadingType.book;
    _status = i?.status ?? ReadingStatus.wishlist;
    _thumbnailUrl = i?.thumbnailUrl ?? book?.thumbnailUrl ?? url?.thumbnailUrl;
    _sourceUrl = i?.sourceUrl ?? widget.rawUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = ReadingItem(
      id: widget.existingItem?.id ??
          'reading_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
      type: _type,
      status: _status,
      totalPages: int.tryParse(_pagesCtrl.text),
      currentPage: widget.existingItem?.currentPage,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      thumbnailUrl: _thumbnailUrl,
      sourceUrl: _sourceUrl,
      startedAt: widget.existingItem?.startedAt,
      completedAt: widget.existingItem?.completedAt,
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
    );
    ref.read(readingProvider.notifier).save(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica' : 'Aggiungi'),
        actions: [TextButton(onPressed: _save, child: const Text('Salva'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thumbnail preview
            if (_thumbnailUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _thumbnailUrl!,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (_thumbnailUrl != null) const SizedBox(height: 16),

            // Type chips
            Wrap(
              spacing: 8,
              children: ReadingType.values
                  .map((t) => ChoiceChip(
                        label: Text('${t.emoji} ${t.label}'),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Il titolo è obbligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authorCtrl,
              decoration: InputDecoration(
                labelText:
                    '${_type == ReadingType.course ? 'Autore/Piattaforma' : 'Autore'} (opzionale)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_type == ReadingType.book || _type == ReadingType.course) ...[
              TextFormField(
                controller: _pagesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      _type == ReadingType.book ? 'Pagine totali' : 'Ore totali',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            DropdownButtonFormField<ReadingStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Stato',
                border: OutlineInputBorder(),
              ),
              items: ReadingStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.emoji} ${s.label}'),
                      ))
                  .toList(),
              onChanged: (s) => setState(() => _status = s!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: cs.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'Lista letture vuota',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi un libro, articolo, podcast o corso.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
