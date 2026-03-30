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
import 'package:trace/features/app_settings/providers/app_data_transfer_provider.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';

import '../../people/test_person_avatar_storage.dart';

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
      expect(payload['personalDatabaseValues'], isA<List<dynamic>>());
      expect((payload['personalDatabaseFields'] as List<dynamic>).length, 1);
      expect((payload['personalDatabaseValues'] as List<dynamic>).length, 1);
      expect(payload['personAvatars'], hasLength(1));
      expect(payload['personAvatars'], containsPair('owner', isA<String>()));
    });

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

      expect(restoredFields, hasLength(1));
      expect(restoredFields.single.key, 'profile');
      expect(restoredFields.single.value, {'nickname': 'Cap'});

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
      expect(refreshedState.settings.enabled, isTrue);
      expect(
        refreshedState.settings.reauthInterval,
        BiometricReauthInterval.nextOpen,
      );
    });
  });
}
