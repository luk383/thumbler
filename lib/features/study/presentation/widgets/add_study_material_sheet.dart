import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../data/user_deck_service.dart';
import '../../domain/user_deck_draft.dart';
import '../controllers/deck_library_controller.dart';
import '../pages/generate_deck_from_notes_page.dart';
import '../pages/user_deck_editor_page.dart';

Future<void> showAddStudyMaterialSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F0D1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _AddStudyMaterialSheet(ref: ref),
  );
}

Future<void> importJsonDeck(
  BuildContext context,
  WidgetRef ref, {
  bool closeCurrentRoute = false,
}) async {
  if (closeCurrentRoute) {
    Navigator.of(context).pop();
  }
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Unable to read the selected JSON file');
    }

    final raw = utf8.decode(bytes);
    final draft = const UserDeckService().normalizeImportedJson(
      raw,
      fallbackCategory: 'Imported Deck',
    );
    await const UserDeckService().saveDeck(draft);
    await ref.read(deckLibraryProvider.notifier).discoverPacks();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${draft.title} added to your library'),
        backgroundColor: const Color(0xFF0D8B5F),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class _AddStudyMaterialSheet extends StatelessWidget {
  const _AddStudyMaterialSheet({required this.ref});

  final WidgetRef ref;

  Future<void> _openGenerate(BuildContext context) async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GenerateDeckFromNotesPage(),
      ),
    );
  }

  Future<void> _openManual(BuildContext context) async {
    Navigator.of(context).pop();
    final draft = UserDeckDraft(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      category: '',
      questions: [
        UserDeckQuestionDraft(
          question: '',
          answers: const ['', '', '', ''],
          correctIndex: 0,
        ),
      ],
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserDeckEditorPage(
          initialDraft: draft,
          pageTitle: 'Create Deck Manually',
        ),
      ),
    );
  }

  Future<void> _importJson(BuildContext context) async {
    await importJsonDeck(context, ref, closeCurrentRoute: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageIntro(
              title: 'Add Study Material',
              subtitle:
                  'Create your own local decks and keep them compatible with Feed, Study, and Exam.',
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.note_alt_outlined,
              title: 'Generate from Notes or Text',
              subtitle:
                  'Paste notes or upload a PDF, then review generated questions before saving.',
              onTap: () => _openGenerate(context),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.edit_note_outlined,
              title: 'Create Deck Manually',
              subtitle:
                  'Write your own deck title, questions, answers, and explanations from scratch.',
              onTap: () => _openManual(context),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.file_upload_outlined,
              title: 'Import JSON Deck',
              subtitle:
                  'Choose a local JSON deck file, validate it, and add it straight to your library.',
              onTap: () => _importJson(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      radius: 20,
      tint: const Color(0xFF6C63FF),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AppSurfaceIcon(icon: icon, tint: const Color(0xFF6C63FF)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, height: 1.35),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white54,
        ),
      ),
    );
  }
}
