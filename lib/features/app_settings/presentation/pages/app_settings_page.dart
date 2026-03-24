import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:people_todolist/app.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';
import 'package:people_todolist/shared/dialogs/update_version_dialog.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text('appSettings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _SectionLabel(label: 'appSettings.section.appearance'.tr()),
          _SettingsTile(
            position: _SettingsTilePosition.single,
            title: 'appSettings.themeMode.title'.tr(),
            subtitle: _themeModeLabel(appSettings.themeMode).tr(),
            leading: const Icon(Icons.palette_outlined),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemeDialog(context, ref, appSettings.themeMode),
          ),
          _SectionLabel(label: 'appSettings.section.app'.tr()),
          _SettingsTile(
            position: _SettingsTilePosition.single,
            title: 'appSettings.checkUpdate.title'.tr(),
            subtitle: 'appSettings.checkUpdate.subtitle'.tr(),
            leading: const Icon(Icons.system_update_alt_rounded),
            onTap: () => showUpdateVersionDialog(context),
          ),
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

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref.read(appDataTransferProvider).exportData();
      if (!context.mounted || !success) {
        return;
      }

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
        onTap: onTap,
      ),
    );
  }
}

enum _SettingsTilePosition { single, first, last }

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
