import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reflection_entry.dart';
import '../state/reflection_notifier.dart';

class ReflectionPage extends ConsumerWidget {
  const ReflectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(reflectionProvider);
    final thisWeek = ref.read(reflectionProvider.notifier).currentWeekEntry();

    return Scaffold(
      appBar: AppBar(title: const Text('Riflessione settimanale')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current week card
          _WeekCard(
            entry: thisWeek,
            isCurrent: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReflectionFormPage(entry: thisWeek),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (all.where((e) => !_isSameWeek(e.weekStart, thisWeek.weekStart)).isNotEmpty) ...[
            Text('Settimane passate',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 10),
            ...all
                .where((e) =>
                    !_isSameWeek(e.weekStart, thisWeek.weekStart) &&
                    !e.isEmpty)
                .map((e) => _WeekCard(
                      entry: e,
                      isCurrent: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReflectionFormPage(entry: e),
                        ),
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  static bool _isSameWeek(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Week card ────────────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });
  final ReflectionEntry entry;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ws = entry.weekStart;
    final we = ws.add(const Duration(days: 6));
    final weekLabel =
        '${ws.day}/${ws.month} — ${we.day}/${we.month}/${we.year}';

    return Card(
      color: isCurrent ? cs.primaryContainer.withAlpha(80) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCurrent ? '📅 Questa settimana' : '📅 $weekLabel',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Icon(
                    entry.isEmpty
                        ? Icons.edit_note_outlined
                        : Icons.check_circle_outline,
                    color: entry.isEmpty ? cs.outline : cs.primary,
                    size: 20,
                  ),
                ],
              ),
              if (isCurrent) ...[
                const SizedBox(height: 4),
                Text(weekLabel,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (!entry.isEmpty) ...[
                const SizedBox(height: 10),
                if (entry.learned?.isNotEmpty == true)
                  _PromptRow('📖 Ho imparato', entry.learned!),
                if (entry.grateful?.isNotEmpty == true)
                  _PromptRow('🙏 Sono grato per', entry.grateful!),
                if (entry.improve?.isNotEmpty == true)
                  _PromptRow('🎯 Voglio migliorare', entry.improve!),
              ] else if (isCurrent) ...[
                const SizedBox(height: 8),
                Text(
                  'Tocca per compilare la riflessione di questa settimana',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow(this.label, this.text);
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

// ── Form page ────────────────────────────────────────────────────────────────

class ReflectionFormPage extends ConsumerStatefulWidget {
  const ReflectionFormPage({super.key, required this.entry});
  final ReflectionEntry entry;

  @override
  ConsumerState<ReflectionFormPage> createState() => _ReflectionFormPageState();
}

class _ReflectionFormPageState extends ConsumerState<ReflectionFormPage> {
  late final TextEditingController _learnedCtrl;
  late final TextEditingController _gratefulCtrl;
  late final TextEditingController _improveCtrl;
  late final TextEditingController _freeCtrl;

  @override
  void initState() {
    super.initState();
    _learnedCtrl = TextEditingController(text: widget.entry.learned ?? '');
    _gratefulCtrl = TextEditingController(text: widget.entry.grateful ?? '');
    _improveCtrl = TextEditingController(text: widget.entry.improve ?? '');
    _freeCtrl = TextEditingController(text: widget.entry.freeText ?? '');
  }

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _gratefulCtrl.dispose();
    _improveCtrl.dispose();
    _freeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.entry.copyWith(
      learned: _learnedCtrl.text.trim().isEmpty ? null : _learnedCtrl.text.trim(),
      grateful:
          _gratefulCtrl.text.trim().isEmpty ? null : _gratefulCtrl.text.trim(),
      improve:
          _improveCtrl.text.trim().isEmpty ? null : _improveCtrl.text.trim(),
      freeText: _freeCtrl.text.trim().isEmpty ? null : _freeCtrl.text.trim(),
    );
    ref.read(reflectionProvider.notifier).saveEntry(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.entry.weekStart;
    final we = ws.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: Text('${ws.day}/${ws.month} — ${we.day}/${we.month}'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Salva')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PromptField(
            emoji: '📖',
            prompt: 'Cosa ho imparato questa settimana?',
            controller: _learnedCtrl,
          ),
          const SizedBox(height: 16),
          _PromptField(
            emoji: '🙏',
            prompt: 'Per cosa sono grato?',
            controller: _gratefulCtrl,
          ),
          const SizedBox(height: 16),
          _PromptField(
            emoji: '🎯',
            prompt: 'Cosa voglio migliorare la prossima settimana?',
            controller: _improveCtrl,
          ),
          const SizedBox(height: 16),
          _PromptField(
            emoji: '💭',
            prompt: 'Pensieri liberi…',
            controller: _freeCtrl,
            maxLines: 6,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Salva riflessione'),
          ),
        ],
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  const _PromptField({
    required this.emoji,
    required this.prompt,
    required this.controller,
    this.maxLines = 3,
  });

  final String emoji;
  final String prompt;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $prompt',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      );
}
