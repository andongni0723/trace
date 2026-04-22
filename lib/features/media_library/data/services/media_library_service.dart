import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart';
import '../daos/media_assets_dao.dart';
import '../models/media_asset_kind.dart';
import '../models/media_import_candidate.dart';
import 'media_asset_picker.dart';
import 'media_asset_storage.dart';

class MediaLibraryService {
  MediaLibraryService({
    required MediaAssetsDao mediaAssetsDao,
    required MediaAssetStorage mediaAssetStorage,
    required MediaAssetPicker mediaAssetPicker,
    required Uuid uuid,
  }) : _mediaAssetsDao = mediaAssetsDao,
       _mediaAssetStorage = mediaAssetStorage,
       _mediaAssetPicker = mediaAssetPicker,
       _uuid = uuid;

  final MediaAssetsDao _mediaAssetsDao;
  final MediaAssetStorage _mediaAssetStorage;
  final MediaAssetPicker _mediaAssetPicker;
  final Uuid _uuid;

  Future<List<MediaAsset>> importPickedMediaFiles({
    required MediaAssetPickerMode mode,
  }) async {
    final candidates = await _mediaAssetPicker.pickMediaFiles(mode: mode);
    if (candidates.isEmpty) {
      return const [];
    }

    final createdAssets = <MediaAsset>[];
    final createdAssetIds = <String>[];
    final copiedPaths = <String>[];

    try {
      for (final candidate in candidates) {
        final createdAsset = await _importCandidate(candidate);
        if (createdAsset == null) {
          continue;
        }

        createdAssets.add(createdAsset);
        createdAssetIds.add(createdAsset.id);
        copiedPaths.add(createdAsset.filePath);
      }
    } catch (_) {
      for (final assetId in createdAssetIds) {
        await _mediaAssetsDao.deleteMediaAssetById(assetId);
      }
      await _cleanupPaths(copiedPaths);
      rethrow;
    }

    return createdAssets;
  }

  Future<MediaAsset?> createMediaAssetFromPath({
    required String sourcePath,
    required String fileName,
    required int sizeBytes,
    required MediaAssetKind kind,
    String? mimeType,
  }) async {
    final candidate = MediaImportCandidate(
      sourcePath: sourcePath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      kind: kind,
      mimeType: mimeType,
    );
    return _importCandidate(candidate);
  }

  Future<void> renameMediaAsset({
    required String assetId,
    required String displayName,
  }) {
    return _mediaAssetsDao.renameMediaAsset(
      id: assetId,
      displayName: displayName,
    );
  }

  Future<void> deleteMediaAsset(String assetId) async {
    final asset = await _mediaAssetsDao.getMediaAssetById(assetId);
    if (asset == null) {
      return;
    }

    await _mediaAssetStorage.deleteManagedMediaFile(asset.filePath);
    await _mediaAssetsDao.deleteMediaAssetById(assetId);
  }

  Future<MediaAsset?> _importCandidate(MediaImportCandidate candidate) async {
    final sourceFile = File(candidate.sourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final assetId = _uuid.v4();
    final managedPath = await _mediaAssetStorage.persistMediaFile(
      mediaAssetId: assetId,
      sourcePath: candidate.sourcePath,
    );
    if (managedPath == null) {
      return null;
    }

    try {
      final insertedRowId = await _mediaAssetsDao.insertMediaAsset(
        id: assetId,
        displayName: _defaultDisplayName(candidate.fileName),
        originalFileName: candidate.fileName,
        kind: candidate.kind,
        sizeBytes: candidate.sizeBytes,
        filePath: managedPath,
        mimeType: candidate.mimeType,
      );

      if (insertedRowId <= 0) {
        await _mediaAssetStorage.deleteManagedMediaFile(managedPath);
        return null;
      }

      return await _mediaAssetsDao.getMediaAssetById(assetId);
    } catch (_) {
      await _mediaAssetStorage.deleteManagedMediaFile(managedPath);
      rethrow;
    }
  }

  Future<void> _cleanupPaths(Iterable<String> paths) async {
    for (final path in paths) {
      await _mediaAssetStorage.deleteManagedMediaFile(path);
    }
  }

  String _defaultDisplayName(String fileName) {
    final trimmedFileName = fileName.trim();
    if (trimmedFileName.isEmpty) {
      return 'media_${DateTime.now().millisecondsSinceEpoch}';
    }
    return p.basename(trimmedFileName);
  }
}
