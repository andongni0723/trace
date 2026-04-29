import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../data/daos/people_dao.dart';
import '../data/daos/person_notes_dao.dart';
import '../data/daos/personal_database_dao.dart';
import '../data/services/person_avatar_picker.dart';
import '../data/services/person_avatar_storage.dart';
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

final personNotesDaoProvider = Provider<PersonNotesDao>((ref) {
  return ref.watch(appDatabaseProvider).personNotesDao;
});

final personalDatabaseDaoProvider = Provider<PersonalDatabaseDao>((ref) {
  return ref.watch(appDatabaseProvider).personalDatabaseDao;
});

final personAvatarStorageProvider = Provider<PersonAvatarStorage>((ref) {
  return PersonAvatarStorage();
});

final personAvatarPickerProvider = Provider<PersonAvatarPicker>((ref) {
  return PersonAvatarPicker();
});
