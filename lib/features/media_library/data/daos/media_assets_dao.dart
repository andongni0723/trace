import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/media_assets.dart';
import '../models/media_asset_kind.dart';

part 'media_assets_dao.g.dart';

@DriftAccessor(tables: [MediaAssets])
class MediaAssetsDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetsDaoMixin {
  MediaAssetsDao(super.db);

  Expression<bool> _matchesAssetId(String assetId) =>
      mediaAssets.id.equals(assetId);

  Expression<bool> _matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const Constant(true);
    }

    final pattern = '%$normalizedQuery%';
    return mediaAssets.displayName.like(pattern) |
        mediaAssets.originalFileName.like(pattern);
  }

  Selectable<MediaAsset> _orderedMediaAssetsQuery({
    String query = '',
    MediaAssetKind? kind,
  }) {
    return select(mediaAssets)
      ..where((table) {
        final matchesKind = kind == null
            ? const Constant(true)
            : table.kind.equals(kind.dbKey);
        return matchesKind & _matchesQuery(query);
      })
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.asc(table.displayName),
      ]);
  }

  Stream<List<MediaAsset>> watchMediaAssets({
    String query = '',
    MediaAssetKind? kind,
  }) {
    return _orderedMediaAssetsQuery(query: query, kind: kind).watch();
  }

  Future<List<MediaAsset>> getMediaAssets({
    String query = '',
    MediaAssetKind? kind,
  }) {
    return _orderedMediaAssetsQuery(query: query, kind: kind).get();
  }

  Stream<MediaAsset?> watchMediaAssetById(String assetId) {
    return (select(
      mediaAssets,
    )..where((table) => _matchesAssetId(assetId))).watchSingleOrNull();
  }

  Future<MediaAsset?> getMediaAssetById(String assetId) {
    return (select(
      mediaAssets,
    )..where((table) => _matchesAssetId(assetId))).getSingleOrNull();
  }

  Future<int> insertMediaAsset({
    required String id,
    required String displayName,
    required String originalFileName,
    required MediaAssetKind kind,
    required int sizeBytes,
    required String filePath,
    String? mimeType,
  }) {
    return into(mediaAssets).insert(
      MediaAssetsCompanion.insert(
        id: id,
        displayName: displayName,
        originalFileName: originalFileName,
        kind: kind,
        sizeBytes: sizeBytes,
        filePath: filePath,
        mimeType: Value(mimeType),
      ),
    );
  }

  Future<int> upsertMediaAsset({
    required String id,
    required String displayName,
    required String originalFileName,
    required MediaAssetKind kind,
    required int sizeBytes,
    required String filePath,
    String? mimeType,
  }) {
    return into(mediaAssets).insertOnConflictUpdate(
      MediaAssetsCompanion(
        id: Value(id),
        displayName: Value(displayName),
        originalFileName: Value(originalFileName),
        kind: Value(kind),
        sizeBytes: Value(sizeBytes),
        filePath: Value(filePath),
        mimeType: Value(mimeType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> renameMediaAsset({
    required String id,
    required String displayName,
  }) {
    final trimmedDisplayName = displayName.trim();
    if (trimmedDisplayName.isEmpty) {
      return Future.value(0);
    }

    return (update(mediaAssets)..where((table) => _matchesAssetId(id))).write(
      MediaAssetsCompanion(
        displayName: Value(trimmedDisplayName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateMediaAssetFile({
    required String id,
    required String filePath,
    required int sizeBytes,
    required String originalFileName,
    required MediaAssetKind kind,
    String? mimeType,
  }) {
    return (update(mediaAssets)..where((table) => _matchesAssetId(id))).write(
      MediaAssetsCompanion(
        originalFileName: Value(originalFileName),
        kind: Value(kind),
        sizeBytes: Value(sizeBytes),
        filePath: Value(filePath),
        mimeType: Value(mimeType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteMediaAssetById(String assetId) {
    return (delete(
      mediaAssets,
    )..where((table) => _matchesAssetId(assetId))).go();
  }
}
