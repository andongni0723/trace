import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/person_notes.dart';

part 'person_notes_dao.g.dart';

@DriftAccessor(tables: [PersonNotes])
class PersonNotesDao extends DatabaseAccessor<AppDatabase>
    with _$PersonNotesDaoMixin {
  PersonNotesDao(super.db);

  Stream<PersonNote?> watchNoteForPerson(String personId) {
    return (select(
      personNotes,
    )..where((table) => table.personId.equals(personId))).watchSingleOrNull();
  }

  Future<PersonNote?> getNoteForPerson(String personId) {
    return (select(
      personNotes,
    )..where((table) => table.personId.equals(personId))).getSingleOrNull();
  }

  Future<void> upsertNote({required String personId, required String content}) {
    return into(personNotes).insertOnConflictUpdate(
      PersonNotesCompanion.insert(
        personId: personId,
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
