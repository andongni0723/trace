import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._sharedPreferences);

  static const _themeModeKey = 'app_settings.theme_mode';

  final SharedPreferences _sharedPreferences;

  Future<AppSettings> load() async {
    return AppSettings(
      themeMode: AppThemeModePreferenceX.fromPreference(
        _sharedPreferences.getString(_themeModeKey),
      ),
    );
  }

  Future<AppSettings> save(AppSettings settings) async {
    await _sharedPreferences.setString(_themeModeKey, settings.themeMode.name);

    return settings;
  }
}
