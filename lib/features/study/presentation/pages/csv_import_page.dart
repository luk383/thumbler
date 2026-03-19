import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/user_deck_service.dart';
import 'user_deck_editor_page.dart';

class CsvImportPage extends StatefulWidget {
  const CsvImportPage({super.key});

  @override
  State<CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends State<CsvImportPage> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _csvCtrl = TextEditingController();

  bool _loading = false;
  bool _showHelp = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _csvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) throw const FormatException('Impossibile leggere il file.');
      _csvCtrl.text = String.fromCharCodes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File caricato ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    final title = _titleCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final csv = _csvCtrl.text.trim();

    if (title.isEmpty || category.isEmpty || csv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila titolo, categoria e CSV.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final draft = const UserDeckService().importFromCsv(
        title: title,
        category: category,
        csvText: csv,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserDeckEditorPage(
            initialDraft: draft,
            pageTitle: 'Rivedi deck importato',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importa da CSV')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Format help toggle
          GestureDetector(
            onTap: () => setState(() => _showHelp = !_showHelp),
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  _showHelp ? 'Nascondi formati supportati' : 'Vedi formati supportati',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          if (_showHelp) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Formato completo (≥6 colonne):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(
                    'domanda;A;B;C;D;indice_corretto[;categoria[;spiegazione]]\n'
                    'Dove indice_corretto è 0-3 (posizione della risposta corretta).',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                  SizedBox(height: 10),
                  Text('🃏 Formato corto (2 colonne, min 4 righe):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(
                    'fronte;retro\n'
                    'I retro degli altri fronti vengono usati come distrattori.',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Separatori supportati: ; (punto e virgola), , (virgola), \\t (tab).\n'
                    'La prima riga viene ignorata se sembra un\'intestazione.',
                    style: TextStyle(fontSize: 10, height: 1.5),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titolo deck *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Categoria *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _csvCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Incolla CSV qui…',
              hintText:
                  'Cos\'è il TCP?;Transmission Control Protocol;...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickCsv,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: const Text('Carica file CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _import,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Importa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
