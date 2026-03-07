import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
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
  await Hive.openBox('xp_box');
  await Hive.openBox('streak_box');
  await Hive.openBox('bookmarks_box');
  await Hive.openBox('quest_box');
  await Hive.openBox('study_box');
  await Hive.openBox('exam_box');
  await Hive.openBox('library_box');

  await configureRevenueCat();

  runApp(const ProviderScope(child: ThumblerApp()));
}
