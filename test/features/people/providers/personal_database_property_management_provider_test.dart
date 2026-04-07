import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/personal_database_management_error.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/personal_database_property_management_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalDatabasePropertyManagementActions', () {
    test('blocks deleting a property that is still assigned', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );

      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-profile',
        personId: 'owner',
        key: 'profile',
        type: PersonalDatabaseValueType.object,
        jsonValue: '{}',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      expect(
        await container
            .read(personalDatabasePropertyManagementActionsProvider)
            .canDeletePropertyDefinition('field-profile'),
        isFalse,
      );
    });

    test(
      'blocks retyping an object property that still has children',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );

        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-profile',
          personId: 'owner',
          key: 'profile',
          type: PersonalDatabaseValueType.object,
          jsonValue: '{}',
        );
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-name',
          personId: 'owner',
          key: 'nickname',
          type: PersonalDatabaseValueType.string,
          jsonValue: '"Cap"',
          parentFieldId: 'field-profile',
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        expect(
          await container
              .read(personalDatabasePropertyManagementActionsProvider)
              .canRetypePropertyDefinition(
                fieldId: 'field-profile',
                nextType: PersonalDatabaseValueType.string,
              ),
          isFalse,
        );
      },
    );

    test('moves a child property to the root level', () async {
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
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-name',
        personId: 'owner',
        key: 'nickname',
        type: PersonalDatabaseValueType.string,
        jsonValue: '"Cap"',
        parentFieldId: 'field-profile',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await container
          .read(personalDatabasePropertyManagementActionsProvider)
          .movePropertyDefinition(
            fieldId: 'field-name',
            newParentFieldId: null,
            newSortOrder: 0,
          );

      final library = await database.personalDatabaseDao.getFieldLibrary();
      final ownerFields = await database.personalDatabaseDao
          .getFieldTreeForPerson('owner');
      expect(library.map((field) => field.key), ['nickname', 'profile']);
      expect(library.first.parentFieldId, isNull);
      expect(library.last.children, isEmpty);
      expect(ownerFields.map((field) => field.key), ['nickname']);
    });

    test(
      'syncs root assignment order after reordering root properties',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
        );
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-a',
          personId: 'owner',
          key: 'first',
          type: PersonalDatabaseValueType.string,
          jsonValue: '"A"',
          sortOrder: 0,
          assignmentSortOrder: 0,
        );
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-b',
          personId: 'owner',
          key: 'second',
          type: PersonalDatabaseValueType.string,
          jsonValue: '"B"',
          sortOrder: 1,
          assignmentSortOrder: 1,
        );

        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        await container
            .read(personalDatabasePropertyManagementActionsProvider)
            .movePropertyDefinition(
              fieldId: 'field-b',
              newParentFieldId: null,
              newSortOrder: 0,
            );

        final ownerFields = await database.personalDatabaseDao
            .getFieldTreeForPerson('owner');
        expect(ownerFields.map((field) => field.key), ['second', 'first']);
      },
    );

    test('blocks moving a property into its own descendant', () async {
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
      await database.personalDatabaseDao.createField(
        id: 'field-meta',
        actorPersonId: 'owner',
        key: 'meta',
        type: PersonalDatabaseValueType.object,
        isPublic: true,
        jsonValue: '{}',
        parentFieldId: 'field-profile',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(personalDatabasePropertyManagementActionsProvider)
            .movePropertyDefinition(
              fieldId: 'field-profile',
              newParentFieldId: 'field-meta',
              newSortOrder: 0,
            ),
        throwsA(
          isA<PersonalDatabaseManagementException>().having(
            (error) => error.code,
            'code',
            PersonalDatabaseManagementErrorCode.moveTargetCannotBeDescendant,
          ),
        ),
      );
    });

    test('blocks moving across visibility scopes', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );

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

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(personalDatabasePropertyManagementActionsProvider)
            .movePropertyDefinition(
              fieldId: 'field-private',
              newParentFieldId: 'field-public',
              newSortOrder: 0,
            ),
        throwsA(
          isA<PersonalDatabaseManagementException>().having(
            (error) => error.code,
            'code',
            PersonalDatabaseManagementErrorCode.moveScopeConflict,
          ),
        ),
      );
    });
  });
}
