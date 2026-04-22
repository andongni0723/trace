import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../people/providers/people_database_providers.dart';
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
  }) {
    return _ref
        .read(mediaLibraryServiceProvider)
        .importPickedMediaFiles(mode: mode);
  }

  Future<void> renameMediaAsset({
    required String assetId,
    required String displayName,
  }) {
    return _ref
        .read(mediaLibraryServiceProvider)
        .renameMediaAsset(assetId: assetId, displayName: displayName);
  }

  Future<void> deleteMediaAsset(String assetId) {
    return _ref.read(mediaLibraryServiceProvider).deleteMediaAsset(assetId);
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
