import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/app_haptics.dart';
import '../../core/utils/update_checker.dart';
import '../../core/utils/useful_extension.dart';
import '../../core/utils/utils_function.dart';

const _releaseOwner = 'andongni0723';
const _releaseRepo = 'trace';

Future<void> showUpdateVersionDialog(
  BuildContext context, {
  GitHubUpdateChecker? updateChecker,
  Future<String> Function()? appVersionLoader,
  bool showStatusFeedback = true,
}) async {
  final checker =
      updateChecker ??
      GitHubUpdateChecker(owner: _releaseOwner, repo: _releaseRepo);
  final loadAppVersion = appVersionLoader ?? getAppVersion;

  final currentVersion = await loadAppVersion();
  final latestRelease = await checker.fetchLatestRelease();

  if (!context.mounted) {
    return;
  }

  if (latestRelease == null) {
    if (showStatusFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('appSettings.checkUpdate.fetchError'.tr())),
      );
    }
    return;
  }

  if (!checker.isUpdateAvailable(
    currentVersion: currentVersion,
    latestVersion: latestRelease.tag,
  )) {
    if (showStatusFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('appSettings.checkUpdate.upToDate'.tr())),
      );
    }
    return;
  }

  final releaseUrl = Uri.parse(
    'https://github.com/$_releaseOwner/$_releaseRepo/releases/latest',
  );
  final downloadUrl = latestRelease.asset?.downloadUrl == null
      ? null
      : Uri.tryParse(latestRelease.asset!.downloadUrl!);

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.cs.surface,
    builder: (sheetContext) {
      final notes = latestRelease.notes.trim();

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'appSettings.checkUpdate.availableTitle'.tr(
                  namedArgs: {'version': latestRelease.tag},
                ),
                style: sheetContext.tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'appSettings.checkUpdate.currentVersion'.tr(
                  namedArgs: {'version': currentVersion},
                ),
                style: sheetContext.tt.bodyMedium?.copyWith(
                  color: sheetContext.cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'appSettings.checkUpdate.releaseNotes'.tr(),
                style: sheetContext.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sheetContext.cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    notes.isEmpty
                        ? 'appSettings.checkUpdate.noReleaseNotes'.tr()
                        : notes,
                    style: sheetContext.tt.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (latestRelease.asset != null && downloadUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UpdateActionButton(
                    title: 'appSettings.checkUpdate.downloadTitle'.tr(),
                    subtitle:
                        '${latestRelease.asset!.name} • ${bytesToMiB(latestRelease.asset!.sizeBytes).toStringAsFixed(2)} MB',
                    icon: Icons.download_rounded,
                    onPressed: () =>
                        _openExternalUrl(sheetContext, downloadUrl),
                  ),
                ),
              _UpdateActionButton(
                title: 'appSettings.checkUpdate.releasePageTitle'.tr(),
                subtitle: latestRelease.tag,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openExternalUrl(sheetContext, releaseUrl),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
  final isSuccess = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!isSuccess && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('appSettings.checkUpdate.openLinkError'.tr())),
    );
  }
}

class _UpdateActionButton extends StatelessWidget {
  const _UpdateActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: () {
        AppHaptics.primaryAction();
        onPressed();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon),
        title: Text(
          title,
          style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
