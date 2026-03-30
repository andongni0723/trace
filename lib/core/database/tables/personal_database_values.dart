import 'package:drift/drift.dart';

import 'people.dart';
import 'personal_database_fields.dart';

class PersonalDatabaseValues extends Table {
  TextColumn get fieldId => text().references(
    PersonalDatabaseFields,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get personId =>
      text().references(People, #id, onDelete: KeyAction.cascade)();

  TextColumn get jsonValue => text().withDefault(const Constant('null'))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {fieldId, personId};
}
