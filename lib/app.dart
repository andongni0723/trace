import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/router.dart';
import 'core/theme/typography.dart';
import 'features/app_settings/biometric_lock/presentation/widgets/biometric_lock_gate.dart';
import 'features/app_settings/data/models/app_settings.dart';
import 'features/app_settings/providers/app_settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (settings) => settings,
          orElse: () => const AppSettings(),
        );

    return MaterialApp.router(
      title: 'Snap Ledger',
      onGenerateTitle: (context) => 'app.title'.tr(),
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      locale: context.locale,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        fontFamily: AppTypography.fontFamily,
      ),
      themeMode: _themeModeOf(appSettings.themeMode),
      builder: (context, child) {
        return BiometricLockGate(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
    );
  }
}

ThemeMode _themeModeOf(AppThemeMode themeMode) {
  return switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
