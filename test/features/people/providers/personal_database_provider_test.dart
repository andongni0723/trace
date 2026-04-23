import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/personal_database_media_value.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/personal_database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('PersonalDatabaseActions', () {
    test('exposes global library and per-person assignment actions', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.peopleDao.createPerson(
        id: 'friend-a',
        name: 'Friend A',
        colorValue: 0xFF222222,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await container
          .read(personalDatabaseActionsProvider)
          .createPropertyAndAssignToPerson(
            personId: 'owner',
            key: 'status',
            type: PersonalDatabaseValueType.string,
            value: 'Active',
          );

      final createdFieldId =
          (await database.personalDatabaseDao.watchFieldLibrary().first)
              .single
              .id;

      await container
          .read(personalDatabaseActionsProvider)
          .assignFieldToPerson(personId: 'friend-a', fieldId: createdFieldId);

      final library = await database.personalDatabaseDao
          .watchFieldLibrary()
          .first;
      final ownerAssignedIds = await database.personalDatabaseDao
          .watchAssignedFieldIdsForPerson('owner')
          .first;
      final friendAssignedIds = await database.personalDatabaseDao
          .watchAssignedFieldIdsForPerson('friend-a')
          .first;
      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;
      final friendFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('friend-a')
          .first;

      expect(library, hasLength(1));
      expect(library.single.key, 'status');
      expect(ownerAssignedIds, {library.single.id});
      expect(friendAssignedIds, {library.single.id});
      expect(ownerFields.single.value, 'Active');
      expect(friendFields.single.value, '');
    });

    test('creates media property values through provider actions', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      const mediaValue = PersonalDatabaseMediaValue(
        mediaAssetId: 'asset-1',
        fileName: 'voice-note.m4a',
        kind: 'audio',
      );

      await container
          .read(personalDatabaseActionsProvider)
          .createPropertyAndAssignToPerson(
            personId: 'owner',
            key: 'voice note',
            type: PersonalDatabaseValueType.media,
            value: mediaValue,
          );

      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;

      expect(ownerFields.single.type, PersonalDatabaseValueType.media);
      expect(ownerFields.single.value, mediaValue);
    });

    test('renameObjectKey rejects duplicate sibling keys', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.personalDatabaseDao.createField(
        id: 'field-1',
        actorPersonId: 'owner',
        key: 'profile',
        type: PersonalDatabaseValueType.object,
        isPublic: false,
        jsonValue: '{"nickname":"Cap","title":"Lead"}',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final field =
          (await database.personalDatabaseDao
                  .watchFieldTreeForPerson('owner')
                  .first)
              .single;

      await expectLater(
        () => container
            .read(personalDatabaseActionsProvider)
            .renameObjectKey(
              personId: 'owner',
              field: field,
              path: const ['nickname'],
              newKey: 'title',
            ),
        throwsA(isA<StateError>()),
      );

      final reloadedField =
          (await database.personalDatabaseDao
                  .watchFieldTreeForPerson('owner')
                  .first)
              .single;
      expect(reloadedField.value, {'nickname': 'Cap', 'title': 'Lead'});
    });

    test('addChildNode rejects duplicate object keys', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.personalDatabaseDao.createField(
        id: 'field-1',
        actorPersonId: 'owner',
        key: 'profile',
        type: PersonalDatabaseValueType.object,
        isPublic: false,
        jsonValue: '{"nickname":"Cap"}',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final field =
          (await database.personalDatabaseDao
                  .watchFieldTreeForPerson('owner')
                  .first)
              .single;

      await expectLater(
        () => container
            .read(personalDatabaseActionsProvider)
            .addChildNode(
              personId: 'owner',
              field: field,
              parentPath: const [],
              key: 'nickname',
              value: 'Captain',
            ),
        throwsA(isA<StateError>()),
      );

      final reloadedField =
          (await database.personalDatabaseDao
                  .watchFieldTreeForPerson('owner')
                  .first)
              .single;
      expect(reloadedField.value, {'nickname': 'Cap'});
    });

    test(
      'createChildPropertyForPerson rejects duplicate assigned child keys',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );
        await database.personalDatabaseDao.createField(
          id: 'field-profile',
          actorPersonId: 'owner',
          key: 'profile',
          type: PersonalDatabaseValueType.object,
          isPublic: true,
          jsonValue: '{}',
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        final profile =
            (await database.personalDatabaseDao
                    .watchFieldTreeForPerson('owner')
                    .first)
                .single;

        await container
            .read(personalDatabaseActionsProvider)
            .createChildPropertyForPerson(
              personId: 'owner',
              parentField: profile,
              key: 'nickname',
              type: PersonalDatabaseValueType.string,
              value: 'Cap',
            );

        final reloadedProfile = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');

        await expectLater(
          () => container
              .read(personalDatabaseActionsProvider)
              .createChildPropertyForPerson(
                personId: 'owner',
                parentField: reloadedProfile.single,
                key: 'nickname',
                type: PersonalDatabaseValueType.string,
                value: 'Captain',
              ),
          throwsA(isA<StateError>()),
        );

        final ownerFields = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');
        expect(ownerFields.single.children.single.key, 'nickname');
        expect(ownerFields.single.children.single.value, 'Cap');
      },
    );

    test('addArrayElementFromTemplate appends cloned saved template', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-pets',
        personId: 'owner',
        key: 'pets',
        type: PersonalDatabaseValueType.list,
        jsonValue: '[]',
        arrayElementType: PersonalDatabaseValueType.object,
        arrayElementTemplateJsonValue:
            '{"name":"Cap","children":[],"__traceArrayElementTemplates":{"children":{"elementType":"object","template":{"name":""}}}}',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      var field = (await database.personalDatabaseDao.getFieldTreeForPerson(
        'owner',
      )).single;
      await container
          .read(personalDatabaseActionsProvider)
          .addArrayElementFromTemplate(personId: 'owner', field: field);

      await container
          .read(personalDatabaseActionsProvider)
          .updateArrayElementTemplate(
            fieldId: 'field-pets',
            template: {'name': 'New', 'age': 0},
          );

      field = (await database.personalDatabaseDao.getFieldTreeForPerson(
        'owner',
      )).single;
      await container
          .read(personalDatabaseActionsProvider)
          .addArrayElementFromTemplate(personId: 'owner', field: field);

      final ownerFields = await database.personalDatabaseDao
          .getFieldTreeForPerson('owner');
      expect(ownerFields.single.value, [
        {'name': 'Cap', 'children': []},
        {'name': 'New', 'age': 0},
      ]);
    });

    test(
      'ensureObjectSubtreeDefinitions backfills legacy object keys',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );

        await database.personalDatabaseDao.createField(
          id: 'field-profile',
          actorPersonId: 'owner',
          key: 'profile',
          type: PersonalDatabaseValueType.object,
          isPublic: true,
          jsonValue: '{"nickname":"Cap","details":{"age":30}}',
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        await container
            .read(personalDatabaseActionsProvider)
            .ensureObjectSubtreeDefinitions(personId: 'owner');

        final library = await database.personalDatabaseDao
            .watchFieldLibrary()
            .first;
        final ownerFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('owner')
            .first;

        expect(library, hasLength(1));
        expect(ownerFields, hasLength(1));

        final libraryProfile = library.single;
        final ownerProfile = ownerFields.single;

        expect(libraryProfile.children.map((child) => child.key), [
          'nickname',
          'details',
        ]);
        expect(
          libraryProfile.children
              .firstWhere((child) => child.key == 'details')
              .children
              .single
              .key,
          'age',
        );
        expect(ownerProfile.children.map((child) => child.key), [
          'nickname',
          'details',
        ]);
        expect(
          ownerProfile.children
              .firstWhere((child) => child.key == 'nickname')
              .value,
          'Cap',
        );
        expect(
          ownerProfile.children
              .firstWhere((child) => child.key == 'details')
              .children
              .single
              .value,
          30,
        );
      },
    );

    test(
      'removeChildPropertyFromPerson hides subtree but keeps definitions',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );
        await database.personalDatabaseDao.createField(
          id: 'field-profile',
          actorPersonId: 'owner',
          key: 'profile',
          type: PersonalDatabaseValueType.object,
          isPublic: true,
          jsonValue: '{}',
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        final profile =
            (await database.personalDatabaseDao
                    .watchFieldTreeForPerson('owner')
                    .first)
                .single;

        final childId = await container
            .read(personalDatabaseActionsProvider)
            .createChildPropertyForPerson(
              personId: 'owner',
              parentField: profile,
              key: 'nickname',
              type: PersonalDatabaseValueType.string,
              value: 'Cap',
            );

        expect(childId, isNotNull);

        await container
            .read(personalDatabaseActionsProvider)
            .removeChildPropertyFromPerson(
              personId: 'owner',
              fieldId: childId!,
            );

        final library = await database.personalDatabaseDao
            .watchFieldLibrary()
            .first;
        final ownerFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('owner')
            .first;

        expect(library.single.children.single.key, 'nickname');
        expect(ownerFields.single.children, isEmpty);
      },
    );

    test(
      'nested child scope follows parent visibility in chooser library',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );
        await database.peopleDao.createPerson(
          id: 'friend-a',
          name: 'Friend A',
          colorValue: 0xFF222222,
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        await database.personalDatabaseDao.createField(
          id: 'field-public',
          actorPersonId: 'owner',
          key: 'publicProfile',
          type: PersonalDatabaseValueType.object,
          isPublic: true,
          jsonValue: '{}',
        );
        await database.personalDatabaseDao.createField(
          id: 'field-private',
          actorPersonId: 'owner',
          key: 'privateProfile',
          type: PersonalDatabaseValueType.object,
          isPublic: false,
          jsonValue: '{}',
        );

        final ownerFields = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');

        final publicParent = ownerFields.firstWhere(
          (field) => field.id == 'field-public',
        );
        final privateParent = ownerFields.firstWhere(
          (field) => field.id == 'field-private',
        );

        await container
            .read(personalDatabaseActionsProvider)
            .createChildPropertyForPerson(
              personId: 'owner',
              parentField: publicParent,
              key: 'nickname',
              type: PersonalDatabaseValueType.string,
              value: 'Cap',
            );
        await container
            .read(personalDatabaseActionsProvider)
            .createChildPropertyForPerson(
              personId: 'owner',
              parentField: privateParent,
              key: 'secret',
              type: PersonalDatabaseValueType.string,
              value: 'Only owner',
            );

        final ownerLibrary = await database.personalDatabaseDao
            .getFieldLibraryForPerson('owner');
        final friendLibrary = await database.personalDatabaseDao
            .getFieldLibraryForPerson('friend-a');

        expect(
          ownerLibrary.map((field) => field.key),
          containsAll(['publicProfile', 'privateProfile']),
        );
        expect(
          ownerLibrary
              .firstWhere((field) => field.key == 'privateProfile')
              .children
              .single
              .key,
          'secret',
        );
        expect(
          friendLibrary.map((field) => field.key),
          contains('publicProfile'),
        );
        expect(
          friendLibrary.map((field) => field.key),
          isNot(contains('privateProfile')),
        );
        expect(
          friendLibrary
              .singleWhere((field) => field.key == 'publicProfile')
              .children
              .single
              .key,
          'nickname',
        );
      },
    );

    test(
      'ensureObjectSubtreeDefinitions does not restore hidden child assignments',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );

        await database.personalDatabaseDao.createField(
          id: 'field-profile',
          actorPersonId: 'owner',
          key: 'profile',
          type: PersonalDatabaseValueType.object,
          isPublic: true,
          jsonValue: '{"nickname":"Cap"}',
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        await container
            .read(personalDatabaseActionsProvider)
            .ensureObjectSubtreeDefinitions(personId: 'owner');

        final ownerFieldsAfterBackfill = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');
        final childId = ownerFieldsAfterBackfill.single.children.single.id;

        await container
            .read(personalDatabaseActionsProvider)
            .removeChildPropertyFromPerson(personId: 'owner', fieldId: childId);

        await container
            .read(personalDatabaseActionsProvider)
            .ensureObjectSubtreeDefinitions(personId: 'owner');

        final ownerFields = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');

        expect(ownerFields.single.children, isEmpty);
        expect(ownerFields.single.value, const <String, Object?>{});
      },
    );
  });
}
