import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._sharedPreferences);

  static const _themeModeKey = 'app_settings.theme_mode';
  static const _themeSeedKey = 'app_settings.theme_seed';
  static const _openingAnimationEnabledKey =
      'app_settings.opening_animation_enabled';

  final SharedPreferences _sharedPreferences;

  Future<AppSettings> load() async {
    return AppSettings(
      themeMode: AppThemeModePreferenceX.fromPreference(
        _sharedPreferences.getString(_themeModeKey),
      ),
      themeSeed: AppThemeSeedPreferenceX.fromPreference(
        _sharedPreferences.getString(_themeSeedKey),
      ),
      openingAnimationEnabled:
          _sharedPreferences.getBool(_openingAnimationEnabledKey) ?? true,
    );
  }

  Future<AppSettings> save(AppSettings settings) async {
    await _sharedPreferences.setString(_themeModeKey, settings.themeMode.name);
    await _sharedPreferences.setString(_themeSeedKey, settings.themeSeed.name);
    await _sharedPreferences.setBool(
      _openingAnimationEnabledKey,
      settings.openingAnimationEnabled,
    );

    return settings;
  }
}
