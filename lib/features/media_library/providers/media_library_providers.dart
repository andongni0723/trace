import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../people/providers/people_database_providers.dart';
import '../../revision_log/data/models/revision_log_action.dart';
import '../../revision_log/providers/revision_log_provider.dart';
import '../data/daos/media_assets_dao.dart';
import '../data/models/media_asset_kind.dart';
import '../data/models/media_library_filter.dart';
import '../data/services/media_asset_opener.dart';
import '../data/services/media_asset_picker.dart';
import '../data/services/media_asset_storage.dart';
import '../data/services/media_library_service.dart';

final mediaAssetsDaoProvider = Provider<MediaAssetsDao>((ref) {
  return ref.watch(appDatabaseProvider).mediaAssetsDao;
});

final mediaAssetStorageProvider = Provider<MediaAssetStorage>((ref) {
  return MediaAssetStorage();
});

final mediaAssetPickerProvider = Provider<MediaAssetPicker>((ref) {
  return MediaAssetPicker();
});

final mediaAssetOpenerProvider = Provider<MediaAssetOpener>((ref) {
  return const MediaAssetOpener();
});

final mediaLibraryServiceProvider = Provider<MediaLibraryService>((ref) {
  return MediaLibraryService(
    mediaAssetsDao: ref.watch(mediaAssetsDaoProvider),
    mediaAssetStorage: ref.watch(mediaAssetStorageProvider),
    mediaAssetPicker: ref.watch(mediaAssetPickerProvider),
    uuid: const Uuid(),
  );
});

final mediaLibraryFilterProvider =
    NotifierProvider.autoDispose<
      MediaLibraryFilterNotifier,
      MediaLibraryFilter
    >(MediaLibraryFilterNotifier.new);

final mediaLibraryAssetsProvider = StreamProvider<List<MediaAsset>>((ref) {
  final filter = ref.watch(mediaLibraryFilterProvider);
  return ref
      .watch(mediaAssetsDaoProvider)
      .watchMediaAssets(query: filter.query, kind: filter.kind);
});

final mediaLibraryActionsProvider = Provider<MediaLibraryActions>((ref) {
  return MediaLibraryActions(ref);
});

class MediaLibraryFilterNotifier extends Notifier<MediaLibraryFilter> {
  @override
  MediaLibraryFilter build() => const MediaLibraryFilter();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setKind(MediaAssetKind? kind) {
    state = state.copyWith(kind: kind);
  }

  void clear() {
    state = const MediaLibraryFilter();
  }
}

class MediaLibraryActions {
  MediaLibraryActions(this._ref);

  final Ref _ref;

  Future<List<MediaAsset>> importMediaFiles({
    required MediaAssetPickerMode mode,
  }) async {
    final importedAssets = await _ref
        .read(mediaLibraryServiceProvider)
        .importPickedMediaFiles(mode: mode);
    for (final asset in importedAssets) {
      await _ref
          .read(revisionLogActionsProvider)
          .record(
            action: RevisionLogAction.create,
            entityType: 'mediaAsset',
            entityId: asset.id,
            entityLabel: asset.displayName,
            summary: 'Imported media asset ${asset.displayName}',
            changedFields: const [
              'displayName',
              'originalFileName',
              'kind',
              'mimeType',
              'sizeBytes',
              'filePath',
            ],
            after: asset.toJson(),
          );
    }
    return importedAssets;
  }

  Future<void> renameMediaAsset({
    required String assetId,
    required String displayName,
  }) async {
    final mediaAssetsDao = _ref.read(mediaAssetsDaoProvider);
    final before = await mediaAssetsDao.getMediaAssetById(assetId);
    await _ref
        .read(mediaLibraryServiceProvider)
        .renameMediaAsset(assetId: assetId, displayName: displayName);
    final after = await mediaAssetsDao.getMediaAssetById(assetId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.update,
          entityType: 'mediaAsset',
          entityId: assetId,
          entityLabel: after?.displayName ?? before?.displayName ?? assetId,
          summary:
              'Renamed media asset ${after?.displayName ?? before?.displayName ?? assetId}',
          changedFields: const ['displayName'],
          before: before?.toJson(),
          after: after?.toJson(),
        );
  }

  Future<void> deleteMediaAsset(String assetId) async {
    final before = await _ref
        .read(mediaAssetsDaoProvider)
        .getMediaAssetById(assetId);
    await _ref.read(mediaLibraryServiceProvider).deleteMediaAsset(assetId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.delete,
          entityType: 'mediaAsset',
          entityId: assetId,
          entityLabel: before?.displayName,
          summary: 'Deleted media asset ${before?.displayName ?? assetId}',
          changedFields: const ['mediaAsset'],
          before: before?.toJson(),
        );
  }

  void setSearchQuery(String query) {
    _ref.read(mediaLibraryFilterProvider.notifier).setQuery(query);
  }

  void setKindFilter(MediaAssetKind? kind) {
    _ref.read(mediaLibraryFilterProvider.notifier).setKind(kind);
  }

  void clearFilters() {
    _ref.read(mediaLibraryFilterProvider.notifier).clear();
  }
}
