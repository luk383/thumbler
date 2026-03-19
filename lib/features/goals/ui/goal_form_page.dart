import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/goal.dart';
import '../state/goals_notifier.dart';

class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key, this.existingGoal});
  final Goal? existingGoal;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late GoalArea _area;
  DateTime? _targetDate;
  final List<TextEditingController> _milestonesCtrls = [];

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _area = g?.area ?? GoalArea.personal;
    _targetDate = g?.targetDate;
    if (g != null) {
      for (final m in g.milestones) {
        _milestonesCtrls.add(TextEditingController(text: m.text));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _milestonesCtrls) { c.dispose(); }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final milestones = _milestonesCtrls
        .where((c) => c.text.trim().isNotEmpty)
        .mapIndexed((i, c) => GoalMilestone(
              id: widget.existingGoal?.milestones.length != null &&
                      i < widget.existingGoal!.milestones.length
                  ? widget.existingGoal!.milestones[i].id
                  : 'ms_${DateTime.now().millisecondsSinceEpoch}_$i',
              text: c.text.trim(),
              done: widget.existingGoal?.milestones.length != null &&
                      i < widget.existingGoal!.milestones.length
                  ? widget.existingGoal!.milestones[i].done
                  : false,
            ))
        .toList();

    final goal = Goal(
      id: widget.existingGoal?.id ??
          'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      area: _area,
      targetDate: _targetDate,
      milestones: milestones,
      completed: widget.existingGoal?.completed ?? false,
      createdAt: widget.existingGoal?.createdAt ?? DateTime.now(),
    );

    if (widget.existingGoal != null) {
      ref.read(goalsProvider.notifier).update(goal);
    } else {
      ref.read(goalsProvider.notifier).add(goal);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGoal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica obiettivo' : 'Nuovo obiettivo'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Salva')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Area selector
            Text('Area', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: GoalArea.values
                  .map((a) => ChoiceChip(
                        label: Text('${a.emoji} ${a.label}'),
                        selected: _area == a,
                        onSelected: (_) => setState(() => _area = a),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo obiettivo *',
                hintText: 'es. Ottenere la certificazione Security+',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Il titolo è obbligatorio'
                  : null,
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                hintText: 'Perché è importante per te?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Target date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_targetDate == null
                  ? 'Nessuna data di scadenza'
                  : _formatDate(_targetDate!)),
              trailing: _targetDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _targetDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Milestones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Milestone',
                    style: Theme.of(context).textTheme.labelLarge),
                TextButton.icon(
                  onPressed: () => setState(
                      () => _milestonesCtrls.add(TextEditingController())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
            ..._milestonesCtrls.mapIndexed((i, ctrl) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            hintText: 'Milestone ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(
                            () => _milestonesCtrls.removeAt(i)),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(isEdit ? 'Salva modifiche' : 'Crea obiettivo'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

extension _IndexedMapExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) sync* {
    var i = 0;
    for (final item in this) {
      yield f(i++, item);
    }
  }
}
