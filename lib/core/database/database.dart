import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/people/data/daos/people_dao.dart';
import '../../features/people/data/daos/personal_database_dao.dart';
import '../../features/people/data/daos/todos_dao.dart';
import 'tables/people.dart';
import 'tables/personal_database_fields.dart';
import 'tables/personal_database_person_fields.dart';
import 'tables/personal_database_values.dart';
import 'tables/todo_participants.dart';
import 'tables/todos.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    People,
    Todos,
    TodoParticipants,
    PersonalDatabaseFields,
    PersonalDatabasePersonFields,
    PersonalDatabaseValues,
  ],
  daos: [PeopleDao, TodosDao, PersonalDatabaseDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(todos, todos.starred);
        await migrator.addColumn(todos, todos.dueAt);
      }
      if (from < 3) {
        await migrator.createTable(personalDatabaseFields);
        await migrator.createTable(personalDatabaseValues);
      }
      if (from < 4) {
        await migrator.addColumn(people, people.avatarPath);
      }
      if (from < 5) {
        await migrator.createTable(personalDatabasePersonFields);
        await customStatement('''
          INSERT OR IGNORE INTO personal_database_person_fields (
            field_id,
            person_id,
            sort_order,
            created_at
          )
          SELECT
            field_id,
            person_id,
            0,
            updated_at
          FROM personal_database_values
        ''');
        await customStatement('''
          UPDATE personal_database_fields
          SET is_public = 1,
              owner_person_id = NULL
        ''');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databaseFile = File(p.join(documentsDirectory.path, 'trace.sqlite'));
    final legacyDatabaseFile = File(
      p.join(documentsDirectory.path, 'people_todolist.sqlite'),
    );

    if (!await databaseFile.exists() && await legacyDatabaseFile.exists()) {
      await legacyDatabaseFile.rename(databaseFile.path);
    }

    return NativeDatabase.createInBackground(databaseFile);
  });
}
