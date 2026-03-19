import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/services/notifications/notification_service.dart';
import 'features/paywall/pro_guard.dart' show configureRevenueCat;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  // Core study boxes
  await Hive.openBox('xp_box');
  await Hive.openBox('streak_box');
  await Hive.openBox('bookmarks_box');
  await Hive.openBox('quest_box');
  await Hive.openBox('study_box');
  await Hive.openBox('exam_box');
  await Hive.openBox('library_box');
  // Personal growth boxes
  await Hive.openBox('goals_box');
  await Hive.openBox('habits_box');
  await Hive.openBox('reflection_box');
  await Hive.openBox('journal_box');
  await Hive.openBox('reading_box');
  await Hive.openBox('notifications_box');

  await configureRevenueCat();
  await NotificationService.init();

  runApp(const ProviderScope(child: WolfLabApp()));
}
