import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum AppThemeMode { system, light, dark }

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

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.dark) AppThemeMode themeMode,
  }) = _AppSettings;
}
