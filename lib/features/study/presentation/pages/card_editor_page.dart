import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/growth/xp/xp_notifier.dart';
import '../../domain/study_item.dart';
import '../controllers/deck_library_controller.dart';
import '../controllers/study_controller.dart';

/// Page to create or edit a custom flashcard.
class CardEditorPage extends ConsumerStatefulWidget {
  const CardEditorPage({super.key, this.existingItem});

  final StudyItem? existingItem;

  @override
  ConsumerState<CardEditorPage> createState() => _CardEditorPageState();
}

class _CardEditorPageState extends ConsumerState<CardEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionCtrl;
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _noteCtrl;
  late final List<TextEditingController> _optionCtrls;
  late int _correctIndex;
  late String _category;
  String? _topic;
  late bool _isCloze;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _isCloze = item?.contentType == ContentType.clozeCard;
    _questionCtrl = TextEditingController(text: item?.promptText ?? '');
    _explanationCtrl = TextEditingController(text: item?.explanationText ?? '');
    _noteCtrl = TextEditingController(text: item?.userNote ?? '');
    _correctIndex = item?.correctAnswerIndex ?? 0;
    _category = item?.category ?? 'Generale';
    _topic = item?.topic;

    final opts = item?.options ?? ['', '', '', ''];
    _optionCtrls = List.generate(4, (i) => TextEditingController(
      text: i < opts.length ? opts[i] : '',
    ));
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _optionCtrls) { c.dispose(); }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final activeDeckId = ref.read(activeDeckIdProvider);
    final noteText = _noteCtrl.text.trim();
    final promptText = _questionCtrl.text.trim();

    final List<String> options;
    final int correctIndex;
    final ContentType contentType;

    if (_isCloze) {
      options = const [''];
      correctIndex = 0;
      contentType = ContentType.clozeCard;
    } else {
      options = _optionCtrls.map((c) => c.text.trim()).toList();
      correctIndex = _correctIndex;
      contentType = ContentType.microCard;
    }

    final item = StudyItem(
      id: widget.existingItem?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      deckId: activeDeckId,
      contentType: contentType,
      category: _category.trim().isEmpty ? 'Generale' : _category.trim(),
      topic: _topic?.trim().isEmpty == true ? null : _topic?.trim(),
      promptText: promptText,
      explanationText: _explanationCtrl.text.trim().isEmpty
          ? null
          : _explanationCtrl.text.trim(),
      options: options,
      correctAnswerIndex: correctIndex,
      userNote: noteText.isEmpty ? null : noteText,
    );

    ref.read(studyProvider.notifier).addCustomItem(item);
    ref.read(xpProvider.notifier).addXp(XpEvent.customCard);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEdit = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica carta' : 'Nuova carta'),
        actions: [
          if (isEdit)
            IconButton(
              icon: Icon(
                widget.existingItem!.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: widget.existingItem!.isStarred
                    ? Colors.amber
                    : null,
              ),
              tooltip: widget.existingItem!.isStarred
                  ? 'Rimuovi dai preferiti'
                  : 'Aggiungi ai preferiti',
              onPressed: () {
                ref
                    .read(studyProvider.notifier)
                    .toggleStar(widget.existingItem!.id);
                Navigator.of(context).pop();
              },
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Salva'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card stats (edit mode only)
            if (isEdit) _CardStatsBar(item: widget.existingItem!),
            if (isEdit) const SizedBox(height: 16),

            // Card type selector
            _CardTypeSelector(
              isCloze: _isCloze,
              onChanged: (v) => setState(() => _isCloze = v),
            ),
            const SizedBox(height: 20),

            // Category + Topic
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria *',
                      hintText: 'es. Storia, Scienze…',
                    ),
                    onChanged: (v) => _category = v,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _topic,
                    decoration: const InputDecoration(
                      labelText: 'Argomento',
                      hintText: 'opzionale',
                    ),
                    onChanged: (v) => _topic = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question / Cloze text
            if (_isCloze) ...[
              Row(
                children: [
                  Text('Testo con lacune *', style: tt.labelLarge),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      final sel = _questionCtrl.selection;
                      final text = _questionCtrl.text;
                      if (sel.isValid && !sel.isCollapsed) {
                        final selected = text.substring(sel.start, sel.end);
                        final newText =
                            '${text.substring(0, sel.start)}{{$selected}}${text.substring(sel.end)}';
                        _questionCtrl.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(
                            offset: sel.start + selected.length + 4,
                          ),
                        );
                      } else {
                        final pos = sel.isValid ? sel.base.offset : text.length;
                        final newText =
                            '${text.substring(0, pos)}{{risposta}}${text.substring(pos)}';
                        _questionCtrl.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection(
                            baseOffset: pos + 2,
                            extentOffset: pos + 10,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_box_outlined, size: 15),
                    label: const Text('{{lacuna}}', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Usa {{testo}} per le lacune. Es: "La capitale d\'Italia è {{Roma}}"',
                style: TextStyle(color: cs.outline, fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'La capitale d\'Italia è {{Roma}}',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Il testo è obbligatorio';
                  if (!RegExp(r'\{\{[^}]+\}\}').hasMatch(v)) {
                    return 'Aggiungi almeno una lacuna con {{...}}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ] else ...[
              Text('Domanda *', style: tt.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Scrivi la domanda…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'La domanda è obbligatoria' : null,
              ),
              const SizedBox(height: 20),

              // Options
              Text('Risposte (seleziona quella corretta)', style: tt.labelLarge),
              const SizedBox(height: 8),
              for (int i = 0; i < 4; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _correctIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _correctIndex == i ? cs.primary : cs.outline,
                              width: _correctIndex == i ? 6 : 2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionCtrls[i],
                          decoration: InputDecoration(
                            hintText: 'Opzione ${i + 1}',
                            border: const OutlineInputBorder(),
                            filled: _correctIndex == i,
                            fillColor: _correctIndex == i
                                ? cs.primaryContainer.withAlpha(100)
                                : null,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Riempire tutte le opzioni'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],

            // Explanation
            Text('Spiegazione (opzionale)', style: tt.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _explanationCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Aggiungi contesto o approfondimento…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Personal note
            Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Nota personale (opzionale)', style: tt.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Appunto visibile durante il ripasso…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? 'Salva modifiche' : 'Crea carta'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card type selector ────────────────────────────────────────────────────────

class _CardTypeSelector extends StatelessWidget {
  const _CardTypeSelector({required this.isCloze, required this.onChanged});
  final bool isCloze;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          label: 'Scelta multipla',
          icon: Icons.list_alt_outlined,
          selected: !isCloze,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 10),
        _TypeChip(
          label: 'Completamento',
          icon: Icons.text_fields_outlined,
          selected: isCloze,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? cs.primary : cs.outline),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card stats bar (edit mode) ────────────────────────────────────────────────

class _CardStatsBar extends StatelessWidget {
  const _CardStatsBar({required this.item});
  final StudyItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = item.correctCount + item.wrongCount;
    final accuracy = total == 0 ? null : (item.correctCount / total * 100).round();
    final nextReview = item.nextReviewAt;
    final nextLabel = nextReview == null
        ? 'Non programmata'
        : nextReview.isBefore(DateTime.now())
            ? 'Da ripassare'
            : 'Tra ${nextReview.difference(DateTime.now()).inDays}g';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Viste',
            value: '${item.timesSeen}x',
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Accuratezza',
            value: accuracy == null ? '—' : '$accuracy%',
            color: accuracy == null
                ? null
                : accuracy >= 75
                    ? Colors.green
                    : accuracy >= 50
                        ? Colors.orange
                        : Colors.red,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Prossima',
            value: nextLabel,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'EF',
            value: item.easeFactor.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: cs.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
