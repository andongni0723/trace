import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/people.dart';
import '../../../../core/database/tables/personal_database_fields.dart';
import '../../../../core/database/tables/personal_database_values.dart';
import '../models/personal_database_field_node.dart';
import '../models/personal_database_value_type.dart';

part 'personal_database_dao.g.dart';

@DriftAccessor(tables: [PersonalDatabaseFields, PersonalDatabaseValues, People])
class PersonalDatabaseDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalDatabaseDaoMixin {
  PersonalDatabaseDao(super.db);

  Stream<List<PersonalDatabaseFieldNode>> watchFieldTreeForPerson(
    String personId,
  ) {
    final valuesAlias = alias(personalDatabaseValues, 'values_for_person');
    final query =
        select(personalDatabaseFields).join([
            leftOuterJoin(
              valuesAlias,
              valuesAlias.fieldId.equalsExp(personalDatabaseFields.id) &
                  valuesAlias.personId.equals(personId),
            ),
          ])
          ..where(
            personalDatabaseFields.isPublic.equals(true) |
                personalDatabaseFields.ownerPersonId.equals(personId),
          )
          ..orderBy([
            OrderingTerm.asc(personalDatabaseFields.sortOrder),
            OrderingTerm.asc(personalDatabaseFields.createdAt),
            OrderingTerm.asc(personalDatabaseFields.key),
          ]);

    return query.watch().map((rows) => _buildFieldTree(rows, valuesAlias));
  }

  Future<int> getNextSortOrder({
    required String actorPersonId,
    required bool isPublic,
    String? parentFieldId,
  }) async {
    final query = selectOnly(personalDatabaseFields)
      ..addColumns([personalDatabaseFields.id.count()]);

    query.where(
      _scopeExpression(actorPersonId: actorPersonId, isPublic: isPublic),
    );

    if (parentFieldId == null) {
      query.where(personalDatabaseFields.parentFieldId.isNull());
    } else {
      query.where(personalDatabaseFields.parentFieldId.equals(parentFieldId));
    }

    final count = await query
        .map((row) => row.read(personalDatabaseFields.id.count()) ?? 0)
        .getSingle();

    return count;
  }

  Future<PersonalDatabaseField?> getFieldById(String fieldId) {
    return (select(
      personalDatabaseFields,
    )..where((table) => table.id.equals(fieldId))).getSingleOrNull();
  }

  Future<void> createField({
    required String id,
    required String actorPersonId,
    required String key,
    required PersonalDatabaseValueType type,
    required bool isPublic,
    required String jsonValue,
    String? parentFieldId,
    int sortOrder = 0,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final normalizedJsonValue = _normalizeJsonValue(
      type: type,
      jsonValue: jsonValue,
    );
    final ownerPersonId = isPublic ? null : actorPersonId;

    await transaction(() async {
      await into(personalDatabaseFields).insert(
        PersonalDatabaseFieldsCompanion.insert(
          id: id,
          key: trimmedKey,
          valueType: type.dbKey,
          isPublic: Value(isPublic),
          ownerPersonId: Value(ownerPersonId),
          parentFieldId: Value(parentFieldId),
          sortOrder: Value(sortOrder),
        ),
      );

      if (isPublic) {
        final personIds = await _getAllPersonIds();
        await _upsertValuesForPeople(
          fieldId: id,
          personIds: personIds,
          jsonValueByPersonId: {
            for (final personId in personIds) personId: normalizedJsonValue,
          },
        );
      } else {
        await _upsertFieldValue(
          fieldId: id,
          personId: actorPersonId,
          jsonValue: normalizedJsonValue,
        );
      }
    });
  }

  Future<void> updateField({
    required String fieldId,
    required String actorPersonId,
    required String key,
    required PersonalDatabaseValueType type,
    required bool isPublic,
    required String jsonValue,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final normalizedJsonValue = _normalizeJsonValue(
      type: type,
      jsonValue: jsonValue,
    );
    final ownerPersonId = isPublic ? null : actorPersonId;

    await transaction(() async {
      final existing = await getFieldById(fieldId);
      if (existing == null) {
        return;
      }

      if (!existing.isPublic && existing.ownerPersonId != actorPersonId) {
        return;
      }

      final existingValues = await (select(
        personalDatabaseValues,
      )..where((table) => table.fieldId.equals(fieldId))).get();
      final existingValueByPerson = {
        for (final row in existingValues) row.personId: row.jsonValue,
      };
      final didChangeType = existing.valueType != type.dbKey;

      await (update(
        personalDatabaseFields,
      )..where((table) => table.id.equals(fieldId))).write(
        PersonalDatabaseFieldsCompanion(
          key: Value(trimmedKey),
          valueType: Value(type.dbKey),
          isPublic: Value(isPublic),
          ownerPersonId: Value(ownerPersonId),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (isPublic) {
        final personIds = await _getAllPersonIds();
        final jsonValueByPersonId = <String, String>{};
        for (final personId in personIds) {
          if (personId == actorPersonId) {
            jsonValueByPersonId[personId] = normalizedJsonValue;
            continue;
          }

          if (didChangeType) {
            jsonValueByPersonId[personId] = type.defaultJsonValue;
            continue;
          }

          jsonValueByPersonId[personId] =
              existingValueByPerson[personId] ?? type.defaultJsonValue;
        }

        await _upsertValuesForPeople(
          fieldId: fieldId,
          personIds: personIds,
          jsonValueByPersonId: jsonValueByPersonId,
        );
      } else {
        await (delete(personalDatabaseValues)
              ..where((table) => table.fieldId.equals(fieldId))
              ..where((table) => table.personId.isNotValue(actorPersonId)))
            .go();

        await _upsertFieldValue(
          fieldId: fieldId,
          personId: actorPersonId,
          jsonValue: normalizedJsonValue,
        );
      }
    });
  }

  Future<void> updateFieldValueForPerson({
    required String fieldId,
    required String personId,
    required PersonalDatabaseValueType type,
    required String jsonValue,
  }) {
    return _upsertFieldValue(
      fieldId: fieldId,
      personId: personId,
      jsonValue: _normalizeJsonValue(type: type, jsonValue: jsonValue),
    );
  }

  Future<void> deleteField(String fieldId) async {
    await transaction(() async {
      final fieldIds = await _collectDescendantFieldIds(fieldId);
      if (fieldIds.isEmpty) {
        return;
      }

      await (delete(
        personalDatabaseValues,
      )..where((table) => table.fieldId.isIn(fieldIds))).go();

      await (delete(
        personalDatabaseFields,
      )..where((table) => table.id.isIn(fieldIds))).go();
    });
  }

  Future<List<String>> _collectDescendantFieldIds(String fieldId) async {
    final allFields = await select(personalDatabaseFields).get();
    final childrenByParentId = <String, List<String>>{};

    for (final field in allFields) {
      final parentId = field.parentFieldId;
      if (parentId == null) {
        continue;
      }
      childrenByParentId.putIfAbsent(parentId, () => []).add(field.id);
    }

    if (!allFields.any((field) => field.id == fieldId)) {
      return const [];
    }

    final stack = <String>[fieldId];
    final collected = <String>{};

    while (stack.isNotEmpty) {
      final currentId = stack.removeLast();
      if (!collected.add(currentId)) {
        continue;
      }
      stack.addAll(childrenByParentId[currentId] ?? const []);
    }

    return collected.toList(growable: false);
  }

  Expression<bool> _scopeExpression({
    required String actorPersonId,
    required bool isPublic,
  }) {
    if (isPublic) {
      return personalDatabaseFields.isPublic.equals(true);
    }

    return personalDatabaseFields.isPublic.equals(false) &
        personalDatabaseFields.ownerPersonId.equals(actorPersonId);
  }

  Future<List<String>> _getAllPersonIds() async {
    final allPeople = await select(people).get();
    return allPeople.map((person) => person.id).toList(growable: false);
  }

  Future<void> _upsertValuesForPeople({
    required String fieldId,
    required List<String> personIds,
    required Map<String, String> jsonValueByPersonId,
  }) async {
    if (personIds.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        personalDatabaseValues,
        personIds
            .map(
              (personId) => PersonalDatabaseValuesCompanion(
                fieldId: Value(fieldId),
                personId: Value(personId),
                jsonValue: Value(jsonValueByPersonId[personId] ?? 'null'),
                updatedAt: Value(DateTime.now()),
              ),
            )
            .toList(growable: false),
      );
    });
  }

  Future<void> _upsertFieldValue({
    required String fieldId,
    required String personId,
    required String jsonValue,
  }) async {
    await into(personalDatabaseValues).insertOnConflictUpdate(
      PersonalDatabaseValuesCompanion(
        fieldId: Value(fieldId),
        personId: Value(personId),
        jsonValue: Value(jsonValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  List<PersonalDatabaseFieldNode> _buildFieldTree(
    List<TypedResult> rows,
    $PersonalDatabaseValuesTable valuesAlias,
  ) {
    final fieldRows = <String, _FieldRow>{};
    final childrenByParentId = <String, List<_FieldRow>>{};

    for (final row in rows) {
      final field = row.readTable(personalDatabaseFields);
      final valueForPerson = row.readTableOrNull(valuesAlias);
      final type = personalDatabaseValueTypeFromDb(field.valueType);
      final resolvedJsonValue =
          valueForPerson?.jsonValue ?? type.defaultJsonValue;

      final record = _FieldRow(
        id: field.id,
        key: field.key,
        type: type,
        isPublic: field.isPublic,
        parentFieldId: field.parentFieldId,
        sortOrder: field.sortOrder,
        rawJsonValue: resolvedJsonValue,
      );

      fieldRows[field.id] = record;
    }

    for (final row in fieldRows.values) {
      final parentId = row.parentFieldId;
      if (parentId == null || !fieldRows.containsKey(parentId)) {
        continue;
      }
      childrenByParentId.putIfAbsent(parentId, () => []).add(row);
    }

    int compareRows(_FieldRow a, _FieldRow b) {
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }
      return a.key.compareTo(b.key);
    }

    for (final entries in childrenByParentId.values) {
      entries.sort(compareRows);
    }

    final rootRows =
        fieldRows.values
            .where(
              (row) =>
                  row.parentFieldId == null ||
                  !fieldRows.containsKey(row.parentFieldId),
            )
            .toList(growable: false)
          ..sort(compareRows);

    PersonalDatabaseFieldNode buildNode(_FieldRow row) {
      final children = (childrenByParentId[row.id] ?? const [])
          .map(buildNode)
          .toList(growable: false);

      return PersonalDatabaseFieldNode(
        id: row.id,
        key: row.key,
        type: row.type,
        isPublic: row.isPublic,
        parentFieldId: row.parentFieldId,
        sortOrder: row.sortOrder,
        rawJsonValue: row.rawJsonValue,
        value: _decodeJsonValue(type: row.type, jsonValue: row.rawJsonValue),
        children: children,
      );
    }

    return rootRows.map(buildNode).toList(growable: false);
  }

  Object? _decodeJsonValue({
    required PersonalDatabaseValueType type,
    required String jsonValue,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonValue);
    } catch (_) {
      decoded = null;
    }

    return switch (type) {
      PersonalDatabaseValueType.string => decoded is String ? decoded : '',
      PersonalDatabaseValueType.number => decoded is num ? decoded : 0,
      PersonalDatabaseValueType.boolean => decoded is bool ? decoded : false,
      PersonalDatabaseValueType.nullType => null,
      PersonalDatabaseValueType.list => decoded is List ? decoded : const [],
      PersonalDatabaseValueType.object =>
        decoded is Map ? decoded : const <String, Object?>{},
    };
  }

  String _normalizeJsonValue({
    required PersonalDatabaseValueType type,
    required String jsonValue,
  }) {
    if (type == PersonalDatabaseValueType.nullType) {
      return 'null';
    }

    Object? decoded;
    try {
      decoded = jsonDecode(jsonValue);
    } catch (_) {
      decoded = null;
    }

    return switch (type) {
      PersonalDatabaseValueType.string => jsonEncode(
        decoded is String ? decoded : (decoded?.toString() ?? ''),
      ),
      PersonalDatabaseValueType.number => jsonEncode(
        decoded is num ? decoded : num.tryParse('$decoded') ?? 0,
      ),
      PersonalDatabaseValueType.boolean => jsonEncode(
        decoded is bool ? decoded : false,
      ),
      PersonalDatabaseValueType.nullType => 'null',
      PersonalDatabaseValueType.list => jsonEncode(
        decoded is List ? decoded : const [],
      ),
      PersonalDatabaseValueType.object => jsonEncode(
        decoded is Map ? decoded : const <String, Object?>{},
      ),
    };
  }
}

class _FieldRow {
  const _FieldRow({
    required this.id,
    required this.key,
    required this.type,
    required this.isPublic,
    required this.parentFieldId,
    required this.sortOrder,
    required this.rawJsonValue,
  });

  final String id;
  final String key;
  final PersonalDatabaseValueType type;
  final bool isPublic;
  final String? parentFieldId;
  final int sortOrder;
  final String rawJsonValue;
}
