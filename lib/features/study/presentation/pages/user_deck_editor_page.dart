import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../data/user_deck_service.dart';
import '../../domain/user_deck_draft.dart';
import '../controllers/deck_library_controller.dart';

class UserDeckEditorPage extends ConsumerStatefulWidget {
  const UserDeckEditorPage({
    super.key,
    required this.initialDraft,
    required this.pageTitle,
  });

  final UserDeckDraft initialDraft;
  final String pageTitle;

  @override
  ConsumerState<UserDeckEditorPage> createState() => _UserDeckEditorPageState();
}

class _UserDeckEditorPageState extends ConsumerState<UserDeckEditorPage> {
  late UserDeckDraft _draft;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draft = UserDeckDraft(
      id: widget.initialDraft.id,
      title: widget.initialDraft.title,
      category: widget.initialDraft.category,
      description: widget.initialDraft.description,
      questions: widget.initialDraft.questions
          .map((question) => question.copy())
          .toList(),
    );
  }

  Future<void> _saveDeck() async {
    final issues = _draft.validate();
    if (issues.isNotEmpty) {
      _showMessage(issues.first, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await const UserDeckService().saveDeck(_draft);
      await ref.read(deckLibraryProvider.notifier).discoverPacks();
      if (!mounted) return;
      _showMessage('Deck saved to your library');
      Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF0D8B5F),
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _draft.questions.add(
        UserDeckQuestionDraft(
          question: '',
          answers: const ['', '', '', ''],
          correctIndex: 0,
          domain: _draft.category,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.pageTitle),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDeck,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const AppPageIntro(
            title: 'Deck Builder',
            subtitle:
                'Edit deck details and keep every question concise and mobile-friendly.',
          ),
          const SizedBox(height: 16),
          AppGlassCard(
            padding: const EdgeInsets.all(18),
            radius: 22,
            tint: const Color(0xFF6C63FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TextField(
                  label: 'Title',
                  initialValue: _draft.title,
                  onChanged: (value) => _draft.title = value,
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Category',
                  initialValue: _draft.category,
                  onChanged: (value) {
                    _draft.category = value;
                    for (final question in _draft.questions) {
                      if (question.domain.trim().isEmpty) {
                        question.domain = value;
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Description',
                  initialValue: _draft.description,
                  maxLines: 3,
                  onChanged: (value) => _draft.description = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._draft.questions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestionEditorCard(
                key: ValueKey('question_${entry.key}'),
                index: entry.key,
                draft: entry.value,
                defaultDomain: _draft.category,
                onDelete: _draft.questions.length <= 1
                    ? null
                    : () =>
                          setState(() => _draft.questions.removeAt(entry.key)),
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionEditorCard extends StatelessWidget {
  const _QuestionEditorCard({
    super.key,
    required this.index,
    required this.draft,
    required this.defaultDomain,
    required this.onChanged,
    this.onDelete,
  });

  final int index;
  final UserDeckQuestionDraft draft;
  final String defaultDomain;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      tint: const Color(0xFF12B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          _TextField(
            label: 'Question',
            initialValue: draft.question,
            maxLines: 3,
            onChanged: (value) {
              draft.question = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < draft.answers.length; i++) ...[
            _TextField(
              label: 'Answer ${String.fromCharCode(65 + i)}',
              initialValue: draft.answers[i],
              onChanged: (value) {
                draft.answers[i] = value;
                onChanged();
              },
            ),
            const SizedBox(height: 10),
          ],
          DropdownButtonFormField<int>(
            initialValue: draft.correctIndex,
            dropdownColor: const Color(0xFF10131B),
            decoration: const InputDecoration(labelText: 'Correct answer'),
            items: List.generate(
              4,
              (index) => DropdownMenuItem(
                value: index,
                child: Text('Answer ${String.fromCharCode(65 + index)}'),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              draft.correctIndex = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _TextField(
            label: 'Explanation (optional)',
            initialValue: draft.explanation,
            maxLines: 3,
            onChanged: (value) {
              draft.explanation = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _TextField(
            label: 'Domain',
            initialValue: draft.domain.isEmpty ? defaultDomain : draft.domain,
            onChanged: (value) {
              draft.domain = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
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
