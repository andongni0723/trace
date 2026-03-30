import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trace/features/app_settings/data/models/app_settings.dart';
import 'package:trace/features/app_settings/providers/app_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app settings defaults to dark theme mode', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(appSettingsProvider.future);

    expect(settings.themeMode, AppThemeMode.dark);
  });

  test('setThemeMode persists the selected theme mode', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.future);
    await container
        .read(appSettingsActionsProvider)
        .setThemeMode(AppThemeMode.light);

    expect(
      container
          .read(appSettingsProvider)
          .maybeWhen(
            data: (settings) => settings.themeMode,
            orElse: () => null,
          ),
      AppThemeMode.light,
    );

    final sharedPreferences = await SharedPreferences.getInstance();
    expect(
      sharedPreferences.getString('app_settings.theme_mode'),
      AppThemeMode.light.name,
    );
  });
}
