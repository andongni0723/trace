import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trace/core/database/database.dart';
import 'package:trace/features/app_settings/data/models/app_settings.dart';
import 'package:trace/features/app_settings/providers/app_settings_provider.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer() {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('app settings defaults to dark theme mode', () async {
    final container = createContainer();

    final settings = await container.read(appSettingsProvider.future);

    expect(settings.themeMode, AppThemeMode.dark);
    expect(
      settings.initialPropertyDisplayMode,
      AppInitialPropertyDisplayMode.collapsed,
    );
  });

  test('setThemeMode persists the selected theme mode', () async {
    final container = createContainer();

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

  test('setInitialPropertyDisplayMode persists the selected mode', () async {
    final container = createContainer();

    await container.read(appSettingsProvider.future);
    await container
        .read(appSettingsActionsProvider)
        .setInitialPropertyDisplayMode(AppInitialPropertyDisplayMode.expanded);

    expect(
      container
          .read(appSettingsProvider)
          .maybeWhen(
            data: (settings) => settings.initialPropertyDisplayMode,
            orElse: () => null,
          ),
      AppInitialPropertyDisplayMode.expanded,
    );

    final sharedPreferences = await SharedPreferences.getInstance();
    expect(
      sharedPreferences.getString('app_settings.initial_property_display_mode'),
      AppInitialPropertyDisplayMode.expanded.name,
    );
  });
}
