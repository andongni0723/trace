import 'package:drift/drift.dart';

import 'people.dart';

class PersonNotes extends Table {
  TextColumn get personId =>
      text().references(People, #id, onDelete: KeyAction.cascade)();

  TextColumn get content => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {personId};
}
