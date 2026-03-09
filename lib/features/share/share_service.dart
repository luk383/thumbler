import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../feed/domain/lesson.dart';
import 'share_card_widget.dart';

class ShareService {
  /// Share a lesson as a PNG image (falls back to plain text on error).
  static Future<void> shareLesson(
    BuildContext context,
    Lesson lesson,
  ) async {
    try {
      await _shareAsImage(context, lesson);
    } catch (_) {
      await _shareAsText(lesson);
    }
  }

  static Future<void> _shareAsImage(
      BuildContext context, Lesson lesson) async {
    final key = GlobalKey();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        // Render off-screen so layout runs but is invisible to the user.
        left: -10000,
        top: 0,
        child: SizedBox(
          width: 400,
          child: RepaintBoundary(
            key: key,
            child: ShareCardWidget(lesson: lesson),
          ),
        ),
      ),
    );

    if (!context.mounted) throw Exception('unmounted');
    Overlay.of(context).insert(entry);

    try {
      // Allow one frame for layout + painting.
      await Future.delayed(const Duration(milliseconds: 200));

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wolf_lab_${lesson.id}.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: lesson.hook,
        ),
      );
    } finally {
      entry.remove();
    }
  }

  static Future<void> _shareAsText(Lesson lesson) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${lesson.hook}\n\n${lesson.explanation}',
      ),
    );
  }
}
