import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:trace/features/people/data/services/person_avatar_storage.dart';

class TestPersonAvatarStorage extends PersonAvatarStorage {
  TestPersonAvatarStorage({Directory? root})
    : _root =
          root ??
          Directory(
            p.join(
              Directory.systemTemp.path,
              'trace_person_avatar_${DateTime.now().microsecondsSinceEpoch}',
            ),
          );

  final Directory _root;

  Future<Directory> _avatarDirectory() async {
    final avatarDirectory = Directory(p.join(_root.path, 'person_avatars'));
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<void> clearManagedAvatars() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }

  @override
  Future<bool> isManagedAvatarPath(String avatarPath) async {
    final avatarDirectory = await _avatarDirectory();
    final normalizedAvatarPath = p.normalize(avatarPath);
    final normalizedDirectoryPath = p.normalize(avatarDirectory.path);
    return p.isWithin(normalizedDirectoryPath, normalizedAvatarPath) ||
        normalizedAvatarPath == normalizedDirectoryPath;
  }
}
