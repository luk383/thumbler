import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/domain/habit.dart';
import '../../habits/state/habits_notifier.dart';
import '../state/notification_settings_notifier.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: ListView(
        children: [
          // Permission button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(notificationSettingsProvider.notifier)
                    .setStudyReminder(
                      settings.studyReminderEnabled,
                      settings.studyReminderTime,
                    );
                // Also triggers requestPermission internally when enabled
                // But let user explicitly request it:
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Richiesta permesso notifiche inviata'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Richiedi permesso notifiche'),
            ),
          ),
          const SizedBox(height: 8),

          // ── Studio ─────────────────────────────────────────────────────────
          const _SectionHeader('Studio'),
          SwitchListTile(
            title: const Text('Promemoria studio'),
            subtitle: Text(
              settings.studyReminderEnabled
                  ? 'Ogni giorno alle ${settings.studyReminderTime}'
                  : 'Disattivato',
            ),
            secondary: const Icon(Icons.school_outlined),
            value: settings.studyReminderEnabled,
            onChanged: (v) => ref
                .read(notificationSettingsProvider.notifier)
                .setStudyReminder(v, settings.studyReminderTime),
          ),
          if (settings.studyReminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: Text(
                settings.studyReminderTime,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Tocca per cambiare orario'),
              onTap: () async {
                final parts = settings.studyReminderTime.split(':');
                final initial = TimeOfDay(
                  hour: int.tryParse(parts[0]) ?? 8,
                  minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                );
                if (!context.mounted) return;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .setStudyReminder(true, formatted);
                }
              },
            ),

          // ── Streak ─────────────────────────────────────────────────────────
          const _SectionHeader('Streak'),
          SwitchListTile(
            title: const Text('Protezione streak'),
            subtitle: Text(
              settings.streakProtectionEnabled
                  ? 'Ogni giorno alle ${settings.streakProtectionTime}'
                  : 'Disattivato',
            ),
            secondary: const Icon(Icons.local_fire_department_outlined),
            value: settings.streakProtectionEnabled,
            onChanged: (v) => ref
                .read(notificationSettingsProvider.notifier)
                .setStreakProtection(v, settings.streakProtectionTime),
          ),
          if (settings.streakProtectionEnabled)
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: Text(
                settings.streakProtectionTime,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Tocca per cambiare orario'),
              onTap: () async {
                final parts = settings.streakProtectionTime.split(':');
                final initial = TimeOfDay(
                  hour: int.tryParse(parts[0]) ?? 20,
                  minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                );
                if (!context.mounted) return;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .setStreakProtection(true, formatted);
                }
              },
            ),

          // ── Abitudini ──────────────────────────────────────────────────────
          if (habits.isNotEmpty) ...[
            const _SectionHeader('Abitudini'),
            ...habits.map((habit) => _HabitReminderTile(habit: habit)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _HabitReminderTile extends ConsumerWidget {
  const _HabitReminderTile({required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReminder = habit.reminderTime != null;

    return ListTile(
      leading: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(habit.name),
      subtitle: Text(
        hasReminder ? 'Promemoria: ${habit.reminderTime}' : 'Nessun promemoria',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReminder)
            IconButton(
              icon: const Icon(Icons.access_time_outlined),
              tooltip: 'Cambia orario',
              onPressed: () => _pickTime(context, ref),
            ),
          Switch(
            value: hasReminder,
            onChanged: (_) => hasReminder
                ? _disableReminder(ref)
                : _pickTime(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(habitsProvider.notifier).updateHabit(
            habit.id,
            reminderTime: formatted,
          );
      // Schedule the notification
      final updatedHabit = habit.copyWith(reminderTime: formatted);
      await ref
          .read(notificationSettingsProvider.notifier)
          .scheduleHabitReminder(updatedHabit);
    }
  }

  Future<void> _disableReminder(WidgetRef ref) async {
    ref
        .read(habitsProvider.notifier)
        .updateHabit(habit.id, clearReminderTime: true);
    await ref
        .read(notificationSettingsProvider.notifier)
        .cancelHabitReminder(habit);
  }
}
