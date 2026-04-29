import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

enum AppInitialPropertyDisplayMode { collapsed, expanded }

enum AppThemeSeed {
  classicDeepPurple,
  violet,
  blue,
  teal,
  green,
  coral,
  orange,
  amber,
  rose,
  berry,
  slate,
}

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

extension AppInitialPropertyDisplayModePreferenceX
    on AppInitialPropertyDisplayMode {
  static AppInitialPropertyDisplayMode fromPreference(String? value) {
    return switch (value) {
      'collapsed' => AppInitialPropertyDisplayMode.collapsed,
      'expanded' => AppInitialPropertyDisplayMode.expanded,
      _ => AppInitialPropertyDisplayMode.collapsed,
    };
  }
}

extension AppThemeSeedPreferenceX on AppThemeSeed {
  static AppThemeSeed fromPreference(String? value) {
    return switch (value) {
      'classicDeepPurple' => AppThemeSeed.classicDeepPurple,
      'violet' => AppThemeSeed.violet,
      'blue' => AppThemeSeed.blue,
      'teal' => AppThemeSeed.teal,
      'green' => AppThemeSeed.green,
      'coral' => AppThemeSeed.coral,
      'orange' => AppThemeSeed.orange,
      'amber' => AppThemeSeed.amber,
      'rose' => AppThemeSeed.rose,
      'berry' => AppThemeSeed.berry,
      'slate' => AppThemeSeed.slate,
      _ => AppThemeSeed.classicDeepPurple,
    };
  }
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.dark) AppThemeMode themeMode,
    @Default(AppThemeSeed.classicDeepPurple) AppThemeSeed themeSeed,
    @Default(true) bool openingAnimationEnabled,
    @Default(AppInitialPropertyDisplayMode.collapsed)
    AppInitialPropertyDisplayMode initialPropertyDisplayMode,
  }) = _AppSettings;
}
