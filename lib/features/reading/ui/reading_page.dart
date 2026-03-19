import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reading_item.dart';
import '../state/reading_notifier.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReadingFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
      body: items.isEmpty
          ? _EmptyState(onAdd: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingFormPage()),
            ))
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
}

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(item.type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (item.author != null)
                      Text(item.author!,
                          style: Theme.of(context).textTheme.bodySmall),
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

// ── Detail page ──────────────────────────────────────────────────────────────

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
          Text(current.title,
              style: Theme.of(context).textTheme.headlineSmall),
          if (current.author != null)
            Text(current.author!,
                style: Theme.of(context).textTheme.bodyMedium),
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

// ── Form page ────────────────────────────────────────────────────────────────

class ReadingFormPage extends ConsumerStatefulWidget {
  const ReadingFormPage({super.key, this.existingItem});
  final ReadingItem? existingItem;

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

  @override
  void initState() {
    super.initState();
    final i = widget.existingItem;
    _titleCtrl = TextEditingController(text: i?.title ?? '');
    _authorCtrl = TextEditingController(text: i?.author ?? '');
    _pagesCtrl =
        TextEditingController(text: i?.totalPages?.toString() ?? '');
    _notesCtrl = TextEditingController(text: i?.notes ?? '');
    _type = i?.type ?? ReadingType.book;
    _status = i?.status ?? ReadingStatus.wishlist;
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
      startedAt: widget.existingItem?.startedAt,
      completedAt: widget.existingItem?.completedAt,
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
    );
    ref.read(readingProvider.notifier).save(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existingItem != null ? 'Modifica' : 'Aggiungi'),
        actions: [TextButton(onPressed: _save, child: const Text('Salva'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type
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
                  labelText: _type == ReadingType.book
                      ? 'Pagine totali'
                      : 'Ore totali',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Status
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

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nessuna lettura',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Aggiungi libri, corsi e articoli',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
      );
}
