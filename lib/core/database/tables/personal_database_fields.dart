import 'package:drift/drift.dart';

import 'people.dart';

class PersonalDatabaseFields extends Table {
  TextColumn get id => text()();

  TextColumn get key => text().withLength(min: 1, max: 120)();

  TextColumn get parentFieldId => text().nullable()();

  TextColumn get valueType => text().withLength(min: 1, max: 20)();

  TextColumn get arrayElementType =>
      text().withLength(min: 1, max: 20).nullable()();

  TextColumn get arrayElementTemplateJsonValue => text().nullable()();

  BoolColumn get isPublic => boolean().withDefault(const Constant(true))();

  TextColumn get ownerPersonId =>
      text().nullable().references(People, #id, onDelete: KeyAction.cascade)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
