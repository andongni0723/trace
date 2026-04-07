import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trace/app.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/shared/dialogs/update_version_dialog.dart';

import '../../biometric_lock/data/models/biometric_lock_settings.dart';
import '../../biometric_lock/domain/biometric_lock_policy.dart';
import '../../biometric_lock/providers/biometric_lock_provider.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_data_transfer_provider.dart';
import '../../providers/app_settings_provider.dart';

const double _tileOuterRadius = 28;
const double _tileInnerRadius = 4;

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (settings) => settings,
          orElse: () => const AppSettings(),
        );
    final biometricLockState = ref.watch(biometricLockStateProvider);
    final biometricLockData = biometricLockState.asData?.value;
    final biometricSettings =
        biometricLockData?.settings ?? const BiometricLockSettings();
    final canAuthenticate = biometricLockData?.canAuthenticate ?? false;
    final isBiometricBusy =
        biometricLockState.isLoading ||
        (biometricLockData?.isAuthenticating ?? false);

    return Scaffold(
      appBar: AppBar(title: Text('appSettings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _SectionLabel(label: 'appSettings.section.appearance'.tr()),
          _SettingsTile(
            position: _SettingsTilePosition.first,
            title: 'appSettings.themeMode.title'.tr(),
            subtitle: _themeModeLabel(appSettings.themeMode).tr(),
            leading: const Icon(Icons.palette_outlined),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemeDialog(context, ref, appSettings.themeMode),
          ),
          const SizedBox(height: 4),
          _ThemeSeedTile(
            themeSeed: appSettings.themeSeed,
            onSelected: (themeSeed) async {
              if (themeSeed == appSettings.themeSeed) {
                return;
              }
              AppHaptics.selection();
              await ref
                  .read(appSettingsActionsProvider)
                  .setThemeSeed(themeSeed);
            },
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'appSettings.section.app'.tr()),
          _SettingsTile(
            position: _SettingsTilePosition.first,
            title: 'appSettings.checkUpdate.title'.tr(),
            subtitle: 'appSettings.checkUpdate.subtitle'.tr(),
            leading: const Icon(Icons.system_update_alt_rounded),
            onTap: () => showUpdateVersionDialog(context),
          ),
          const SizedBox(height: 4),
          _SettingsSwitchTile(
            position: _SettingsTilePosition.last,
            title: 'appSettings.openingAnimation.title'.tr(),
            subtitle: 'appSettings.openingAnimation.subtitle'.tr(),
            value: appSettings.openingAnimationEnabled,
            leading: const Icon(Icons.movie_filter_outlined),
            onChanged: (value) async {
              AppHaptics.selection();
              await ref
                  .read(appSettingsActionsProvider)
                  .setOpeningAnimationEnabled(value);
            },
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'appSettings.section.security'.tr()),
          _SecurityCard(
            title: 'appSettings.fingerprint.title'.tr(),
            subtitle: 'appSettings.fingerprint.subtitle'.tr(),
            enabled: biometricSettings.enabled,
            frequencySummary: _biometricIntervalLabel(
              biometricSettings.reauthInterval,
            ).tr(),
            canAuthenticate: canAuthenticate,
            isBusy: isBiometricBusy,
            onToggle: (value) => _handleBiometricToggle(
              context,
              ref,
              value,
              canAuthenticate: canAuthenticate,
            ),
            onTapFrequency: () => _showFingerprintFrequencySheet(
              context,
              ref,
              biometricSettings.reauthInterval,
            ),
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'appSettings.section.data'.tr()),
          _SettingsTile(
            position: _SettingsTilePosition.first,
            title: 'appSettings.exportData.title'.tr(),
            subtitle: 'appSettings.exportData.subtitle'.tr(),
            leading: const Icon(Icons.ios_share_rounded),
            onTap: () => _handleExport(context, ref),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            position: _SettingsTilePosition.last,
            title: 'appSettings.importData.title'.tr(),
            subtitle: 'appSettings.importData.subtitle'.tr(),
            leading: const Icon(Icons.file_download_outlined),
            onTap: () => _handleImport(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showFingerprintFrequencySheet(
    BuildContext context,
    WidgetRef ref,
    BiometricReauthInterval currentInterval,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: RadioGroup<BiometricReauthInterval>(
              groupValue: currentInterval,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                AppHaptics.selection();

                await ref
                    .read(biometricLockStateProvider.notifier)
                    .setReauthInterval(value);

                if (!sheetContext.mounted) {
                  return;
                }

                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'appSettings.fingerprint.recheckFrequency.title'.tr(),
                    style: sheetContext.tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'appSettings.fingerprint.recheckFrequency.subtitle'.tr(),
                    style: sheetContext.tt.bodyMedium?.copyWith(
                      color: sheetContext.cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FrequencyOptionTile(
                    position: _SettingsTilePosition.first,
                    value: BiometricReauthInterval.fifteenMinutes,
                    title: 'appSettings.fingerprint.recheckFrequency.15m'.tr(),
                    subtitle: 'appSettings.fingerprint.recheckFrequency.15mHint'
                        .tr(),
                  ),
                  const SizedBox(height: 4),
                  _FrequencyOptionTile(
                    position: _SettingsTilePosition.middle,
                    value: BiometricReauthInterval.thirtyMinutes,
                    title: 'appSettings.fingerprint.recheckFrequency.30m'.tr(),
                    subtitle: 'appSettings.fingerprint.recheckFrequency.30mHint'
                        .tr(),
                  ),
                  const SizedBox(height: 4),
                  _FrequencyOptionTile(
                    position: _SettingsTilePosition.last,
                    value: BiometricReauthInterval.nextOpen,
                    title: 'appSettings.fingerprint.recheckFrequency.nextOpen'
                        .tr(),
                    subtitle:
                        'appSettings.fingerprint.recheckFrequency.nextOpenHint'
                            .tr(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentMode,
  ) async {
    final nextMode = await showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('appSettings.themeMode.title'.tr()),
          contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values
                .map((themeMode) {
                  return ListTile(
                    leading: Icon(
                      themeMode == currentMode
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                    title: Text(_themeModeLabel(themeMode).tr()),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.of(dialogContext).pop(themeMode);
                    },
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );

    if (nextMode == null || nextMode == currentMode) {
      return;
    }

    await ref.read(appSettingsActionsProvider).setThemeMode(nextMode);
  }

  Future<void> _handleBiometricToggle(
    BuildContext context,
    WidgetRef ref,
    bool value, {
    required bool canAuthenticate,
  }) async {
    final notifier = ref.read(biometricLockStateProvider.notifier);

    if (!value) {
      await notifier.setEnabled(false);
      return;
    }

    if (!canAuthenticate) {
      _showAppSnackBar(context, 'appSettings.fingerprint.unavailable'.tr());
      return;
    }

    await notifier.setEnabled(true);
    final outcome = await notifier.handleLifecycleTrigger(
      BiometricLockTrigger.appOpened,
      localizedReason: 'appSettings.fingerprint.systemPrompt'.tr(),
    );

    if (outcome.authenticated) {
      return;
    }

    await notifier.setEnabled(false);
    if (!context.mounted) {
      return;
    }

    _showAppSnackBar(context, 'appSettings.fingerprint.lockError'.tr());
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref.read(appDataTransferProvider).exportData();
      if (!context.mounted || !success) {
        return;
      }

      AppHaptics.confirm();
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('appSettings.exportData.success'.tr())),
      );
    } catch (_) {
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('appSettings.exportData.error'.tr())),
      );
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref.read(appDataTransferProvider).importData();
      if (!context.mounted || !success) {
        return;
      }

      AppHaptics.confirm();
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('appSettings.importData.success'.tr())),
      );
    } on FormatException {
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('appSettings.importData.invalidFormat'.tr())),
      );
    } catch (_) {
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('appSettings.importData.error'.tr())),
      );
    }
  }
}

void _showAppSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }

  App.scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: context.tt.labelSmall?.copyWith(
          color: context.cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.frequencySummary,
    required this.canAuthenticate,
    required this.isBusy,
    required this.onToggle,
    required this.onTapFrequency,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final String frequencySummary;
  final bool canAuthenticate;
  final bool isBusy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapFrequency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: isBusy
                ? null
                : (value) {
                    AppHaptics.selection();
                    onToggle(value);
                  },
            title: Text(title),
            subtitle: Text(
              canAuthenticate
                  ? subtitle
                  : 'appSettings.fingerprint.unavailable'.tr(),
            ),
            secondary: const Icon(Icons.fingerprint_rounded),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: context.cs.outlineVariant,
          ),
          _FrequencyTile(
            summary: frequencySummary,
            enabled: !isBusy,
            onTap: onTapFrequency,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.position,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.trailing,
  });

  final _SettingsTilePosition position;
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: _tileBorderRadiusFor(position),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: () {
          AppHaptics.primaryAction();
          onTap();
        },
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.position,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.leading,
    required this.onChanged,
  });

  final _SettingsTilePosition position;
  final String title;
  final String subtitle;
  final bool value;
  final Widget leading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: _tileBorderRadiusFor(position),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: leading,
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _FrequencyTile extends StatelessWidget {
  const _FrequencyTile({
    required this.summary,
    required this.enabled,
    required this.onTap,
  });

  final String summary;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_reset_rounded),
      title: Text('appSettings.fingerprint.recheckFrequency.title'.tr()),
      subtitle: Text(summary),
      trailing: const Icon(Icons.chevron_right_rounded),
      enabled: enabled,
      onTap: () {
        AppHaptics.primaryAction();
        onTap();
      },
    );
  }
}

class _ThemeSeedTile extends StatelessWidget {
  const _ThemeSeedTile({required this.themeSeed, required this.onSelected});

  final AppThemeSeed themeSeed;
  final ValueChanged<AppThemeSeed> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: _tileBorderRadiusFor(_SettingsTilePosition.last),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.color_lens_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'appSettings.themeSeed.title'.tr(),
                        style: context.tt.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'appSettings.themeSeed.subtitle'.tr(),
                        style: context.tt.bodySmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'appSettings.themeSeed.label'.tr(),
                    style: context.tt.labelLarge?.copyWith(
                      color: context.cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AppThemeSeed.values
                          .map(
                            (seed) => _ThemeSeedButton(
                              themeSeed: seed,
                              selected: seed == themeSeed,
                              onTap: () => onSelected(seed),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSeedButton extends StatelessWidget {
  const _ThemeSeedButton({
    required this.themeSeed,
    required this.selected,
    required this.onTap,
  });

  final AppThemeSeed themeSeed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final seedColor = _themeSeedColor(themeSeed);

    return Tooltip(
      message: _themeSeedLabel(themeSeed).tr(),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: seedColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? context.cs.onSurface
                  : context.cs.outlineVariant,
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.cs.shadow.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class _FrequencyOptionTile extends StatelessWidget {
  const _FrequencyOptionTile({
    required this.position,
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final _SettingsTilePosition position;
  final BiometricReauthInterval value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: _tileBorderRadiusFor(position),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<BiometricReauthInterval>(
        value: value,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        secondary: const Icon(Icons.schedule_rounded),
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

enum _SettingsTilePosition { single, first, middle, last }

BorderRadius _tileBorderRadiusFor(_SettingsTilePosition position) {
  switch (position) {
    case _SettingsTilePosition.single:
      return BorderRadius.circular(_tileOuterRadius);
    case _SettingsTilePosition.first:
      return const BorderRadius.only(
        topLeft: Radius.circular(_tileOuterRadius),
        topRight: Radius.circular(_tileOuterRadius),
        bottomLeft: Radius.circular(_tileInnerRadius),
        bottomRight: Radius.circular(_tileInnerRadius),
      );
    case _SettingsTilePosition.middle:
      return BorderRadius.circular(_tileInnerRadius);
    case _SettingsTilePosition.last:
      return const BorderRadius.only(
        topLeft: Radius.circular(_tileInnerRadius),
        topRight: Radius.circular(_tileInnerRadius),
        bottomLeft: Radius.circular(_tileOuterRadius),
        bottomRight: Radius.circular(_tileOuterRadius),
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

String _themeSeedLabel(AppThemeSeed themeSeed) {
  return switch (themeSeed) {
    AppThemeSeed.classicDeepPurple => 'appSettings.themeSeed.classicDeepPurple',
    AppThemeSeed.violet => 'appSettings.themeSeed.violet',
    AppThemeSeed.blue => 'appSettings.themeSeed.blue',
    AppThemeSeed.teal => 'appSettings.themeSeed.teal',
    AppThemeSeed.green => 'appSettings.themeSeed.green',
    AppThemeSeed.coral => 'appSettings.themeSeed.coral',
    AppThemeSeed.orange => 'appSettings.themeSeed.orange',
    AppThemeSeed.amber => 'appSettings.themeSeed.amber',
    AppThemeSeed.rose => 'appSettings.themeSeed.rose',
    AppThemeSeed.berry => 'appSettings.themeSeed.berry',
    AppThemeSeed.slate => 'appSettings.themeSeed.slate',
  };
}

Color _themeSeedColor(AppThemeSeed themeSeed) {
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

String _biometricIntervalLabel(BiometricReauthInterval interval) {
  return switch (interval) {
    BiometricReauthInterval.fifteenMinutes =>
      'appSettings.fingerprint.recheckFrequency.15m',
    BiometricReauthInterval.thirtyMinutes =>
      'appSettings.fingerprint.recheckFrequency.30m',
    BiometricReauthInterval.nextOpen =>
      'appSettings.fingerprint.recheckFrequency.nextOpen',
  };
}
