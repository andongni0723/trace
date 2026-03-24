import 'package:drift/drift.dart';

class People extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  IntColumn get colorValue => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
