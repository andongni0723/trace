import 'package:drift/drift.dart';

import 'people.dart';
import 'todos.dart';

class TodoParticipants extends Table {
  TextColumn get todoId => text().references(Todos, #id, onDelete: KeyAction.cascade)();

  TextColumn get personId => text().references(People, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {todoId, personId};
}
