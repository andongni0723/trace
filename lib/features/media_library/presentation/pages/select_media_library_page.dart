import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../people/data/models/personal_database_media_value.dart';
import '../../data/models/media_asset_kind.dart';
import '../../providers/media_library_providers.dart';
import '../models/media_library_view_data.dart';
import '../widgets/media_library_card.dart';

final _selectableMediaLibraryAssetsProvider =
    StreamProvider.autoDispose<List<MediaAsset>>((ref) {
      return ref.watch(mediaAssetsDaoProvider).watchMediaAssets();
    });

Future<PersonalDatabaseMediaValue?> showSelectMediaLibraryPage({
  required BuildContext context,
}) {
  return Navigator.of(context).push<PersonalDatabaseMediaValue>(
    MaterialPageRoute(builder: (_) => const SelectMediaLibraryPage()),
  );
}

class SelectMediaLibraryPage extends ConsumerWidget {
  const SelectMediaLibraryPage({super.key});

  static const _gridPadding = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const _gridSpacing = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(_selectableMediaLibraryAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('personTodo.database.sheet.mediaPickerTitle'.tr()),
      ),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const _EmptySelectableMediaState();
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
              return MediaLibraryCard(
                item: _mapAssetToViewData(asset),
                onTap: () {
                  AppHaptics.primaryAction();
                  Navigator.of(context).pop(
                    PersonalDatabaseMediaValue(
                      mediaAssetId: asset.id,
                      fileName: asset.displayName,
                      kind: asset.kind.dbKey,
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'mediaLibrary.loadError'.tr(),
              textAlign: TextAlign.center,
              style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
            ),
          ),
        ),
      ),
    );
  }

  static MediaLibraryItemViewData _mapAssetToViewData(MediaAsset asset) {
    return MediaLibraryItemViewData(
      id: asset.id,
      kind: asset.kind,
      name: asset.displayName,
      sizeLabel: _formatFileSize(asset.sizeBytes),
      previewPath: asset.kind == MediaAssetKind.audio ? null : asset.filePath,
    );
  }
}

class _EmptySelectableMediaState extends StatelessWidget {
  const _EmptySelectableMediaState();

  @override
  Widget build(BuildContext context) {
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
              'personTodo.database.sheet.mediaLibraryEmptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'personTodo.database.sheet.mediaLibraryEmptyBody'.tr(),
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
