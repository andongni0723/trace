import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_todolist/core/database/database.dart';

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
      );

      final createdPerson = await database.peopleDao.getPersonById('maya');
      expect(createdPerson, isNotNull);
      expect(createdPerson!.name, 'Maya');
      expect(createdPerson.colorValue, 0xFF5B6CF0);

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
      );
      await database.peopleDao.createPerson(
        id: 'friend-a',
        name: 'Friend A',
        colorValue: 0xFF222222,
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

      final createdTodo =
          await database.todosDao.getTodoWithPeopleById('todo-1');
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

      final updatedTodo =
          await database.todosDao.getTodoWithPeopleById('todo-1');
      expect(updatedTodo, isNotNull);
      final updatedTodoValue = updatedTodo!;
      expect(updatedTodoValue.todo.title, 'Plan group trip');
      expect(updatedTodoValue.todo.note, isNull);
      expect(updatedTodoValue.todo.starred, isFalse);
      expect(updatedTodoValue.todo.dueAt, isNull);
      expect(updatedTodoValue.todo.done, isTrue);
      expect(
        updatedTodoValue.relatedPeople.map((person) => person.id),
        ['friend-b'],
      );

      final deletedRows = await database.todosDao.deleteTodoById('todo-1');
      expect(deletedRows, 1);
      expect(await database.todosDao.getTodoById('todo-1'), isNull);
      expect(
        await database.todosDao.getParticipantsForTodo('todo-1'),
        isEmpty,
      );
    });

    test('deleting a person cascades to owned todos and participant links', () async {
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
    });
  });
}
