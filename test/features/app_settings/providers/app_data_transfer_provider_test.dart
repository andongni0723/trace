import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/app_settings/biometric_lock/data/auth/biometric_auth_client.dart';
import 'package:trace/features/app_settings/biometric_lock/data/models/biometric_lock_settings.dart';
import 'package:trace/features/app_settings/biometric_lock/domain/biometric_lock_service.dart';
import 'package:trace/features/app_settings/biometric_lock/providers/biometric_lock_provider.dart';
import 'package:trace/features/app_settings/data/models/app_settings.dart';
import 'package:trace/features/app_settings/providers/app_data_transfer_provider.dart';
import 'package:trace/features/app_settings/providers/app_settings_provider.dart';
import 'package:trace/features/media_library/data/models/media_asset_kind.dart';
import 'package:trace/features/media_library/providers/media_library_providers.dart';
import 'package:trace/features/people/data/models/personal_database_media_value.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';

import '../../people/test_person_avatar_storage.dart';
import '../../media_library/test_media_asset_storage.dart';

class _FakeBiometricAuthClient implements BiometricAuthClient {
  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool persistAcrossBackgrounding = true,
  }) async {
    return true;
  }

  @override
  Future<bool> canAuthenticate() async {
    return true;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return const [BiometricType.fingerprint];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('AppDataTransferService', () {
    test('buildBackupPayload includes personal database records', () async {
      SharedPreferences.setMockInitialValues({});
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final avatarStorage = TestPersonAvatarStorage();
      addTearDown(avatarStorage.clearManagedAvatars);

      final sourceAvatarFile = File(
        '${Directory.systemTemp.path}/trace_avatar_source_owner.png',
      );
      await sourceAvatarFile.writeAsBytes([1, 2, 3, 4], flush: true);
      addTearDown(sourceAvatarFile.delete);

      final storedAvatarPath = await avatarStorage.persistAvatar(
        personId: 'owner',
        sourcePath: sourceAvatarFile.path,
      );

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
        avatarPath: storedAvatarPath,
      );
      await database.personNotesDao.upsertNote(
        personId: 'owner',
        content: 'Coffee preference',
      );
      await database.personalDatabaseDao.createField(
        id: 'field-1',
        actorPersonId: 'owner',
        key: 'nickname',
        type: PersonalDatabaseValueType.string,
        isPublic: false,
        jsonValue: '"Cap"',
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          personAvatarStorageProvider.overrideWithValue(avatarStorage),
        ],
      );
      addTearDown(container.dispose);

      final payload = await container
          .read(appDataTransferProvider)
          .buildBackupPayload();

      expect(payload['personalDatabaseFields'], isA<List<dynamic>>());
      expect(payload['personalDatabasePersonFields'], isA<List<dynamic>>());
      expect(payload['personalDatabaseValues'], isA<List<dynamic>>());
      expect(payload['personNotes'], isA<List<dynamic>>());
      expect((payload['personalDatabaseFields'] as List<dynamic>).length, 1);
      expect(
        (payload['personalDatabasePersonFields'] as List<dynamic>).length,
        1,
      );
      expect((payload['personalDatabaseValues'] as List<dynamic>).length, 1);
      expect((payload['personNotes'] as List<dynamic>).length, 1);
      expect(payload['personAvatars'], hasLength(1));
      expect(payload['personAvatars'], containsPair('owner', isA<String>()));
    });

    test('buildBackupPayload includes media library records', () async {
      SharedPreferences.setMockInitialValues({});

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final mediaAssetStorage = TestMediaAssetStorage();
      addTearDown(mediaAssetStorage.clearManagedMediaFiles);

      final sourceMediaFile = File(
        '${Directory.systemTemp.path}/trace_media_backup_clip.mp4',
      );
      await sourceMediaFile.writeAsBytes([11, 22, 33, 44], flush: true);
      addTearDown(sourceMediaFile.delete);

      final storedMediaPath = await mediaAssetStorage.persistMediaFile(
        mediaAssetId: 'media-1',
        sourcePath: sourceMediaFile.path,
      );

      await database.mediaAssetsDao.insertMediaAsset(
        id: 'media-1',
        displayName: 'clip',
        originalFileName: 'clip.mp4',
        kind: MediaAssetKind.video,
        sizeBytes: 4,
        filePath: storedMediaPath!,
        mimeType: 'video/mp4',
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          mediaAssetStorageProvider.overrideWithValue(mediaAssetStorage),
        ],
      );
      addTearDown(container.dispose);

      final payload = await container
          .read(appDataTransferProvider)
          .buildBackupPayload();

      expect(payload['mediaAssets'], isA<List<dynamic>>());
      expect(payload['mediaFiles'], isA<Map<String, dynamic>>());
      expect((payload['mediaAssets'] as List<dynamic>), hasLength(1));
      expect(payload['mediaFiles'], containsPair('media-1', isA<String>()));
    });

    test(
      'buildBackupPayload excludes missing media files and media references',
      () async {
        SharedPreferences.setMockInitialValues({});

        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final avatarStorage = TestPersonAvatarStorage();
        addTearDown(avatarStorage.clearManagedAvatars);
        final mediaAssetStorage = TestMediaAssetStorage();
        addTearDown(mediaAssetStorage.clearManagedMediaFiles);
        final missingMediaFile = File(
          '${Directory.systemTemp.path}/trace_missing_media_export.png',
        );
        if (await missingMediaFile.exists()) {
          await missingMediaFile.delete();
        }

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );
        await database.mediaAssetsDao.insertMediaAsset(
          id: 'missing-media',
          displayName: 'missing',
          originalFileName: 'missing.png',
          kind: MediaAssetKind.image,
          sizeBytes: 4,
          filePath: missingMediaFile.path,
          mimeType: 'image/png',
        );
        await database.personalDatabaseDao.createField(
          id: 'field-media',
          actorPersonId: 'owner',
          key: 'photo',
          type: PersonalDatabaseValueType.media,
          isPublic: false,
          jsonValue: jsonEncode(
            const PersonalDatabaseMediaValue(
              mediaAssetId: 'missing-media',
              fileName: 'missing.png',
              kind: 'image',
            ).toJson(),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            personAvatarStorageProvider.overrideWithValue(avatarStorage),
            mediaAssetStorageProvider.overrideWithValue(mediaAssetStorage),
          ],
        );
        addTearDown(container.dispose);

        final payload = await container
            .read(appDataTransferProvider)
            .buildBackupPayload();

        expect(payload['mediaAssets'], isEmpty);
        expect(payload['mediaFiles'], isEmpty);
        expect(payload['personalDatabaseValues'], isEmpty);
      },
    );

    test('importPayload restores personal database records', () async {
      SharedPreferences.setMockInitialValues({});

      final sourceDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(sourceDatabase.close);
      final sourceAvatarStorage = TestPersonAvatarStorage();
      addTearDown(sourceAvatarStorage.clearManagedAvatars);

      final sourceAvatarFile = File(
        '${Directory.systemTemp.path}/trace_avatar_source_import.png',
      );
      await sourceAvatarFile.writeAsBytes([9, 8, 7, 6], flush: true);
      addTearDown(sourceAvatarFile.delete);

      final storedAvatarPath = await sourceAvatarStorage.persistAvatar(
        personId: 'owner',
        sourcePath: sourceAvatarFile.path,
      );

      await sourceDatabase.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
        avatarPath: storedAvatarPath,
      );
      await sourceDatabase.personNotesDao.upsertNote(
        personId: 'owner',
        content: 'Favorite cafe: Echo',
      );
      await sourceDatabase.personalDatabaseDao.createField(
        id: 'field-1',
        actorPersonId: 'owner',
        key: 'profile',
        type: PersonalDatabaseValueType.object,
        isPublic: false,
        jsonValue: '{"nickname":"Cap"}',
      );

      final sourceContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(sourceDatabase),
          personAvatarStorageProvider.overrideWithValue(sourceAvatarStorage),
        ],
      );
      addTearDown(sourceContainer.dispose);

      final payload = await sourceContainer
          .read(appDataTransferProvider)
          .buildBackupPayload();

      final targetDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDatabase.close);
      final targetAvatarStorage = TestPersonAvatarStorage();
      addTearDown(targetAvatarStorage.clearManagedAvatars);
      final targetContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(targetDatabase),
          personAvatarStorageProvider.overrideWithValue(targetAvatarStorage),
        ],
      );
      addTearDown(targetContainer.dispose);

      await targetContainer
          .read(appDataTransferProvider)
          .importPayload(
            jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
          );

      final restoredFields = await targetDatabase.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;
      final restoredLibrary = await targetDatabase.personalDatabaseDao
          .watchFieldLibrary()
          .first;
      final restoredAssignedIds = await targetDatabase.personalDatabaseDao
          .watchAssignedFieldIdsForPerson('owner')
          .first;

      expect(restoredFields, hasLength(1));
      expect(restoredLibrary, hasLength(1));
      expect(restoredAssignedIds, {restoredFields.single.id});
      expect(restoredFields.single.key, 'profile');
      expect(restoredFields.single.value, {'nickname': 'Cap'});
      final restoredNote = await targetDatabase.personNotesDao.getNoteForPerson(
        'owner',
      );
      expect(restoredNote, isNotNull);
      expect(restoredNote!.content, 'Favorite cafe: Echo');

      final restoredPerson = await targetDatabase.peopleDao.getPersonById(
        'owner',
      );
      expect(restoredPerson, isNotNull);
      expect(restoredPerson!.avatarPath, isNotNull);
      expect(await File(restoredPerson.avatarPath!).readAsBytes(), [
        9,
        8,
        7,
        6,
      ]);
    });

    test('importPayload restores media library records', () async {
      SharedPreferences.setMockInitialValues({});

      final sourceDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(sourceDatabase.close);
      final sourceMediaStorage = TestMediaAssetStorage();
      addTearDown(sourceMediaStorage.clearManagedMediaFiles);

      final sourceMediaFile = File(
        '${Directory.systemTemp.path}/trace_media_backup_import_clip.png',
      );
      await sourceMediaFile.writeAsBytes([7, 7, 8, 8], flush: true);
      addTearDown(sourceMediaFile.delete);

      final storedMediaPath = await sourceMediaStorage.persistMediaFile(
        mediaAssetId: 'media-restore',
        sourcePath: sourceMediaFile.path,
      );

      await sourceDatabase.mediaAssetsDao.insertMediaAsset(
        id: 'media-restore',
        displayName: 'photo',
        originalFileName: 'photo.png',
        kind: MediaAssetKind.image,
        sizeBytes: 4,
        filePath: storedMediaPath!,
        mimeType: 'image/png',
      );

      final sourceContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(sourceDatabase),
          mediaAssetStorageProvider.overrideWithValue(sourceMediaStorage),
        ],
      );
      addTearDown(sourceContainer.dispose);

      final payload = await sourceContainer
          .read(appDataTransferProvider)
          .buildBackupPayload();

      final targetDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(targetDatabase.close);
      final targetMediaStorage = TestMediaAssetStorage();
      addTearDown(targetMediaStorage.clearManagedMediaFiles);
      final targetContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(targetDatabase),
          mediaAssetStorageProvider.overrideWithValue(targetMediaStorage),
        ],
      );
      addTearDown(targetContainer.dispose);

      await targetContainer
          .read(appDataTransferProvider)
          .importPayload(
            jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
          );

      final restoredMedia = await targetDatabase.mediaAssetsDao
          .getMediaAssetById('media-restore');
      expect(restoredMedia, isNotNull);
      expect(restoredMedia!.displayName, 'photo');
      expect(restoredMedia.kind, MediaAssetKind.image);
      expect(await File(restoredMedia.filePath).readAsBytes(), [7, 7, 8, 8]);
    });

    test(
      'importPayload drops media values when backup file bytes are missing',
      () async {
        SharedPreferences.setMockInitialValues({});

        final targetDatabase = AppDatabase(NativeDatabase.memory());
        addTearDown(targetDatabase.close);
        final targetAvatarStorage = TestPersonAvatarStorage();
        addTearDown(targetAvatarStorage.clearManagedAvatars);
        final targetMediaStorage = TestMediaAssetStorage();
        addTearDown(targetMediaStorage.clearManagedMediaFiles);
        final now = DateTime(2026, 3, 30);
        final missingPath =
            '${Directory.systemTemp.path}/trace_missing_media_import.png';

        final payload = <String, dynamic>{
          'appId': 'trace',
          'backupType': 'app_backup',
          'version': 6,
          'exportedAt': now.toIso8601String(),
          'settings': {'themeMode': 'system'},
          'people': [
            PeopleData(
              id: 'owner',
              name: 'Owner',
              colorValue: 0xFF111111,
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          ],
          'personAvatars': const <String, String>{},
          'mediaAssets': [
            MediaAsset(
              id: 'missing-media',
              displayName: 'missing',
              originalFileName: 'missing.png',
              kind: MediaAssetKind.image,
              mimeType: 'image/png',
              sizeBytes: 4,
              filePath: missingPath,
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          ],
          'mediaFiles': const <String, String>{},
          'todos': const [],
          'todoParticipants': const [],
          'personalDatabaseFields': [
            PersonalDatabaseField(
              id: 'field-media',
              key: 'photo',
              valueType: PersonalDatabaseValueType.media.dbKey,
              isPublic: false,
              ownerPersonId: 'owner',
              sortOrder: 0,
              createdAt: now,
              updatedAt: now,
            ).toJson(),
          ],
          'personalDatabasePersonFields': const [],
          'personalDatabaseValues': [
            PersonalDatabaseValue(
              fieldId: 'field-media',
              personId: 'owner',
              jsonValue: jsonEncode(
                const PersonalDatabaseMediaValue(
                  mediaAssetId: 'missing-media',
                  fileName: 'missing.png',
                  kind: 'image',
                ).toJson(),
              ),
              updatedAt: now,
            ).toJson(),
          ],
        };

        final targetContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(targetDatabase),
            personAvatarStorageProvider.overrideWithValue(targetAvatarStorage),
            mediaAssetStorageProvider.overrideWithValue(targetMediaStorage),
          ],
        );
        addTearDown(targetContainer.dispose);

        await targetContainer
            .read(appDataTransferProvider)
            .importPayload(payload);

        final restoredMediaAssets = await targetDatabase
            .select(targetDatabase.mediaAssets)
            .get();
        final restoredValues = await targetDatabase
            .select(targetDatabase.personalDatabaseValues)
            .get();
        final restoredAssignedFields = await targetDatabase
            .select(targetDatabase.personalDatabasePersonFields)
            .get();

        expect(restoredMediaAssets, isEmpty);
        expect(restoredValues, isEmpty);
        expect(restoredAssignedFields, hasLength(1));
      },
    );

    test(
      'importPayload keeps existing managed avatars when import fails',
      () async {
        SharedPreferences.setMockInitialValues({});

        final sourceDatabase = AppDatabase(NativeDatabase.memory());
        addTearDown(sourceDatabase.close);
        final sourceAvatarStorage = TestPersonAvatarStorage();
        addTearDown(sourceAvatarStorage.clearManagedAvatars);

        final sourceAvatarFile = File(
          '${Directory.systemTemp.path}/trace_avatar_source_invalid_import.png',
        );
        await sourceAvatarFile.writeAsBytes([4, 5, 6, 7], flush: true);
        addTearDown(sourceAvatarFile.delete);

        final sourceStoredAvatarPath = await sourceAvatarStorage.persistAvatar(
          personId: 'source-owner',
          sourcePath: sourceAvatarFile.path,
        );

        await sourceDatabase.peopleDao.createPerson(
          id: 'source-owner',
          name: 'Source Owner',
          colorValue: 0xFF111111,
          avatarPath: sourceStoredAvatarPath,
        );

        final sourceContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(sourceDatabase),
            personAvatarStorageProvider.overrideWithValue(sourceAvatarStorage),
          ],
        );
        addTearDown(sourceContainer.dispose);

        final payload = Map<String, dynamic>.from(
          await sourceContainer
              .read(appDataTransferProvider)
              .buildBackupPayload(),
        );
        payload['personalDatabaseValues'] = [
          {
            'fieldId': 'missing-field',
            'personId': 'source-owner',
            'jsonValue': '"broken"',
            'updatedAt': DateTime(2026, 3, 30).toIso8601String(),
          },
        ];

        final targetDatabase = AppDatabase(NativeDatabase.memory());
        addTearDown(targetDatabase.close);
        final targetAvatarStorage = TestPersonAvatarStorage();
        addTearDown(targetAvatarStorage.clearManagedAvatars);

        final existingAvatarFile = File(
          '${Directory.systemTemp.path}/trace_avatar_existing_before_failed_import.png',
        );
        await existingAvatarFile.writeAsBytes([1, 2, 3], flush: true);
        addTearDown(existingAvatarFile.delete);

        final existingManagedAvatarPath = await targetAvatarStorage
            .persistAvatar(
              personId: 'existing-owner',
              sourcePath: existingAvatarFile.path,
            );

        await targetDatabase.peopleDao.createPerson(
          id: 'existing-owner',
          name: 'Existing Owner',
          colorValue: 0xFF222222,
          avatarPath: existingManagedAvatarPath,
        );

        final targetContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(targetDatabase),
            personAvatarStorageProvider.overrideWithValue(targetAvatarStorage),
          ],
        );
        addTearDown(targetContainer.dispose);

        await expectLater(
          () => targetContainer
              .read(appDataTransferProvider)
              .importPayload(payload),
          throwsA(isA<Object>()),
        );

        expect(await File(existingManagedAvatarPath!).exists(), isTrue);
        final restoredExistingPerson = await targetDatabase.peopleDao
            .getPersonById('existing-owner');
        expect(restoredExistingPerson, isNotNull);
        expect(restoredExistingPerson!.avatarPath, existingManagedAvatarPath);
      },
    );

    test('importPayload refreshes biometric lock state after import', () async {
      SharedPreferences.setMockInitialValues({});

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final avatarStorage = TestPersonAvatarStorage();
      addTearDown(avatarStorage.clearManagedAvatars);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          personAvatarStorageProvider.overrideWithValue(avatarStorage),
          biometricAuthClientProvider.overrideWithValue(
            _FakeBiometricAuthClient(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initialBiometricState = await container.read(
        biometricLockStateProvider.future,
      );
      expect(initialBiometricState.settings.enabled, isFalse);

      final payload = <String, dynamic>{
        'appId': 'trace',
        'backupType': 'app_backup',
        'version': 4,
        'exportedAt': DateTime(2026, 3, 30).toIso8601String(),
        'settings': {
          'themeMode': 'dark',
          'themeSeed': 'teal',
          'openingAnimationEnabled': false,
          'initialPropertyDisplayMode': 'expanded',
          'biometricLock': {
            'enabled': true,
            'reauthInterval': BiometricReauthInterval.nextOpen.preferenceValue,
          },
        },
        'people': const [],
        'personAvatars': const <String, String>{},
        'todos': const [],
        'todoParticipants': const [],
        'personalDatabaseFields': const [],
        'personalDatabaseValues': const [],
      };

      await container.read(appDataTransferProvider).importPayload(payload);

      final refreshedState = await container.read(
        biometricLockStateProvider.future,
      );
      final importedSettings = await container.read(appSettingsProvider.future);
      expect(importedSettings.themeMode, AppThemeMode.dark);
      expect(importedSettings.themeSeed, AppThemeSeed.teal);
      expect(importedSettings.openingAnimationEnabled, isFalse);
      expect(
        importedSettings.initialPropertyDisplayMode,
        AppInitialPropertyDisplayMode.expanded,
      );
      expect(refreshedState.settings.enabled, isTrue);
      expect(
        refreshedState.settings.reauthInterval,
        BiometricReauthInterval.nextOpen,
      );
    });
  });
}
