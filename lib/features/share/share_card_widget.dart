import 'package:flutter/material.dart';

import '../feed/domain/lesson.dart';

/// A clean, self-contained card rendered off-screen for sharing.
/// Wrap this in RepaintBoundary to capture as PNG.
class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1830), Color(0xFF2D2760)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withAlpha(100)),
              ),
              child: Text(
                lesson.category,
                style: const TextStyle(
                  color: Color(0xFFADA8FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hook
            Text(
              lesson.hook,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 36),

            // Branding footer
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Thumbler',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
