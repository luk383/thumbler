import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../data/user_deck_service.dart';
import 'user_deck_editor_page.dart';

class GenerateDeckFromNotesPage extends StatefulWidget {
  const GenerateDeckFromNotesPage({super.key});

  @override
  State<GenerateDeckFromNotesPage> createState() =>
      _GenerateDeckFromNotesPageState();
}

class _GenerateDeckFromNotesPageState extends State<GenerateDeckFromNotesPage> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoadingPdf = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    setState(() => _isLoadingPdf = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;

      final loadedFile = file.bytes != null
          ? file
          : PlatformFile(
              name: file.name,
              path: file.path,
              size: file.size,
              bytes: file.path == null
                  ? null
                  : await File(file.path!).readAsBytes(),
            );

      final text = await const UserDeckService().extractTextFromPdf(loadedFile);
      if (!mounted) return;
      _notesController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF text extracted')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPdf = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final draft = const UserDeckService().generateFromText(
        title: _titleController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        sourceText: _notesController.text,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserDeckEditorPage(
            initialDraft: draft,
            pageTitle: 'Review Generated Deck',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Generate from Notes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const AppPageIntro(
            title: 'Generate from Notes',
            subtitle:
                'Paste text or extract text from a PDF, then review the generated questions before saving.',
          ),
          const SizedBox(height: 16),
          AppGlassCard(
            padding: const EdgeInsets.all(18),
            radius: 22,
            tint: const Color(0xFF6C63FF),
            child: Column(
              children: [
                _NotesField(controller: _titleController, label: 'Deck title'),
                const SizedBox(height: 12),
                _NotesField(controller: _categoryController, label: 'Category'),
                const SizedBox(height: 12),
                _NotesField(
                  controller: _descriptionController,
                  label: 'Description (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _NotesField(
                  controller: _notesController,
                  label: 'Paste notes or extracted text',
                  maxLines: 12,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingPdf ? null : _pickPdf,
                        icon: _isLoadingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Upload PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Generate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withAlpha(6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
