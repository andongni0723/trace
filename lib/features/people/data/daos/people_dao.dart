import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/people.dart';

part 'people_dao.g.dart';

@DriftAccessor(tables: [People])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(super.db);

  Expression<bool> _matchesId(String personId) => people.id.equals(personId);

  Selectable<PeopleData> _orderedPeople() {
    return select(people)
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
  }

  Stream<List<PeopleData>> watchPeople() => _orderedPeople().watch();

  Future<List<PeopleData>> getPeople() => _orderedPeople().get();

  Stream<PeopleData?> watchPersonById(String personId) {
    return (select(people)..where((table) => _matchesId(personId)))
        .watchSingleOrNull();
  }

  Future<PeopleData?> getPersonById(String personId) {
    return (select(people)..where((table) => _matchesId(personId)))
        .getSingleOrNull();
  }

  Future<int> insertPerson({
    required String id,
    required String name,
    required int colorValue,
    String? avatarPath,
  }) {
    return into(people).insert(
      PeopleCompanion.insert(
        id: id,
        name: name,
        colorValue: colorValue,
        avatarPath: Value(avatarPath),
      ),
    );
  }

  Future<int> createPerson({
    required String id,
    required String name,
    required int colorValue,
    String? avatarPath,
  }) {
    return insertPerson(
      id: id,
      name: name,
      colorValue: colorValue,
      avatarPath: avatarPath,
    );
  }

  Future<int> updatePerson({
    required String id,
    required String name,
    required int colorValue,
    Value<String?> avatarPath = const Value.absent(),
  }) {
    return (update(people)..where((table) => _matchesId(id))).write(
      PeopleCompanion(
        name: Value(name),
        colorValue: Value(colorValue),
        avatarPath: avatarPath,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> upsertPerson({
    required String id,
    required String name,
    required int colorValue,
    Value<String?> avatarPath = const Value.absent(),
  }) {
    return into(people).insertOnConflictUpdate(
      PeopleCompanion(
        id: Value(id),
        name: Value(name),
        colorValue: Value(colorValue),
        avatarPath: avatarPath,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deletePersonById(String personId) {
    return (delete(people)..where((table) => _matchesId(personId))).go();
  }
}
