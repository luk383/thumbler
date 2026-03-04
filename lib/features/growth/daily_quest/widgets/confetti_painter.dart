import 'dart:math';

import 'package:flutter/material.dart';

class ConfettiParticle {
  ConfettiParticle({
    required this.x,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spin,
  });

  final double x;   // normalised start x (0–1)
  final double vx;  // horizontal drift (normalised)
  final double vy;  // downward speed factor
  final Color color;
  final double size;
  final double rotation; // initial angle (radians)
  final double spin;     // rotations per animation cycle

  static const _colors = [
    Colors.yellow,
    Colors.pink,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.red,
  ];

  static List<ConfettiParticle> generate(int count) {
    final rng = Random();
    return List.generate(count, (_) => ConfettiParticle(
      x: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.6,
      vy: rng.nextDouble() * 0.5 + 0.5,
      color: _colors[rng.nextInt(_colors.length)],
      size: rng.nextDouble() * 10 + 5,
      rotation: rng.nextDouble() * 2 * pi,
      spin: (rng.nextDouble() - 0.5) * 6 * pi,
    ));
  }
}

class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  /// 0.0 → 1.0 as the animation runs.
  final double progress;
  final List<ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final alpha = (255 * (1.0 - progress * 0.85)).round().clamp(0, 255);
      paint.color = p.color.withAlpha(alpha);

      final x = p.x * size.width + p.vx * progress * size.width * 0.6;
      final y = -20 + p.vy * progress * (size.height + 40);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.45,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.progress != progress;
}
