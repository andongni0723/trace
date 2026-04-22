import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database.dart';
import '../../media_library/providers/media_library_providers.dart';
import '../../people/data/models/personal_database_value_type.dart';
import '../../people/providers/people_database_providers.dart';
import '../biometric_lock/data/models/biometric_lock_settings.dart';
import '../biometric_lock/data/repositories/biometric_lock_settings_repository.dart';
import '../biometric_lock/providers/biometric_lock_provider.dart';
import '../data/models/app_settings.dart';
import 'app_settings_provider.dart';

final appDataTransferProvider = Provider<AppDataTransferService>((ref) {
  return AppDataTransferService(ref);
});

const _backupAppId = 'trace';
const _legacyBackupAppIds = {'people_todolist'};
const _backupType = 'app_backup';
const _backupVersion = 6;
const _supportedBackupVersions = {1, 2, 3, 4, 5, 6};

class AppDataTransferService {
  AppDataTransferService(this._ref);

  final Ref _ref;

  Future<bool> exportData() async {
    final payload = await buildBackupPayload();

    final fileName =
        'trace_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      return savedPath != null;
    } catch (_) {
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(tempFile.path)], title: 'trace backup'),
      );

      return true;
    }
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    final rawJson =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    await importPayload(rawJson);

    return true;
  }

  Future<Map<String, Object?>> buildBackupPayload() async {
    final database = _ref.read(appDatabaseProvider);
    final appSettings = await _readCurrentSettings();
    final biometricSettings = await _readCurrentBiometricSettings();

    final people = await database.select(database.people).get();
    final todos = await database.select(database.todos).get();
    final participants = await database.select(database.todoParticipants).get();
    final personalDatabaseFields = await database
        .select(database.personalDatabaseFields)
        .get();
    final personalDatabasePersonFields = await database
        .select(database.personalDatabasePersonFields)
        .get();
    final personalDatabaseValues = await database
        .select(database.personalDatabaseValues)
        .get();
    final mediaAssets = await database.select(database.mediaAssets).get();
    final personAvatars = await _ref
        .read(personAvatarStorageProvider)
        .buildBackupPayload(
          people.map(
            (person) => (personId: person.id, avatarPath: person.avatarPath),
          ),
        );
    final mediaFiles = await _ref
        .read(mediaAssetStorageProvider)
        .buildBackupPayload(
          mediaAssets.map(
            (asset) => (mediaAssetId: asset.id, filePath: asset.filePath),
          ),
        );
    final exportableMediaAssetIds = mediaFiles.keys.toSet();
    final exportableMediaAssets = mediaAssets
        .where((asset) => exportableMediaAssetIds.contains(asset.id))
        .toList(growable: false);
    final exportablePersonalDatabaseValues = _withoutUnavailableMediaReferences(
      personalDatabaseValues: personalDatabaseValues,
      personalDatabaseFields: personalDatabaseFields,
      availableMediaAssetIds: exportableMediaAssetIds,
    );

    return <String, Object?>{
      'appId': _backupAppId,
      'backupType': _backupType,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'themeMode': appSettings.themeMode.name,
        'biometricLock': {
          'enabled': biometricSettings.enabled,
          'reauthInterval': biometricSettings.reauthInterval.preferenceValue,
        },
      },
      'people': people.map((person) => person.toJson()).toList(growable: false),
      'personAvatars': personAvatars,
      'mediaAssets': exportableMediaAssets
          .map((asset) => asset.toJson())
          .toList(growable: false),
      'mediaFiles': mediaFiles,
      'todos': todos.map((todo) => todo.toJson()).toList(growable: false),
      'todoParticipants': participants
          .map((participant) => participant.toJson())
          .toList(growable: false),
      'personalDatabaseFields': personalDatabaseFields
          .map((field) => field.toJson())
          .toList(growable: false),
      'personalDatabasePersonFields': personalDatabasePersonFields
          .map((item) => item.toJson())
          .toList(growable: false),
      'personalDatabaseValues': exportablePersonalDatabaseValues
          .map((value) => value.toJson())
          .toList(growable: false),
    };
  }

  Future<void> importPayload(Map<String, dynamic> rawJson) async {
    _validateBackupPayload(rawJson);

    final peopleJson = (rawJson['people'] as List<dynamic>? ?? const []);
    final todosJson = (rawJson['todos'] as List<dynamic>? ?? const []);
    final participantsJson =
        (rawJson['todoParticipants'] as List<dynamic>? ?? const []);
    final personalDatabaseFieldsJson =
        (rawJson['personalDatabaseFields'] as List<dynamic>? ?? const []);
    final personalDatabasePersonFieldsJson =
        (rawJson['personalDatabasePersonFields'] as List<dynamic>? ?? const []);
    final personalDatabaseValuesJson =
        (rawJson['personalDatabaseValues'] as List<dynamic>? ?? const []);
    final mediaAssetsJson =
        (rawJson['mediaAssets'] as List<dynamic>? ?? const []);
    final mediaFilesJson = rawJson['mediaFiles'] as Map<String, dynamic>?;
    final personAvatarsJson = rawJson['personAvatars'] as Map<String, dynamic>?;
    final settingsJson = rawJson['settings'] as Map<String, dynamic>?;
    final biometricSettingsJson =
        settingsJson?['biometricLock'] as Map<String, dynamic>?;
    final database = _ref.read(appDatabaseProvider);
    final previousPeople = await database.select(database.people).get();
    final previousManagedAvatarPaths = previousPeople
        .map((person) => person.avatarPath)
        .whereType<String>()
        .toSet();
    final previousMediaAssets = await database
        .select(database.mediaAssets)
        .get();
    final previousManagedMediaPaths = previousMediaAssets
        .map((asset) => asset.filePath)
        .whereType<String>()
        .toSet();

    final importedPeople = peopleJson
        .map(
          (item) => PeopleData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final people = <PeopleData>[];
    final restoredAvatarPaths = <String>{};
    try {
      final restoredPeople = await _restorePeopleWithManagedAvatars(
        importedPeople,
        personAvatarsJson,
      );
      people.addAll(restoredPeople);
      restoredAvatarPaths.addAll(
        restoredPeople.map((person) => person.avatarPath).whereType<String>(),
      );
    } catch (_) {
      await _cleanupAvatarPaths(restoredAvatarPaths);
      rethrow;
    }
    final todos = todosJson
        .map((item) => Todo.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    final participants = participantsJson
        .map(
          (item) =>
              TodoParticipant.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final personalDatabaseFields = personalDatabaseFieldsJson
        .map(
          (item) => PersonalDatabaseField.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    final importedPersonalDatabaseValues = personalDatabaseValuesJson
        .map(
          (item) => PersonalDatabaseValue.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    final importedMediaAssets = mediaAssetsJson
        .map(
          (item) => MediaAsset.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final personalDatabasePersonFields =
        personalDatabasePersonFieldsJson.isEmpty
        ? importedPersonalDatabaseValues
              .map(
                (value) => PersonalDatabasePersonField(
                  fieldId: value.fieldId,
                  personId: value.personId,
                  sortOrder: 0,
                  createdAt: value.updatedAt,
                ),
              )
              .toList(growable: false)
        : personalDatabasePersonFieldsJson
              .map(
                (item) => PersonalDatabasePersonField.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false);
    final mediaAssets = <MediaAsset>[];
    final restoredMediaPaths = <String>{};
    try {
      final restoredMediaAssets = await _restoreMediaAssetsWithManagedFiles(
        importedMediaAssets,
        mediaFilesJson,
      );
      mediaAssets.addAll(restoredMediaAssets);
      restoredMediaPaths.addAll(
        restoredMediaAssets.map((asset) => asset.filePath).whereType<String>(),
      );
    } catch (_) {
      await _cleanupMediaPaths(restoredMediaPaths);
      rethrow;
    }
    final availableMediaAssetIds = mediaAssets.map((asset) => asset.id).toSet();
    final personalDatabaseValues = _withoutUnavailableMediaReferences(
      personalDatabaseValues: importedPersonalDatabaseValues,
      personalDatabaseFields: personalDatabaseFields,
      availableMediaAssetIds: availableMediaAssetIds,
    );

    try {
      await database.transaction(() async {
        await database.delete(database.personalDatabaseValues).go();
        await database.delete(database.personalDatabasePersonFields).go();
        await database.delete(database.personalDatabaseFields).go();
        await database.delete(database.mediaAssets).go();
        await database.delete(database.todoParticipants).go();
        await database.delete(database.todos).go();
        await database.delete(database.people).go();

        await database.batch((batch) {
          if (people.isNotEmpty) {
            batch.insertAll(database.people, people);
          }
          if (todos.isNotEmpty) {
            batch.insertAll(database.todos, todos);
          }
          if (participants.isNotEmpty) {
            batch.insertAll(database.todoParticipants, participants);
          }
          if (personalDatabaseFields.isNotEmpty) {
            batch.insertAll(
              database.personalDatabaseFields,
              personalDatabaseFields,
            );
          }
          if (personalDatabasePersonFields.isNotEmpty) {
            batch.insertAll(
              database.personalDatabasePersonFields,
              personalDatabasePersonFields,
            );
          }
          if (personalDatabaseValues.isNotEmpty) {
            batch.insertAll(
              database.personalDatabaseValues,
              personalDatabaseValues,
            );
          }
          if (mediaAssets.isNotEmpty) {
            batch.insertAll(database.mediaAssets, mediaAssets);
          }
        });
      });
    } catch (_) {
      await _cleanupAvatarPaths(restoredAvatarPaths);
      await _cleanupMediaPaths(restoredMediaPaths);
      rethrow;
    }

    final importedThemeMode = AppThemeModePreferenceX.fromPreference(
      settingsJson?['themeMode'] as String?,
    );
    await _ref.read(appSettingsActionsProvider).setThemeMode(importedThemeMode);
    await _ref
        .read(biometricLockSettingsRepositoryProvider)
        .save(
          BiometricLockSettings(
            enabled: biometricSettingsJson?['enabled'] as bool? ?? false,
            reauthInterval: BiometricReauthIntervalX.fromPreference(
              biometricSettingsJson?['reauthInterval'] as String?,
            ),
          ),
        );
    _ref.invalidate(biometricLockStateProvider);

    final avatarPathsToDelete = previousManagedAvatarPaths.difference(
      restoredAvatarPaths,
    );
    await _cleanupAvatarPaths(avatarPathsToDelete);
    final mediaPathsToDelete = previousManagedMediaPaths.difference(
      restoredMediaPaths,
    );
    await _cleanupMediaPaths(mediaPathsToDelete);
  }

  Future<AppSettings> _readCurrentSettings() async {
    try {
      return await _ref.read(appSettingsProvider.future);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<BiometricLockSettings> _readCurrentBiometricSettings() async {
    try {
      return _ref.read(biometricLockSettingsRepositoryProvider).load();
    } catch (_) {
      return const BiometricLockSettings();
    }
  }

  void _validateBackupPayload(Map<String, dynamic> rawJson) {
    final appId = rawJson['appId'];
    final backupType = rawJson['backupType'];
    final version = rawJson['version'];

    final hasRequiredStructure =
        rawJson['settings'] is Map<String, dynamic> &&
        rawJson['people'] is List<dynamic> &&
        (rawJson['personAvatars'] == null ||
            rawJson['personAvatars'] is Map<String, dynamic>) &&
        (rawJson['mediaAssets'] == null ||
            rawJson['mediaAssets'] is List<dynamic>) &&
        (rawJson['mediaFiles'] == null ||
            rawJson['mediaFiles'] is Map<String, dynamic>) &&
        rawJson['todos'] is List<dynamic> &&
        rawJson['todoParticipants'] is List<dynamic> &&
        (rawJson['personalDatabaseFields'] == null ||
            rawJson['personalDatabaseFields'] is List<dynamic>) &&
        (rawJson['personalDatabasePersonFields'] == null ||
            rawJson['personalDatabasePersonFields'] is List<dynamic>) &&
        (rawJson['personalDatabaseValues'] == null ||
            rawJson['personalDatabaseValues'] is List<dynamic>);

    final isKnownAppId =
        appId == _backupAppId || _legacyBackupAppIds.contains(appId);

    if (!isKnownAppId ||
        backupType != _backupType ||
        !_supportedBackupVersions.contains(version) ||
        !hasRequiredStructure) {
      throw const FormatException('Invalid trace backup format.');
    }
  }

  Future<List<PeopleData>> _restorePeopleWithManagedAvatars(
    List<PeopleData> people,
    Map<String, dynamic>? personAvatarsJson,
  ) async {
    final avatarStorage = _ref.read(personAvatarStorageProvider);

    return Future.wait(
      people.map((person) async {
        final encodedAvatar = personAvatarsJson?[person.id];
        if (encodedAvatar is! String || encodedAvatar.isEmpty) {
          return person.copyWith(avatarPath: Value(null));
        }

        final restoredAvatarPath = await avatarStorage.restoreAvatar(
          personId: person.id,
          base64Bytes: encodedAvatar,
          originalPath: person.avatarPath,
        );

        return person.copyWith(avatarPath: Value(restoredAvatarPath));
      }),
    );
  }

  Future<List<MediaAsset>> _restoreMediaAssetsWithManagedFiles(
    List<MediaAsset> mediaAssets,
    Map<String, dynamic>? mediaFilesJson,
  ) async {
    final mediaStorage = _ref.read(mediaAssetStorageProvider);

    final restoredMediaAssets = await Future.wait(
      mediaAssets.map((asset) async {
        final encodedMediaFile = mediaFilesJson?[asset.id];
        if (encodedMediaFile is! String || encodedMediaFile.isEmpty) {
          return null;
        }

        final restoredMediaPath = await mediaStorage.restoreMediaFile(
          mediaAssetId: asset.id,
          base64Bytes: encodedMediaFile,
          originalPath: asset.filePath,
          originalFileName: asset.originalFileName,
        );

        return asset.copyWith(filePath: restoredMediaPath);
      }),
    );

    return restoredMediaAssets.whereType<MediaAsset>().toList(growable: false);
  }

  List<PersonalDatabaseValue> _withoutUnavailableMediaReferences({
    required List<PersonalDatabaseValue> personalDatabaseValues,
    required List<PersonalDatabaseField> personalDatabaseFields,
    required Set<String> availableMediaAssetIds,
  }) {
    final mediaFieldIds = personalDatabaseFields
        .where(
          (field) =>
              personalDatabaseValueTypeFromDb(field.valueType) ==
              PersonalDatabaseValueType.media,
        )
        .map((field) => field.id)
        .toSet();

    if (mediaFieldIds.isEmpty) {
      return personalDatabaseValues;
    }

    return personalDatabaseValues
        .where((value) {
          if (!mediaFieldIds.contains(value.fieldId)) {
            return true;
          }

          final mediaAssetId = _mediaAssetIdFromJsonValue(value.jsonValue);
          if (mediaAssetId == null || mediaAssetId.isEmpty) {
            return true;
          }

          return availableMediaAssetIds.contains(mediaAssetId);
        })
        .toList(growable: false);
  }

  String? _mediaAssetIdFromJsonValue(String jsonValue) {
    try {
      final decoded = jsonDecode(jsonValue);
      if (decoded is! Map) {
        return null;
      }

      final mediaAssetId = decoded['mediaAssetId'];
      if (mediaAssetId is! String) {
        return null;
      }

      return mediaAssetId.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cleanupAvatarPaths(Iterable<String> avatarPaths) async {
    final avatarStorage = _ref.read(personAvatarStorageProvider);
    for (final avatarPath in avatarPaths) {
      await avatarStorage.deleteManagedAvatar(avatarPath);
    }
  }

  Future<void> _cleanupMediaPaths(Iterable<String> mediaPaths) async {
    final mediaStorage = _ref.read(mediaAssetStorageProvider);
    for (final mediaPath in mediaPaths) {
      await mediaStorage.deleteManagedMediaFile(mediaPath);
    }
  }
}
