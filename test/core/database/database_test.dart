import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/personal_database_media_value.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('PeopleDao', () {
    test('supports create, read, update, delete', () async {
      await database.peopleDao.createPerson(
        id: 'maya',
        name: 'Maya',
        colorValue: 0xFF5B6CF0,
        avatarPath: '/avatars/maya.png',
      );

      final createdPerson = await database.peopleDao.getPersonById('maya');
      expect(createdPerson, isNotNull);
      expect(createdPerson!.name, 'Maya');
      expect(createdPerson.colorValue, 0xFF5B6CF0);
      expect(createdPerson.avatarPath, '/avatars/maya.png');

      final didUpdate = await database.peopleDao.updatePerson(
        id: 'maya',
        name: 'Maya Chen',
        colorValue: 0xFF334455,
      );
      expect(didUpdate, 1);

      final updatedPerson = await database.peopleDao.getPersonById('maya');
      expect(updatedPerson, isNotNull);
      expect(updatedPerson!.name, 'Maya Chen');
      expect(updatedPerson.colorValue, 0xFF334455);
      expect(updatedPerson.avatarPath, '/avatars/maya.png');

      final clearedRows = await database.peopleDao.updatePerson(
        id: 'maya',
        name: 'Maya Chen',
        colorValue: 0xFF334455,
        avatarPath: const Value(null),
      );
      expect(clearedRows, 1);

      final clearedPerson = await database.peopleDao.getPersonById('maya');
      expect(clearedPerson, isNotNull);
      expect(clearedPerson!.avatarPath, isNull);

      final deletedRows = await database.peopleDao.deletePersonById('maya');
      expect(deletedRows, 1);
      expect(await database.peopleDao.getPersonById('maya'), isNull);
    });
  });

  group('TodosDao', () {
    setUp(() async {
      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
        avatarPath: '/avatars/owner.png',
      );
      await database.peopleDao.createPerson(
        id: 'friend-a',
        name: 'Friend A',
        colorValue: 0xFF222222,
        avatarPath: '/avatars/friend-a.png',
      );
      await database.peopleDao.createPerson(
        id: 'friend-b',
        name: 'Friend B',
        colorValue: 0xFF333333,
      );
    });

    test('supports todo CRUD with participant mapping', () async {
      await database.todosDao.createTodo(
        id: 'todo-1',
        personId: 'owner',
        title: 'Plan trip',
        note: 'Book train tickets',
        starred: true,
        dueAt: DateTime(2026, 3, 26, 9, 30),
        participantPersonIds: const ['friend-a', 'friend-b', 'friend-a'],
      );

      final createdTodo = await database.todosDao.getTodoWithPeopleById(
        'todo-1',
      );
      expect(createdTodo, isNotNull);
      final createdTodoValue = createdTodo!;
      expect(createdTodoValue.todo.title, 'Plan trip');
      expect(createdTodoValue.todo.starred, isTrue);
      expect(createdTodoValue.todo.dueAt, DateTime(2026, 3, 26, 9, 30));
      expect(
        createdTodoValue.relatedPeople.map((person) => person.id),
        unorderedEquals(['friend-a', 'friend-b']),
      );

      final didUpdate = await database.todosDao.updateTodo(
        id: 'todo-1',
        title: 'Plan group trip',
        note: const Value(null),
        starred: false,
        dueAt: const Value(null),
        done: true,
        participantPersonIds: const ['friend-b'],
      );
      expect(didUpdate, 1);

      final updatedTodo = await database.todosDao.getTodoWithPeopleById(
        'todo-1',
      );
      expect(updatedTodo, isNotNull);
      final updatedTodoValue = updatedTodo!;
      expect(updatedTodoValue.todo.title, 'Plan group trip');
      expect(updatedTodoValue.todo.note, isNull);
      expect(updatedTodoValue.todo.starred, isFalse);
      expect(updatedTodoValue.todo.dueAt, isNull);
      expect(updatedTodoValue.todo.done, isTrue);
      expect(updatedTodoValue.relatedPeople.map((person) => person.id), [
        'friend-b',
      ]);

      final deletedRows = await database.todosDao.deleteTodoById('todo-1');
      expect(deletedRows, 1);
      expect(await database.todosDao.getTodoById('todo-1'), isNull);
      expect(await database.todosDao.getParticipantsForTodo('todo-1'), isEmpty);
    });

    test(
      'deleting a person cascades to owned todos and participant links',
      () async {
        await database.todosDao.createTodo(
          id: 'todo-2',
          personId: 'owner',
          title: 'Call everyone',
          participantPersonIds: const ['friend-a'],
        );

        await database.peopleDao.deletePersonById('owner');

        expect(await database.todosDao.getTodoById('todo-2'), isNull);
        expect(
          await database.todosDao.getParticipantsForTodo('todo-2'),
          isEmpty,
        );
      },
    );
  });

  group('PersonalDatabaseDao', () {
    setUp(() async {
      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
        avatarPath: '/avatars/owner.png',
      );
      await database.peopleDao.createPerson(
        id: 'friend-a',
        name: 'Friend A',
        colorValue: 0xFF222222,
      );
    });

    test(
      'creates properties in the global library and assigns to one person',
      () async {
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-1',
          personId: 'owner',
          key: 'nickname',
          type: PersonalDatabaseValueType.string,
          jsonValue: '"Captain"',
        );

        final libraryFields = await database.personalDatabaseDao
            .watchFieldLibrary()
            .first;
        final rawDefinition = await database.personalDatabaseDao.getFieldById(
          'field-1',
        );
        final ownerFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('owner')
            .first;
        final friendFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('friend-a')
            .first;

        expect(libraryFields, hasLength(1));
        expect(libraryFields.single.key, 'nickname');
        expect(rawDefinition, isNotNull);
        expect(rawDefinition!.ownerPersonId, isNull);
        expect(ownerFields, hasLength(1));
        expect(ownerFields.single.key, 'nickname');
        expect(ownerFields.single.value, 'Captain');
        expect(friendFields, isEmpty);
      },
    );

    test('can assign an existing property to another person', () async {
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-2',
        personId: 'owner',
        key: 'secretNote',
        type: PersonalDatabaseValueType.string,
        jsonValue: '"Only owner"',
      );

      await database.personalDatabaseDao.assignFieldToPerson(
        fieldId: 'field-2',
        personId: 'friend-a',
      );

      await database.personalDatabaseDao.updateFieldValueForPerson(
        fieldId: 'field-2',
        personId: 'friend-a',
        type: PersonalDatabaseValueType.string,
        jsonValue: '"Buddy"',
      );

      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;
      final friendFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('friend-a')
          .first;

      expect(ownerFields.map((field) => field.value), ['Only owner']);
      expect(friendFields.map((field) => field.value), ['Buddy']);
    });

    test(
      'keeps existing person values stable when definition type changes',
      () async {
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-3',
          personId: 'owner',
          key: 'score',
          type: PersonalDatabaseValueType.number,
          jsonValue: '42',
        );

        await database.personalDatabaseDao.assignFieldToPerson(
          fieldId: 'field-3',
          personId: 'friend-a',
        );
        await database.personalDatabaseDao.updateFieldValueForPerson(
          fieldId: 'field-3',
          personId: 'friend-a',
          type: PersonalDatabaseValueType.number,
          jsonValue: '7',
        );

        await database.personalDatabaseDao.updatePropertyDefinition(
          fieldId: 'field-3',
          key: 'scoreText',
          type: PersonalDatabaseValueType.string,
        );

        final ownerFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('owner')
            .first;
        final friendFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('friend-a')
            .first;

        expect(ownerFields.single.key, 'scoreText');
        expect(ownerFields.single.value, '42');
        expect(friendFields.single.key, 'scoreText');
        expect(friendFields.single.value, '7');
      },
    );

    test('encodes and decodes media property values', () async {
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-media',
        personId: 'owner',
        key: 'photo',
        type: PersonalDatabaseValueType.media,
        jsonValue:
            '{"mediaAssetId":"asset-1","fileName":"portrait.jpg","kind":"image"}',
      );

      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;

      expect(ownerFields.single.type, PersonalDatabaseValueType.media);
      expect(
        ownerFields.single.value,
        const PersonalDatabaseMediaValue(
          mediaAssetId: 'asset-1',
          fileName: 'portrait.jpg',
          kind: 'image',
        ),
      );
    });

    test(
      'stores array element type and object template on definitions',
      () async {
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-list',
          personId: 'owner',
          key: 'pets',
          type: PersonalDatabaseValueType.list,
          jsonValue: '[]',
          arrayElementType: PersonalDatabaseValueType.object,
          arrayElementTemplateJsonValue: '{"name":"","age":0}',
        );

        final rawDefinition = await database.personalDatabaseDao.getFieldById(
          'field-list',
        );
        final ownerFields = await database.personalDatabaseDao
            .watchFieldTreeForPerson('owner')
            .first;

        expect(rawDefinition!.arrayElementType, 'object');
        expect(
          rawDefinition.arrayElementTemplateJsonValue,
          '{"name":"","age":0}',
        );
        expect(
          ownerFields.single.arrayElementType,
          PersonalDatabaseValueType.object,
        );
        expect(ownerFields.single.arrayElementTemplate, {'name': '', 'age': 0});
      },
    );

    test('list fields default to unspecified array element metadata', () async {
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-list',
        personId: 'owner',
        key: 'tags',
        type: PersonalDatabaseValueType.list,
        jsonValue: '[]',
      );

      final rawDefinition = await database.personalDatabaseDao.getFieldById(
        'field-list',
      );
      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;

      expect(rawDefinition!.arrayElementType, isNull);
      expect(rawDefinition.arrayElementTemplateJsonValue, isNull);
      expect(ownerFields.single.arrayElementType, isNull);
      expect(ownerFields.single.arrayElementTemplate, isNull);
    });

    test('clears array template when element type is not object', () async {
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-list',
        personId: 'owner',
        key: 'pets',
        type: PersonalDatabaseValueType.list,
        jsonValue: '[]',
        arrayElementType: PersonalDatabaseValueType.object,
        arrayElementTemplateJsonValue: '{"name":""}',
      );

      await database.personalDatabaseDao.updateArrayElementType(
        fieldId: 'field-list',
        elementType: PersonalDatabaseValueType.string,
      );

      final rawDefinition = await database.personalDatabaseDao.getFieldById(
        'field-list',
      );
      final ownerFields = await database.personalDatabaseDao
          .watchFieldTreeForPerson('owner')
          .first;

      expect(rawDefinition!.arrayElementType, 'string');
      expect(rawDefinition.arrayElementTemplateJsonValue, isNull);
      expect(
        ownerFields.single.arrayElementType,
        PersonalDatabaseValueType.string,
      );
      expect(ownerFields.single.arrayElementTemplate, isNull);
    });

    test(
      'clears array metadata when property type changes away from list',
      () async {
        await database.personalDatabaseDao.createFieldAndAssignToPerson(
          id: 'field-list',
          personId: 'owner',
          key: 'pets',
          type: PersonalDatabaseValueType.list,
          jsonValue: '[]',
          arrayElementType: PersonalDatabaseValueType.object,
          arrayElementTemplateJsonValue: '{"name":""}',
        );

        await database.personalDatabaseDao.updatePropertyDefinition(
          fieldId: 'field-list',
          key: 'pets',
          type: PersonalDatabaseValueType.string,
        );

        final rawDefinition = await database.personalDatabaseDao.getFieldById(
          'field-list',
        );

        expect(rawDefinition!.valueType, 'string');
        expect(rawDefinition.arrayElementType, isNull);
        expect(rawDefinition.arrayElementTemplateJsonValue, isNull);
      },
    );
  });
}
