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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
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

    final options = _optionCtrls.map((c) => c.text.trim()).toList();
    final activeDeckId = ref.read(activeDeckIdProvider);

    final noteText = _noteCtrl.text.trim();
    final item = StudyItem(
      id: widget.existingItem?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      deckId: activeDeckId,
      contentType: ContentType.microCard,
      category: _category.trim().isEmpty ? 'Generale' : _category.trim(),
      topic: _topic?.trim().isEmpty == true ? null : _topic?.trim(),
      promptText: _questionCtrl.text.trim(),
      explanationText: _explanationCtrl.text.trim().isEmpty
          ? null
          : _explanationCtrl.text.trim(),
      options: options,
      correctAnswerIndex: _correctIndex,
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

            // Question
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
