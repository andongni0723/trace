import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
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
  });
}
