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
    final seedColor = _seedColorOf(appSettings.themeSeed);

    return MaterialApp.router(
      title: 'Snap Ledger',
      onGenerateTitle: (context) => 'app.title'.tr(),
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      locale: context.locale,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
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

Color _seedColorOf(AppThemeSeed themeSeed) {
  return switch (themeSeed) {
    AppThemeSeed.classicDeepPurple => Colors.deepPurple,
    AppThemeSeed.violet => const Color(0xFF6750A4),
    AppThemeSeed.blue => const Color(0xFF355F9D),
    AppThemeSeed.teal => const Color(0xFF006A6A),
    AppThemeSeed.green => const Color(0xFF406836),
    AppThemeSeed.coral => const Color(0xFFB3261E),
    AppThemeSeed.orange => const Color(0xFF9A4600),
    AppThemeSeed.amber => const Color(0xFF8C5000),
    AppThemeSeed.rose => const Color(0xFFB03060),
    AppThemeSeed.berry => const Color(0xFF904A72),
    AppThemeSeed.slate => const Color(0xFF5C5F77),
  };
}
