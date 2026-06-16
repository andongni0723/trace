import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../revision_log/data/models/revision_log_action.dart';
import '../../revision_log/providers/revision_log_provider.dart';
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

  Future<void> setOpeningAnimationEnabled(bool enabled) async {
    final currentSettings = state.maybeWhen(
      data: (settings) => settings,
      orElse: () => const AppSettings(),
    );
    final nextSettings = currentSettings.copyWith(
      openingAnimationEnabled: enabled,
    );

    state = AsyncData(nextSettings);
    state = await AsyncValue.guard(() async {
      final repository = await _repository;
      return repository.save(nextSettings);
    });
  }

  Future<void> setInitialPropertyDisplayMode(
    AppInitialPropertyDisplayMode mode,
  ) async {
    final currentSettings = state.maybeWhen(
      data: (settings) => settings,
      orElse: () => const AppSettings(),
    );
    final nextSettings = currentSettings.copyWith(
      initialPropertyDisplayMode: mode,
    );

    state = AsyncData(nextSettings);
    state = await AsyncValue.guard(() async {
      final repository = await _repository;
      return repository.save(nextSettings);
    });
  }

  Future<void> replaceSettings(AppSettings settings) async {
    state = AsyncData(settings);
    state = await AsyncValue.guard(() async {
      final repository = await _repository;
      return repository.save(settings);
    });
  }
}

class AppSettingsActions {
  AppSettingsActions(this._ref);

  final Ref _ref;

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    final before = await _readSettings();
    await _ref.read(appSettingsProvider.notifier).setThemeMode(themeMode);
    final after = await _readSettings();
    await _recordSettingsChange(
      changedFields: const ['themeMode'],
      before: before,
      after: after,
    );
  }

  Future<void> setThemeSeed(AppThemeSeed themeSeed) async {
    final before = await _readSettings();
    await _ref.read(appSettingsProvider.notifier).setThemeSeed(themeSeed);
    final after = await _readSettings();
    await _recordSettingsChange(
      changedFields: const ['themeSeed'],
      before: before,
      after: after,
    );
  }

  Future<void> setOpeningAnimationEnabled(bool enabled) async {
    final before = await _readSettings();
    await _ref
        .read(appSettingsProvider.notifier)
        .setOpeningAnimationEnabled(enabled);
    final after = await _readSettings();
    await _recordSettingsChange(
      changedFields: const ['openingAnimationEnabled'],
      before: before,
      after: after,
    );
  }

  Future<void> setInitialPropertyDisplayMode(
    AppInitialPropertyDisplayMode mode,
  ) async {
    final before = await _readSettings();
    await _ref
        .read(appSettingsProvider.notifier)
        .setInitialPropertyDisplayMode(mode);
    final after = await _readSettings();
    await _recordSettingsChange(
      changedFields: const ['initialPropertyDisplayMode'],
      before: before,
      after: after,
    );
  }

  Future<void> replaceSettings(AppSettings settings) {
    return _ref.read(appSettingsProvider.notifier).replaceSettings(settings);
  }

  Future<AppSettings> _readSettings() async {
    try {
      return await _ref.read(appSettingsProvider.future);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _recordSettingsChange({
    required List<String> changedFields,
    required AppSettings before,
    required AppSettings after,
  }) {
    return _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.settings,
          entityType: 'appSettings',
          entityId: 'appSettings',
          entityLabel: 'Settings',
          summary: 'Updated app settings',
          changedFields: changedFields,
          before: _settingsSnapshot(before),
          after: _settingsSnapshot(after),
        );
  }

  Map<String, Object?> _settingsSnapshot(AppSettings settings) {
    return {
      'themeMode': settings.themeMode.name,
      'themeSeed': settings.themeSeed.name,
      'openingAnimationEnabled': settings.openingAnimationEnabled,
      'initialPropertyDisplayMode': settings.initialPropertyDisplayMode.name,
    };
  }
}
