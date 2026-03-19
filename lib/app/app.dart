import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

class WolfLabApp extends ConsumerWidget {
  const WolfLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final effectiveDark = settings.amoledDark ? AppTheme.amoled : AppTheme.dark;
    return MaterialApp.router(
      title: 'Wolf Lab',
      theme: AppTheme.light,
      darkTheme: effectiveDark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
