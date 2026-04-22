import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:trace/features/media_library/data/services/media_asset_storage.dart';

class TestMediaAssetStorage extends MediaAssetStorage {
  TestMediaAssetStorage({Directory? root})
    : _root =
          root ??
          Directory(
            p.join(
              Directory.systemTemp.path,
              'trace_media_asset_${DateTime.now().microsecondsSinceEpoch}',
            ),
          );

  final Directory _root;

  Future<Directory> _mediaDirectory() async {
    final mediaDirectory = Directory(p.join(_root.path, 'media_assets'));
    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }
    return mediaDirectory;
  }

  String? _normalizePath(String? filePath) {
    final trimmedPath = filePath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }
    return p.normalize(trimmedPath);
  }

  @override
  Future<String?> persistMediaFile({
    required String mediaAssetId,
    String? sourcePath,
  }) async {
    final normalizedSourcePath = _normalizePath(sourcePath);
    if (normalizedSourcePath == null) {
      return null;
    }

    if (await isManagedMediaFilePath(normalizedSourcePath)) {
      return normalizedSourcePath;
    }

    final sourceFile = File(normalizedSourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final mediaDirectory = await _mediaDirectory();
    final extension = p.extension(normalizedSourcePath);
    final sanitizedExtension = extension.isEmpty ? '.bin' : extension;
    final targetPath = p.join(
      mediaDirectory.path,
      '${mediaAssetId}_${DateTime.now().microsecondsSinceEpoch}$sanitizedExtension',
    );

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  @override
  Future<String?> restoreMediaFile({
    required String mediaAssetId,
    required String base64Bytes,
    String? originalPath,
    String? originalFileName,
  }) async {
    final bytes = base64Decode(base64Bytes);
    final mediaDirectory = await _mediaDirectory();
    final extension = p.extension(originalPath ?? originalFileName ?? '');
    final sanitizedExtension = extension.isEmpty ? '.bin' : extension;
    final targetPath = p.join(
      mediaDirectory.path,
      '${mediaAssetId}_${DateTime.now().microsecondsSinceEpoch}$sanitizedExtension',
    );

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  @override
  Future<Map<String, String>> buildBackupPayload(
    Iterable<({String mediaAssetId, String? filePath})> mediaAssets,
  ) async {
    final payload = <String, String>{};

    for (final mediaAsset in mediaAssets) {
      final normalizedPath = _normalizePath(mediaAsset.filePath);
      if (normalizedPath == null) {
        continue;
      }

      final mediaFile = File(normalizedPath);
      if (!await mediaFile.exists()) {
        continue;
      }

      payload[mediaAsset.mediaAssetId] = base64Encode(
        await mediaFile.readAsBytes(),
      );
    }

    return payload;
  }

  @override
  Future<void> deleteManagedMediaFile(String? filePath) async {
    final normalizedPath = _normalizePath(filePath);
    if (normalizedPath == null ||
        !await isManagedMediaFilePath(normalizedPath)) {
      return;
    }

    final mediaFile = File(normalizedPath);
    if (await mediaFile.exists()) {
      await mediaFile.delete();
    }
  }

  @override
  Future<void> clearManagedMediaFiles() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }

  @override
  Future<bool> isManagedMediaFilePath(String filePath) async {
    final mediaDirectory = await _mediaDirectory();
    final normalizedFilePath = p.normalize(filePath);
    final normalizedDirectoryPath = p.normalize(mediaDirectory.path);
    return p.isWithin(normalizedDirectoryPath, normalizedFilePath) ||
        normalizedFilePath == normalizedDirectoryPath;
  }
}
