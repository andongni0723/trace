import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaAssetStorage {
  static const _mediaDirectoryName = 'media_assets';

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

  Future<void> clearManagedMediaFiles() async {
    final mediaDirectory = await _mediaDirectory();
    if (await mediaDirectory.exists()) {
      await mediaDirectory.delete(recursive: true);
    }
  }

  Future<bool> isManagedMediaFilePath(String filePath) async {
    final mediaDirectory = await _mediaDirectory();
    final normalizedFilePath = p.normalize(filePath);
    final normalizedDirectoryPath = p.normalize(mediaDirectory.path);
    return p.isWithin(normalizedDirectoryPath, normalizedFilePath) ||
        normalizedFilePath == normalizedDirectoryPath;
  }

  Future<Directory> _mediaDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final mediaDirectory = Directory(
      p.join(documentsDirectory.path, _mediaDirectoryName),
    );
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
}
