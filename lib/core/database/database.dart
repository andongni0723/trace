import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/people/data/daos/people_dao.dart';
import '../../features/people/data/daos/todos_dao.dart';
import 'tables/people.dart';
import 'tables/todo_participants.dart';
import 'tables/todos.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [People, Todos, TodoParticipants],
  daos: [PeopleDao, TodosDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(todos, todos.starred);
            await migrator.addColumn(todos, todos.dueAt);
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
    final databaseFile = File(
      p.join(documentsDirectory.path, 'people_todolist.sqlite'),
    );

    return NativeDatabase.createInBackground(databaseFile);
  });
}
