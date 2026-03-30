import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/people.dart';
import '../../../../core/database/tables/todo_participants.dart';
import '../../../../core/database/tables/todos.dart';
import '../models/todo_with_people.dart';

part 'todos_dao.g.dart';

@DriftAccessor(tables: [Todos, TodoParticipants, People])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  Expression<bool> _matchesTodoId(String todoId) => todos.id.equals(todoId);

  Selectable<Todo> _todosForPersonQuery(String personId) {
    return (select(todos)..where((table) => table.personId.equals(personId)))
      ..orderBy([
        (table) => OrderingTerm.asc(table.done),
        (table) => OrderingTerm.desc(table.updatedAt),
      ]);
  }

  Stream<List<Todo>> watchTodosForPerson(String personId) {
    return _todosForPersonQuery(personId).watch();
  }

  Stream<List<Todo>> watchAllTodos() {
    return (select(todos)..orderBy([
          (table) => OrderingTerm.asc(table.done),
          (table) => OrderingTerm.desc(table.updatedAt),
        ]))
        .watch();
  }

  Future<List<Todo>> getTodosForPerson(String personId) {
    return _todosForPersonQuery(personId).get();
  }

  Stream<Todo?> watchTodoById(String todoId) {
    return (select(
      todos,
    )..where((table) => _matchesTodoId(todoId))).watchSingleOrNull();
  }

  Future<Todo?> getTodoById(String todoId) {
    return (select(
      todos,
    )..where((table) => _matchesTodoId(todoId))).getSingleOrNull();
  }

  Stream<List<TodoWithPeople>> watchTodosWithPeopleForPerson(String personId) {
    return watchTodosForPerson(personId).asyncMap(_composeTodoBundles);
  }

  Future<TodoWithPeople?> getTodoWithPeopleById(String todoId) async {
    final todo = await getTodoById(todoId);
    if (todo == null) {
      return null;
    }

    final bundles = await _composeTodoBundles([todo]);
    return bundles.single;
  }

  Future<int> createTodo({
    required String id,
    required String personId,
    required String title,
    String? note,
    bool starred = false,
    DateTime? dueAt,
    bool done = false,
    List<String> participantPersonIds = const [],
  }) async {
    return transaction(() async {
      final insertResult = await into(todos).insert(
        TodosCompanion.insert(
          id: id,
          personId: personId,
          title: title,
          note: Value(note),
          starred: Value(starred),
          dueAt: Value(dueAt),
          done: Value(done),
        ),
      );

      await _replaceParticipants(
        todoId: id,
        participantPersonIds: participantPersonIds,
      );

      return insertResult;
    });
  }

  Future<int> updateTodo({
    required String id,
    String? personId,
    String? title,
    Value<String?> note = const Value.absent(),
    bool? starred,
    Value<DateTime?> dueAt = const Value.absent(),
    bool? done,
    List<String>? participantPersonIds,
  }) async {
    return transaction(() async {
      final didUpdate =
          await (update(todos)..where((table) => _matchesTodoId(id))).write(
            TodosCompanion(
              personId: personId == null
                  ? const Value.absent()
                  : Value(personId),
              title: title == null ? const Value.absent() : Value(title),
              note: note,
              starred: starred == null ? const Value.absent() : Value(starred),
              dueAt: dueAt,
              done: done == null ? const Value.absent() : Value(done),
              updatedAt: Value(DateTime.now()),
            ),
          );

      if (participantPersonIds != null) {
        await _replaceParticipants(
          todoId: id,
          participantPersonIds: participantPersonIds,
        );
      }

      return didUpdate;
    });
  }

  Future<int> setTodoDone({required String todoId, required bool done}) {
    return (update(todos)..where((table) => _matchesTodoId(todoId))).write(
      TodosCompanion(done: Value(done), updatedAt: Value(DateTime.now())),
    );
  }

  Future<int> setTodoStarred({required String todoId, required bool starred}) {
    return (update(todos)..where((table) => _matchesTodoId(todoId))).write(
      TodosCompanion(starred: Value(starred), updatedAt: Value(DateTime.now())),
    );
  }

  Future<int> deleteTodoById(String todoId) {
    return (delete(todos)..where((table) => _matchesTodoId(todoId))).go();
  }

  Future<List<PeopleData>> getParticipantsForTodo(String todoId) async {
    final rows = await _participantsJoinQuery(todoIds: [todoId]).get();

    return rows.map((row) => row.readTable(people)).toList(growable: false);
  }

  Stream<List<PeopleData>> watchParticipantsForTodo(String todoId) {
    return _participantsJoinQuery(todoIds: [todoId]).watch().map(
      (rows) =>
          rows.map((row) => row.readTable(people)).toList(growable: false),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _participantsJoinQuery({
    required Iterable<String> todoIds,
  }) {
    return select(todoParticipants).join([
      innerJoin(people, people.id.equalsExp(todoParticipants.personId)),
    ])..where(todoParticipants.todoId.isIn(todoIds));
  }

  Future<List<TodoWithPeople>> _composeTodoBundles(List<Todo> todoItems) async {
    if (todoItems.isEmpty) {
      return const [];
    }

    final participantsByTodoId = await _loadParticipantsByTodoIds(
      todoItems.map((todo) => todo.id),
    );

    return todoItems
        .map(
          (todo) => TodoWithPeople(
            todo: todo,
            relatedPeople: participantsByTodoId[todo.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, List<PeopleData>>> _loadParticipantsByTodoIds(
    Iterable<String> todoIds,
  ) async {
    final ids = todoIds.toList(growable: false);
    if (ids.isEmpty) {
      return const {};
    }

    final rows = await _participantsJoinQuery(todoIds: ids).get();
    final participantsByTodoId = <String, List<PeopleData>>{};

    for (final row in rows) {
      final participant = row.readTable(todoParticipants);
      final person = row.readTable(people);
      participantsByTodoId
          .putIfAbsent(participant.todoId, () => [])
          .add(person);
    }

    return participantsByTodoId;
  }

  Future<void> _replaceParticipants({
    required String todoId,
    required List<String> participantPersonIds,
  }) async {
    await (delete(
      todoParticipants,
    )..where((table) => table.todoId.equals(todoId))).go();

    final distinctParticipantIds = participantPersonIds.toSet().toList(
      growable: false,
    );
    if (distinctParticipantIds.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(
        todoParticipants,
        distinctParticipantIds
            .map(
              (personId) => TodoParticipantsCompanion.insert(
                todoId: todoId,
                personId: personId,
              ),
            )
            .toList(growable: false),
      );
    });
  }
}
