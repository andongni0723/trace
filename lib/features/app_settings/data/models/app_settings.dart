import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeSeed { classicDeepPurple, violet, teal, coral, amber, berry }

extension AppThemeModePreferenceX on AppThemeMode {
  static AppThemeMode fromPreference(String? value) {
    return switch (value) {
      'system' => AppThemeMode.system,
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.dark,
    };
  }
}

extension AppThemeSeedPreferenceX on AppThemeSeed {
  static AppThemeSeed fromPreference(String? value) {
    return switch (value) {
      'classicDeepPurple' => AppThemeSeed.classicDeepPurple,
      'violet' => AppThemeSeed.violet,
      'teal' => AppThemeSeed.teal,
      'coral' => AppThemeSeed.coral,
      'amber' => AppThemeSeed.amber,
      'berry' => AppThemeSeed.berry,
      _ => AppThemeSeed.classicDeepPurple,
    };
  }
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.dark) AppThemeMode themeMode,
    @Default(AppThemeSeed.classicDeepPurple) AppThemeSeed themeSeed,
  }) = _AppSettings;
}
