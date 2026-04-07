import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';

import '../../data/models/app_settings.dart';
import '../../providers/app_settings_provider.dart';

class AppSettingsBottomSheet extends ConsumerWidget {
  const AppSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (settings) => settings,
          orElse: () => const AppSettings(),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appSettings.title'.tr(),
              style: context.tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'appSettings.themeMode.title'.tr(),
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<AppThemeMode>(
              groupValue: appSettings.themeMode,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }

                AppHaptics.selection();
                await ref.read(appSettingsActionsProvider).setThemeMode(value);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Column(
                children: AppThemeMode.values
                    .map((themeMode) {
                      return RadioListTile<AppThemeMode>(
                        contentPadding: EdgeInsets.zero,
                        value: themeMode,
                        title: Text(_themeModeLabel(themeMode).tr()),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _themeModeLabel(AppThemeMode themeMode) {
  return switch (themeMode) {
    AppThemeMode.system => 'appSettings.themeMode.system',
    AppThemeMode.light => 'appSettings.themeMode.light',
    AppThemeMode.dark => 'appSettings.themeMode.dark',
  };
}
