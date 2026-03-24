import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../data/daos/people_dao.dart';
import '../data/daos/todos_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final peopleDaoProvider = Provider<PeopleDao>((ref) {
  return ref.watch(appDatabaseProvider).peopleDao;
});

final todosDaoProvider = Provider<TodosDao>((ref) {
  return ref.watch(appDatabaseProvider).todosDao;
});
