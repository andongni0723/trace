import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/app_settings.dart';
import '../data/repositories/app_settings_repository.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final appSettingsRepositoryProvider = FutureProvider<AppSettingsRepository>((
  ref,
) async {
  final sharedPreferences = await ref.watch(sharedPreferencesProvider.future);
  return AppSettingsRepository(sharedPreferences);
});

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

final appSettingsActionsProvider = Provider<AppSettingsActions>((ref) {
  return AppSettingsActions(ref);
});

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  Future<AppSettingsRepository> get _repository =>
      ref.read(appSettingsRepositoryProvider.future);

  @override
  Future<AppSettings> build() async {
    final repository = await _repository;
    return repository.load();
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    final currentSettings = state.maybeWhen(
      data: (settings) => settings,
      orElse: () => const AppSettings(),
    );
    final nextSettings = currentSettings.copyWith(themeMode: themeMode);

    state = AsyncData(nextSettings);
    state = await AsyncValue.guard(() async {
      final repository = await _repository;
      return repository.save(nextSettings);
    });
  }

  Future<void> setThemeSeed(AppThemeSeed themeSeed) async {
    final currentSettings = state.maybeWhen(
      data: (settings) => settings,
      orElse: () => const AppSettings(),
    );
    final nextSettings = currentSettings.copyWith(themeSeed: themeSeed);

    state = AsyncData(nextSettings);
    state = await AsyncValue.guard(() async {
      final repository = await _repository;
      return repository.save(nextSettings);
    });
  }
}

class AppSettingsActions {
  AppSettingsActions(this._ref);

  final Ref _ref;

  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _ref.read(appSettingsProvider.notifier).setThemeMode(themeMode);
  }

  Future<void> setThemeSeed(AppThemeSeed themeSeed) {
    return _ref.read(appSettingsProvider.notifier).setThemeSeed(themeSeed);
  }
}
