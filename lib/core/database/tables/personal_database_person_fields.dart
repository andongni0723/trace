import 'package:drift/drift.dart';

import 'people.dart';
import 'personal_database_fields.dart';

class PersonalDatabasePersonFields extends Table {
  TextColumn get fieldId => text().references(
    PersonalDatabaseFields,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get personId =>
      text().references(People, #id, onDelete: KeyAction.cascade)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {fieldId, personId};
}
