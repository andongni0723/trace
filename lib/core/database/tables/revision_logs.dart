import 'package:drift/drift.dart';

import '../date_time_millis_converter.dart';

class RevisionLogs extends Table {
  TextColumn get id => text()();

  TextColumn get action => text().withLength(min: 1, max: 32)();

  TextColumn get entityType => text().withLength(min: 1, max: 64)();

  TextColumn get entityId => text().withLength(min: 1, max: 160)();

  TextColumn get entityLabel => text().nullable()();

  TextColumn get summary => text().withLength(min: 1, max: 500)();

  TextColumn get changedFieldsJson =>
      text().withDefault(const Constant('[]'))();

  TextColumn get beforeJson => text().nullable()();

  TextColumn get afterJson => text().nullable()();

  IntColumn get happenedAt => integer().map(const DateTimeMillisConverter())();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
