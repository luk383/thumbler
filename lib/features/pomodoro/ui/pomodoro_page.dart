import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/pomodoro_notifier.dart';

class PomodoroPage extends ConsumerStatefulWidget {
  const PomodoroPage({super.key});

  @override
  ConsumerState<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends ConsumerState<PomodoroPage> {
  @override
  void initState() {
    super.initState();
    // Listen for phase transitions to vibrate
    ref.listenManual(
      pomodoroProvider.select((s) => s.phase),
      (previous, next) {
        if (previous != null && previous != next) {
          HapticFeedback.vibrate();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    final phaseColor = switch (state.phase) {
      PomodoroPhase.work => cs.primary,
      PomodoroPhase.shortBreak => Colors.green,
      PomodoroPhase.longBreak => Colors.teal,
    };

    final phaseLabel = switch (state.phase) {
      PomodoroPhase.work => 'Concentrazione',
      PomodoroPhase.shortBreak => 'Pausa breve',
      PomodoroPhase.longBreak => 'Pausa lunga',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _showSettings(context, ref, state),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phase label
                Text(
                  phaseLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 40),

                // Circular timer
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CustomPaint(
                          painter: _CirclePainter(
                            progress: state.progress,
                            color: phaseColor,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.timeString,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${state.completedSessions} sessioni oggi',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.refresh),
                      iconSize: 28,
                      onPressed: notifier.reset,
                    ),
                    const SizedBox(width: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: phaseColor,
                        minimumSize: const Size(140, 52),
                      ),
                      icon: Icon(
                        state.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 28,
                      ),
                      label: Text(
                        state.isRunning ? 'Pausa' : 'Avvia',
                        style: const TextStyle(fontSize: 18),
                      ),
                      onPressed: notifier.startPause,
                    ),
                    const SizedBox(width: 20),
                    IconButton.outlined(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 28,
                      onPressed: notifier.skipToNext,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Phase dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final done = i < state.completedSessions % 4 ||
                        (state.completedSessions % 4 == 0 &&
                            state.completedSessions > 0 &&
                            state.phase != PomodoroPhase.work);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? phaseColor : cs.surfaceContainerHighest,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Total completed footer
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'Totale completati: ${ref.read(pomodoroProvider.notifier).totalCompleted}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(
      BuildContext context, WidgetRef ref, PomodoroState state) {
    var workMin = state.workMinutes;
    var shortMin = state.shortBreakMinutes;
    var longMin = state.longBreakMinutes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Impostazioni',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 20),
              _SliderSetting(
                label: 'Concentrazione',
                value: workMin,
                min: 5,
                max: 60,
                onChanged: (v) => setSt(() => workMin = v),
              ),
              _SliderSetting(
                label: 'Pausa breve',
                value: shortMin,
                min: 1,
                max: 15,
                onChanged: (v) => setSt(() => shortMin = v),
              ),
              _SliderSetting(
                label: 'Pausa lunga',
                value: longMin,
                min: 5,
                max: 30,
                onChanged: (v) => setSt(() => longMin = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(pomodoroProvider.notifier).updateSettings(
                        workMin: workMin,
                        shortMin: shortMin,
                        longMin: longMin,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Applica'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text('$value min',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      );
}

class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.progress != progress || old.color != color;
}
