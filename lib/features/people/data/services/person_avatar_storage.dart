import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PersonAvatarStorage {
  static const _avatarDirectoryName = 'person_avatars';

  Future<String?> persistAvatar({
    required String personId,
    String? sourcePath,
  }) async {
    final normalizedSourcePath = _normalizePath(sourcePath);
    if (normalizedSourcePath == null) {
      return null;
    }

    if (await isManagedAvatarPath(normalizedSourcePath)) {
      return normalizedSourcePath;
    }

    final sourceFile = File(normalizedSourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final avatarDirectory = await _avatarDirectory();
    final extension = p.extension(normalizedSourcePath);
    final sanitizedExtension = extension.isEmpty ? '.img' : extension;
    final targetPath = p.join(
      avatarDirectory.path,
      '${personId}_${DateTime.now().microsecondsSinceEpoch}$sanitizedExtension',
    );

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<String?> restoreAvatar({
    required String personId,
    required String base64Bytes,
    String? originalPath,
  }) async {
    final bytes = base64Decode(base64Bytes);
    final avatarDirectory = await _avatarDirectory();
    final extension = p.extension(originalPath ?? '');
    final sanitizedExtension = extension.isEmpty ? '.img' : extension;
    final targetPath = p.join(
      avatarDirectory.path,
      '${personId}_${DateTime.now().microsecondsSinceEpoch}$sanitizedExtension',
    );

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  Future<Map<String, String>> buildBackupPayload(
    Iterable<({String personId, String? avatarPath})> people,
  ) async {
    final payload = <String, String>{};

    for (final person in people) {
      final normalizedPath = _normalizePath(person.avatarPath);
      if (normalizedPath == null) {
        continue;
      }

      final avatarFile = File(normalizedPath);
      if (!await avatarFile.exists()) {
        continue;
      }

      payload[person.personId] = base64Encode(await avatarFile.readAsBytes());
    }

    return payload;
  }

  Future<void> deleteManagedAvatar(String? avatarPath) async {
    final normalizedPath = _normalizePath(avatarPath);
    if (normalizedPath == null || !await isManagedAvatarPath(normalizedPath)) {
      return;
    }

    final avatarFile = File(normalizedPath);
    if (await avatarFile.exists()) {
      await avatarFile.delete();
    }
  }

  Future<void> clearManagedAvatars() async {
    final avatarDirectory = await _avatarDirectory();
    if (await avatarDirectory.exists()) {
      await avatarDirectory.delete(recursive: true);
    }
  }

  Future<bool> isManagedAvatarPath(String avatarPath) async {
    final avatarDirectory = await _avatarDirectory();
    final normalizedAvatarPath = p.normalize(avatarPath);
    final normalizedDirectoryPath = p.normalize(avatarDirectory.path);
    return p.isWithin(normalizedDirectoryPath, normalizedAvatarPath) ||
        normalizedAvatarPath == normalizedDirectoryPath;
  }

  Future<Directory> _avatarDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final avatarDirectory = Directory(
      p.join(documentsDirectory.path, _avatarDirectoryName),
    );
    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }
    return avatarDirectory;
  }

  String? _normalizePath(String? avatarPath) {
    final trimmedPath = avatarPath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }
    return p.normalize(trimmedPath);
  }
}
