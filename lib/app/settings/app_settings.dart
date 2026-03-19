import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/study/data/deck_library_storage.dart';

enum AppLanguage { italian, english }

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.italian => const Locale('it'),
    AppLanguage.english => const Locale('en'),
  };

  String get storageValue => switch (this) {
    AppLanguage.italian => 'it',
    AppLanguage.english => 'en',
  };

  static AppLanguage fromStorage(String? value) {
    return switch (value) {
      'en' => AppLanguage.english,
      _ => AppLanguage.italian,
    };
  }
}

extension AppThemeModeX on ThemeMode {
  String get storageValue => switch (this) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode fromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

class AppSettingsState {
  const AppSettingsState({
    required this.language,
    required this.themeMode,
    this.dailyCardGoal = 20,
    this.cardFontScale = 1.0,
    this.amoledDark = false,
  });

  final AppLanguage language;
  final ThemeMode themeMode;
  final int dailyCardGoal;
  final double cardFontScale;
  final bool amoledDark;

  Locale get locale => language.locale;
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  final _storage = const DeckLibraryStorage();

  @override
  AppSettingsState build() {
    final language = AppLanguageX.fromStorage(
      _storage.loadPreferredLanguageCode(),
    );
    final themeMode = AppThemeModeX.fromStorage(_storage.loadThemeMode());
    final dailyCardGoal = _storage.loadDailyCardGoal();
    final cardFontScale = _storage.loadCardFontScale();
    final amoledDark = _storage.loadAmoledDark();
    return AppSettingsState(
      language: language,
      themeMode: themeMode,
      dailyCardGoal: dailyCardGoal,
      cardFontScale: cardFontScale,
      amoledDark: amoledDark,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _storage.savePreferredLanguageCode(language.storageValue);
    state = AppSettingsState(
      language: language,
      themeMode: state.themeMode,
      dailyCardGoal: state.dailyCardGoal,
      cardFontScale: state.cardFontScale,
      amoledDark: state.amoledDark,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.saveThemeMode(mode.storageValue);
    state = AppSettingsState(
      language: state.language,
      themeMode: mode,
      dailyCardGoal: state.dailyCardGoal,
      cardFontScale: state.cardFontScale,
      amoledDark: state.amoledDark,
    );
  }

  Future<void> setDailyCardGoal(int goal) async {
    await _storage.saveDailyCardGoal(goal);
    state = AppSettingsState(
      language: state.language,
      themeMode: state.themeMode,
      dailyCardGoal: goal,
      cardFontScale: state.cardFontScale,
      amoledDark: state.amoledDark,
    );
  }

  Future<void> setCardFontScale(double scale) async {
    await _storage.saveCardFontScale(scale);
    state = AppSettingsState(
      language: state.language,
      themeMode: state.themeMode,
      dailyCardGoal: state.dailyCardGoal,
      cardFontScale: scale,
      amoledDark: state.amoledDark,
    );
  }

  Future<void> setAmoledDark(bool enabled) async {
    await _storage.saveAmoledDark(enabled);
    state = AppSettingsState(
      language: state.language,
      themeMode: state.themeMode,
      dailyCardGoal: state.dailyCardGoal,
      cardFontScale: state.cardFontScale,
      amoledDark: enabled,
    );
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );
