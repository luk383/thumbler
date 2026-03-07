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

class AppSettingsState {
  const AppSettingsState({required this.language});

  final AppLanguage language;

  Locale get locale => language.locale;
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  final _storage = const DeckLibraryStorage();

  @override
  AppSettingsState build() {
    final language = AppLanguageX.fromStorage(
      _storage.loadPreferredLanguageCode(),
    );
    return AppSettingsState(language: language);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _storage.savePreferredLanguageCode(language.storageValue);
    state = AppSettingsState(language: language);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );
