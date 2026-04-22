import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../data/models/media_asset_kind.dart';
import '../../data/services/media_asset_picker.dart';
import '../../providers/media_library_providers.dart';
import '../models/media_library_view_data.dart';
import '../widgets/media_library_card.dart';

class MediaLibraryPage extends ConsumerStatefulWidget {
  const MediaLibraryPage({super.key});

  @override
  ConsumerState<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends ConsumerState<MediaLibraryPage> {
  static const _gridPadding = EdgeInsets.fromLTRB(16, 0, 16, 24);
  static const _gridSpacing = 12.0;
  static const _fabAnimationDuration = Duration(milliseconds: 250);

  final _fabKey = GlobalKey<ExpandableFabState>();
  String _searchQuery = '';
  bool _isImportingMedia = false;

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(mediaLibraryAssetsProvider);

    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('mediaLibrary.title'.tr()),
      ),
      floatingActionButton: ExpandableFab(
        key: _fabKey,
        duration: _fabAnimationDuration,
        type: ExpandableFabType.up,
        distance: 76,
        overlayStyle: ExpandableFabOverlayStyle(
          color: context.cs.scrim.withValues(alpha: 0.12),
        ),
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          heroTag: 'media-library-add-fab-open',
          child: const Icon(Icons.upload_rounded),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: context.cs.onPrimaryContainer,
          backgroundColor: context.cs.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          heroTag: 'media-library-add-fab-close',
          child: const Icon(Icons.close_rounded),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: context.cs.onSurface,
          backgroundColor: context.cs.surfaceContainerHigh,
          shape: const CircleBorder(),
        ),
        children: [
          _ExpandableFabAction(
            label: 'mediaLibrary.uploadSheet.audioTitle'.tr(),
            icon: Icons.audio_file_outlined,
            onPressed: () => _importMedia(MediaAssetPickerMode.audio),
          ),
          _ExpandableFabAction(
            label: 'mediaLibrary.uploadSheet.videoTitle'.tr(),
            icon: Icons.video_library_outlined,
            onPressed: () => _importMedia(MediaAssetPickerMode.video),
          ),
          _ExpandableFabAction(
            label: 'mediaLibrary.uploadSheet.imageTitle'.tr(),
            icon: Icons.photo_library_outlined,
            onPressed: () => _importMedia(MediaAssetPickerMode.image),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              elevation: const WidgetStatePropertyAll<double>(0),
              hintText: 'mediaLibrary.searchHint'.tr(),
              leading: const Icon(Icons.search_rounded),
              onChanged: _handleSearchChanged,
            ),
          ),
          Expanded(
            child: assetsAsync.when(
              data: (assets) => _buildGrid(context, assets),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'mediaLibrary.loadError'.tr(),
                    textAlign: TextAlign.center,
                    style: context.tt.bodyLarge?.copyWith(
                      color: context.cs.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaAsset> assets) {
    if (assets.isEmpty) {
      return _MediaLibraryEmptyState(query: _searchQuery);
    }

    return GridView.builder(
      padding: _gridPadding,
      itemCount: assets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: _gridSpacing,
        crossAxisSpacing: _gridSpacing,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) {
        final asset = assets[index];
        final item = _mapAssetToViewData(asset);
        return MediaLibraryCard(
          item: item,
          onTap: () => _openMedia(asset),
          onRenameTap: () => _showRenameDialog(item),
        );
      },
    );
  }

  Future<void> _openMedia(MediaAsset asset) async {
    final filePath = asset.filePath.trim();
    if (filePath.isEmpty) {
      _showOpenMediaError();
      return;
    }

    AppHaptics.primaryAction();
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showOpenMediaError();
        return;
      }

      final didOpen = await ref
          .read(mediaAssetOpenerProvider)
          .openMediaFile(filePath: file.path, mimeType: asset.mimeType);
      if (!didOpen) {
        _showOpenMediaError();
      }
    } catch (_) {
      _showOpenMediaError();
    }
  }

  Future<void> _importMedia(MediaAssetPickerMode pickerMode) async {
    if (_isImportingMedia) {
      return;
    }

    _fabKey.currentState?.close();
    setState(() {
      _isImportingMedia = true;
    });

    try {
      await Future<void>.delayed(_fabAnimationDuration);
      await ref
          .read(mediaLibraryActionsProvider)
          .importMediaFiles(mode: pickerMode);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('mediaLibrary.uploadError'.tr())),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingMedia = false;
        });
      }
    }
  }

  Future<void> _showRenameDialog(MediaLibraryItemViewData item) async {
    var draftName = item.name;
    final renamedValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('mediaLibrary.renameDialog.title'.tr()),
          content: TextFormField(
            initialValue: item.name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'mediaLibrary.renameDialog.fieldLabel'.tr(),
            ),
            onChanged: (value) {
              draftName = value;
            },
            onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(draftName),
              child: Text('mediaLibrary.renameDialog.confirm'.tr()),
            ),
          ],
        );
      },
    );

    if (!mounted || renamedValue == null) {
      return;
    }

    await ref
        .read(mediaLibraryActionsProvider)
        .renameMediaAsset(assetId: item.id, displayName: renamedValue);
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    ref.read(mediaLibraryActionsProvider).setSearchQuery(value);
  }

  void _showOpenMediaError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('mediaLibrary.openError'.tr())));
  }

  MediaLibraryItemViewData _mapAssetToViewData(MediaAsset asset) {
    return MediaLibraryItemViewData(
      id: asset.id,
      kind: asset.kind,
      name: asset.displayName,
      sizeLabel: _formatFileSize(asset.sizeBytes),
      previewPath: asset.kind == MediaAssetKind.audio ? null : asset.filePath,
    );
  }
}

class _ExpandableFabAction extends StatelessWidget {
  const _ExpandableFabAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Material(
          color: context.cs.surfaceContainerHigh,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: context.tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        FloatingActionButton.small(
          heroTag: null,
          tooltip: label,
          onPressed: () async {
            AppHaptics.selection();
            await onPressed();
          },
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _MediaLibraryEmptyState extends StatelessWidget {
  const _MediaLibraryEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(Icons.perm_media_outlined, size: 36),
              ),
            ),
            Text(
              hasQuery
                  ? 'mediaLibrary.emptySearchTitle'.tr()
                  : 'mediaLibrary.emptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              hasQuery
                  ? 'mediaLibrary.emptySearchBody'.tr()
                  : 'mediaLibrary.emptyBody'.tr(),
              textAlign: TextAlign.center,
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFileSize(int sizeBytes) {
  if (sizeBytes < 1024) {
    return '$sizeBytes B';
  }
  final sizeInKilobytes = sizeBytes / 1024;
  if (sizeInKilobytes < 1024) {
    return '${sizeInKilobytes.toStringAsFixed(sizeInKilobytes >= 100 ? 0 : 1)} KB';
  }
  final sizeInMegabytes = sizeInKilobytes / 1024;
  if (sizeInMegabytes < 1024) {
    return '${sizeInMegabytes.toStringAsFixed(sizeInMegabytes >= 100 ? 0 : 1)} MB';
  }
  final sizeInGigabytes = sizeInMegabytes / 1024;
  return '${sizeInGigabytes.toStringAsFixed(sizeInGigabytes >= 100 ? 0 : 1)} GB';
}
