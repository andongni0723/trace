import 'package:drift/drift.dart';

import 'people.dart';

class Todos extends Table {
  TextColumn get id => text()();

  TextColumn get personId =>
      text().references(People, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text().withLength(min: 1, max: 280)();

  TextColumn get note => text().nullable()();

  BoolColumn get starred => boolean().withDefault(const Constant(false))();

  DateTimeColumn get dueAt => dateTime().nullable()();

  BoolColumn get done => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
