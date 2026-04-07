import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/people.dart';
import '../../../../core/database/tables/personal_database_fields.dart';
import '../../../../core/database/tables/personal_database_person_fields.dart';
import '../../../../core/database/tables/personal_database_values.dart';
import '../models/personal_database_field_node.dart';
import '../models/personal_database_value_type.dart';

part 'personal_database_dao.g.dart';

@DriftAccessor(
  tables: [
    PersonalDatabaseFields,
    PersonalDatabasePersonFields,
    PersonalDatabaseValues,
    People,
  ],
)
class PersonalDatabaseDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalDatabaseDaoMixin {
  PersonalDatabaseDao(super.db);

  Selectable<PersonalDatabaseField> _orderedFieldLibraryForPersonQuery(
    String personId,
  ) {
    return (select(personalDatabaseFields)
      ..where(
        (table) =>
            table.isPublic.equals(true) | table.ownerPersonId.equals(personId),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
        (table) => OrderingTerm.asc(table.key),
      ]));
  }

  Selectable<PersonalDatabaseField> _orderedFieldLibraryQuery() {
    return (select(personalDatabaseFields)..orderBy([
      (table) => OrderingTerm.asc(table.sortOrder),
      (table) => OrderingTerm.asc(table.createdAt),
      (table) => OrderingTerm.asc(table.key),
    ]));
  }

  Stream<List<PersonalDatabaseFieldNode>> watchFieldLibrary() {
    return _orderedFieldLibraryQuery().watch().map(
      (fields) => _buildFieldTreeFromDefinitions(
        fields.map(_fieldRowFromDefinition).toList(growable: false),
      ),
    );
  }

  Future<List<PersonalDatabaseFieldNode>> getFieldLibrary() async {
    final fields = await _orderedFieldLibraryQuery().get();
    return _buildFieldTreeFromDefinitions(
      fields.map(_fieldRowFromDefinition).toList(growable: false),
    );
  }

  Stream<List<PersonalDatabaseFieldNode>> watchFieldLibraryForPerson(
    String personId,
  ) {
    return _orderedFieldLibraryForPersonQuery(personId).watch().map(
      (fields) => _buildFieldTreeFromDefinitions(
        fields.map(_fieldRowFromDefinition).toList(growable: false),
      ),
    );
  }

  Future<List<PersonalDatabaseFieldNode>> getFieldLibraryForPerson(
    String personId,
  ) async {
    final fields = await _orderedFieldLibraryForPersonQuery(personId).get();
    return _buildFieldTreeFromDefinitions(
      fields.map(_fieldRowFromDefinition).toList(growable: false),
    );
  }

  Stream<Set<String>> watchAssignedFieldIdsForPerson(String personId) {
    return (select(personalDatabasePersonFields)
          ..where((table) => table.personId.equals(personId)))
        .watch()
        .map((rows) => rows.map((row) => row.fieldId).toSet());
  }

  Future<Set<String>> getAssignedFieldIdsForPerson(String personId) async {
    final rows = await (select(
      personalDatabasePersonFields,
    )..where((table) => table.personId.equals(personId))).get();
    return rows.map((row) => row.fieldId).toSet();
  }

  Stream<List<PersonalDatabaseFieldNode>> watchFieldTreeForPerson(
    String personId,
  ) {
    final personFieldsAlias = alias(
      personalDatabasePersonFields,
      'assigned_fields_for_person',
    );
    final valuesAlias = alias(personalDatabaseValues, 'values_for_person');
    final query =
        select(personalDatabaseFields).join([
          innerJoin(
            personFieldsAlias,
            personFieldsAlias.fieldId.equalsExp(personalDatabaseFields.id) &
                personFieldsAlias.personId.equals(personId),
          ),
          leftOuterJoin(
            valuesAlias,
            valuesAlias.fieldId.equalsExp(personalDatabaseFields.id) &
                valuesAlias.personId.equals(personId),
          ),
        ])..orderBy([
          OrderingTerm.asc(personFieldsAlias.sortOrder),
          OrderingTerm.asc(personalDatabaseFields.sortOrder),
          OrderingTerm.asc(personalDatabaseFields.createdAt),
          OrderingTerm.asc(personalDatabaseFields.key),
        ]);

    return query.watch().map(
      (rows) => _buildFieldTree(rows, personFieldsAlias, valuesAlias),
    );
  }

  Future<List<PersonalDatabaseFieldNode>> getFieldTreeForPerson(
    String personId,
  ) async {
    final personFieldsAlias = alias(
      personalDatabasePersonFields,
      'assigned_fields_for_person',
    );
    final valuesAlias = alias(personalDatabaseValues, 'values_for_person');
    final query =
        select(personalDatabaseFields).join([
          innerJoin(
            personFieldsAlias,
            personFieldsAlias.fieldId.equalsExp(personalDatabaseFields.id) &
                personFieldsAlias.personId.equals(personId),
          ),
          leftOuterJoin(
            valuesAlias,
            valuesAlias.fieldId.equalsExp(personalDatabaseFields.id) &
                valuesAlias.personId.equals(personId),
          ),
        ])..orderBy([
          OrderingTerm.asc(personFieldsAlias.sortOrder),
          OrderingTerm.asc(personalDatabaseFields.sortOrder),
          OrderingTerm.asc(personalDatabaseFields.createdAt),
          OrderingTerm.asc(personalDatabaseFields.key),
        ]);

    final rows = await query.get();
    return _buildFieldTree(rows, personFieldsAlias, valuesAlias);
  }

  Future<int> getNextSortOrder({
    required String actorPersonId,
    required bool isPublic,
    String? parentFieldId,
  }) {
    return getNextFieldLibrarySortOrder(parentFieldId: parentFieldId);
  }

  Future<int> getNextFieldLibrarySortOrder({String? parentFieldId}) async {
    final query = selectOnly(personalDatabaseFields)
      ..addColumns([personalDatabaseFields.id.count()]);

    if (parentFieldId == null) {
      query.where(personalDatabaseFields.parentFieldId.isNull());
    } else {
      query.where(personalDatabaseFields.parentFieldId.equals(parentFieldId));
    }

    return query
        .map((row) => row.read(personalDatabaseFields.id.count()) ?? 0)
        .getSingle();
  }

  Future<int> getNextAssignedFieldSortOrder(String personId) async {
    final query = selectOnly(personalDatabasePersonFields)
      ..addColumns([personalDatabasePersonFields.fieldId.count()])
      ..where(personalDatabasePersonFields.personId.equals(personId));

    return query
        .map(
          (row) => row.read(personalDatabasePersonFields.fieldId.count()) ?? 0,
        )
        .getSingle();
  }

  Future<PersonalDatabaseField?> getFieldById(String fieldId) {
    return (select(
      personalDatabaseFields,
    )..where((table) => table.id.equals(fieldId))).getSingleOrNull();
  }

  Future<List<PersonalDatabaseField>> getAllFieldDefinitions() {
    return select(personalDatabaseFields).get();
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
  }) {
    return createFieldAndAssignToPerson(
      id: id,
      personId: actorPersonId,
      key: key,
      type: type,
      isPublic: isPublic,
      ownerPersonId: isPublic ? null : actorPersonId,
      jsonValue: jsonValue,
      parentFieldId: parentFieldId,
      sortOrder: sortOrder,
    );
  }

  Future<void> createFieldDefinition({
    required String id,
    required String key,
    required PersonalDatabaseValueType type,
    required bool isPublic,
    String? ownerPersonId,
    String? parentFieldId,
    int sortOrder = 0,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    await into(personalDatabaseFields).insert(
      PersonalDatabaseFieldsCompanion.insert(
        id: id,
        key: trimmedKey,
        valueType: type.dbKey,
        isPublic: Value(isPublic),
        ownerPersonId: Value(isPublic ? null : ownerPersonId),
        parentFieldId: Value(parentFieldId),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<void> createFieldAndAssignToPerson({
    required String id,
    required String personId,
    required String key,
    required PersonalDatabaseValueType type,
    required String jsonValue,
    bool isPublic = true,
    String? ownerPersonId,
    String? parentFieldId,
    int sortOrder = 0,
    int? assignmentSortOrder,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final normalizedJsonValue = _normalizeJsonValue(
      type: type,
      jsonValue: jsonValue,
    );

    final resolvedAssignmentSortOrder =
        assignmentSortOrder ?? await getNextAssignedFieldSortOrder(personId);

    await transaction(() async {
      await into(personalDatabaseFields).insert(
        PersonalDatabaseFieldsCompanion.insert(
          id: id,
          key: trimmedKey,
          valueType: type.dbKey,
          isPublic: Value(isPublic),
          ownerPersonId: Value(isPublic ? null : ownerPersonId),
          parentFieldId: Value(parentFieldId),
          sortOrder: Value(sortOrder),
        ),
      );

      await into(personalDatabasePersonFields).insertOnConflictUpdate(
        PersonalDatabasePersonFieldsCompanion(
          fieldId: Value(id),
          personId: Value(personId),
          sortOrder: Value(resolvedAssignmentSortOrder),
          createdAt: Value(DateTime.now()),
        ),
      );

      await _upsertFieldValue(
        fieldId: id,
        personId: personId,
        jsonValue: normalizedJsonValue,
      );
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
    await updatePropertyDefinition(fieldId: fieldId, key: key, type: type);
    await updateFieldValueForPerson(
      fieldId: fieldId,
      personId: actorPersonId,
      type: type,
      jsonValue: jsonValue,
    );
  }

  Future<void> updatePropertyDefinition({
    required String fieldId,
    required String key,
    required PersonalDatabaseValueType type,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    await transaction(() async {
      final existing = await getFieldById(fieldId);
      if (existing == null) {
        return;
      }

      final previousType = personalDatabaseValueTypeFromDb(existing.valueType);
      final didChangeType = previousType != type;

      await (update(
        personalDatabaseFields,
      )..where((table) => table.id.equals(fieldId))).write(
        PersonalDatabaseFieldsCompanion(
          key: Value(trimmedKey),
          valueType: Value(type.dbKey),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (!didChangeType) {
        return;
      }

      final existingValues = await (select(
        personalDatabaseValues,
      )..where((table) => table.fieldId.equals(fieldId))).get();

      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          personalDatabaseValues,
          existingValues
              .map(
                (row) => PersonalDatabaseValuesCompanion(
                  fieldId: Value(row.fieldId),
                  personId: Value(row.personId),
                  jsonValue: Value(
                    _normalizeJsonValueAfterTypeChange(
                      previousType: previousType,
                      newType: type,
                      currentJsonValue: row.jsonValue,
                    ),
                  ),
                  updatedAt: Value(DateTime.now()),
                ),
              )
              .toList(growable: false),
        );
      });
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

  Future<void> assignFieldToPerson({
    required String fieldId,
    required String personId,
    String? jsonValue,
  }) async {
    final field = await getFieldById(fieldId);
    if (field == null) {
      return;
    }

    final existingAssignment =
        await (select(personalDatabasePersonFields)
              ..where((table) => table.fieldId.equals(fieldId))
              ..where((table) => table.personId.equals(personId)))
            .getSingleOrNull();
    if (existingAssignment != null) {
      return;
    }

    final type = personalDatabaseValueTypeFromDb(field.valueType);
    final sortOrder = await getNextAssignedFieldSortOrder(personId);

    await transaction(() async {
      await into(personalDatabasePersonFields).insertOnConflictUpdate(
        PersonalDatabasePersonFieldsCompanion(
          fieldId: Value(fieldId),
          personId: Value(personId),
          sortOrder: Value(sortOrder),
          createdAt: Value(DateTime.now()),
        ),
      );

      await _upsertFieldValue(
        fieldId: fieldId,
        personId: personId,
        jsonValue: jsonValue == null
            ? type.defaultJsonValue
            : _normalizeJsonValue(type: type, jsonValue: jsonValue),
      );
    });
  }

  Future<void> removeFieldFromPerson({
    required String fieldId,
    required String personId,
  }) async {
    await transaction(() async {
      await (delete(personalDatabasePersonFields)
            ..where((table) => table.fieldId.equals(fieldId))
            ..where((table) => table.personId.equals(personId)))
          .go();
      await (delete(personalDatabaseValues)
            ..where((table) => table.fieldId.equals(fieldId))
            ..where((table) => table.personId.equals(personId)))
          .go();
    });
  }

  Future<void> removeFieldSubtreeFromPerson({
    required String fieldId,
    required String personId,
  }) async {
    final fieldIds = await _collectDescendantFieldIds(fieldId);
    if (fieldIds.isEmpty) {
      return;
    }

    await transaction(() async {
      await (delete(personalDatabasePersonFields)
            ..where((table) => table.personId.equals(personId))
            ..where((table) => table.fieldId.isIn(fieldIds)))
          .go();
      await (delete(personalDatabaseValues)
            ..where((table) => table.personId.equals(personId))
            ..where((table) => table.fieldId.isIn(fieldIds)))
          .go();
    });
  }

  Future<bool> hasChildDefinitions(String fieldId) async {
    final fieldIds = await _collectDescendantFieldIds(fieldId);
    return fieldIds.length > 1;
  }

  Future<int> countAssignmentsForFieldSubtree(String fieldId) async {
    final fieldIds = await _collectDescendantFieldIds(fieldId);
    if (fieldIds.isEmpty) {
      return 0;
    }

    final countExpression = personalDatabasePersonFields.fieldId.count();
    final query = selectOnly(personalDatabasePersonFields)
      ..addColumns([countExpression])
      ..where(personalDatabasePersonFields.fieldId.isIn(fieldIds));

    return query.map((row) => row.read(countExpression) ?? 0).getSingle();
  }

  Future<Set<String>> getAssignedPersonIdsForFieldSubtree(
    String fieldId,
  ) async {
    final fieldIds = await _collectDescendantFieldIds(fieldId);
    if (fieldIds.isEmpty) {
      return const <String>{};
    }

    final rows = await (select(
      personalDatabasePersonFields,
    )..where((table) => table.fieldId.isIn(fieldIds))).get();
    return rows.map((row) => row.personId).toSet();
  }

  Future<void> deleteField(String fieldId) {
    return deleteFieldDefinition(fieldId);
  }

  Future<void> deleteFieldDefinition(String fieldId) async {
    await transaction(() async {
      final fieldIds = await _collectDescendantFieldIds(fieldId);
      if (fieldIds.isEmpty) {
        return;
      }

      await (delete(
        personalDatabaseValues,
      )..where((table) => table.fieldId.isIn(fieldIds))).go();
      await (delete(
        personalDatabasePersonFields,
      )..where((table) => table.fieldId.isIn(fieldIds))).go();
      await (delete(
        personalDatabaseFields,
      )..where((table) => table.id.isIn(fieldIds))).go();
    });
  }

  Future<void> moveFieldDefinition({
    required String fieldId,
    required String? newParentFieldId,
    required int newSortOrder,
  }) async {
    await transaction(() async {
      final allFields = await select(personalDatabaseFields).get();
      final field = _fieldById(allFields, fieldId);
      if (field == null) {
        throw StateError('Field not found: $fieldId');
      }

      if (newParentFieldId == fieldId) {
        throw StateError('A field cannot be moved into itself');
      }

      final descendantFieldIds = await _collectDescendantFieldIds(fieldId);
      if (newParentFieldId != null &&
          descendantFieldIds.contains(newParentFieldId)) {
        throw StateError('A field cannot be moved into its descendant');
      }

      final newParent = newParentFieldId == null
          ? null
          : _fieldById(allFields, newParentFieldId);
      if (newParentFieldId != null && newParent == null) {
        throw StateError('Target parent not found: $newParentFieldId');
      }

      if (newParent != null &&
          personalDatabaseValueTypeFromDb(newParent.valueType) !=
              PersonalDatabaseValueType.object) {
        throw StateError('Target parent must be an object property');
      }

      if (newParent != null) {
        final isScopeMismatch =
            field.isPublic != newParent.isPublic ||
            (!field.isPublic && field.ownerPersonId != newParent.ownerPersonId);
        if (isScopeMismatch) {
          throw StateError('Cannot move across visibility scopes');
        }
      }

      int compareRows(PersonalDatabaseField a, PersonalDatabaseField b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) {
          return sortCompare;
        }
        final createdAtCompare = a.createdAt.compareTo(b.createdAt);
        if (createdAtCompare != 0) {
          return createdAtCompare;
        }
        return a.key.compareTo(b.key);
      }

      final siblingsByParentId = <String?, List<PersonalDatabaseField>>{};
      for (final current in allFields) {
        siblingsByParentId.putIfAbsent(current.parentFieldId, () => []);
        siblingsByParentId[current.parentFieldId]!.add(current);
      }

      for (final siblings in siblingsByParentId.values) {
        siblings.sort(compareRows);
      }

      final oldParentId = field.parentFieldId;
      final oldSiblings = [
        ...siblingsByParentId[oldParentId] ?? const <PersonalDatabaseField>[],
      ]..removeWhere((candidate) => candidate.id == fieldId);

      final isSameParent = oldParentId == newParentFieldId;
      final targetSiblings =
          isSameParent
                ? oldSiblings
                : [
                    ...siblingsByParentId[newParentFieldId] ??
                        const <PersonalDatabaseField>[],
                  ]
            ..removeWhere((candidate) => candidate.id == fieldId);

      final insertIndex = newSortOrder.clamp(0, targetSiblings.length);
      targetSiblings.insert(insertIndex, field);

      final now = DateTime.now();

      await batch((batch) {
        for (var index = 0; index < targetSiblings.length; index++) {
          final current = targetSiblings[index];
          batch.update(
            personalDatabaseFields,
            PersonalDatabaseFieldsCompanion(
              parentFieldId: current.id == fieldId
                  ? Value(newParentFieldId)
                  : const Value.absent(),
              sortOrder: Value(index),
              updatedAt: Value(now),
            ),
            where: (table) => table.id.equals(current.id),
          );
        }

        if (!isSameParent) {
          for (var index = 0; index < oldSiblings.length; index++) {
            final current = oldSiblings[index];
            batch.update(
              personalDatabaseFields,
              PersonalDatabaseFieldsCompanion(
                sortOrder: Value(index),
                updatedAt: Value(now),
              ),
              where: (table) => table.id.equals(current.id),
            );
          }
        }
      });
    });
  }

  Future<void> updateFieldAssignmentSortOrder({
    required String personId,
    required String fieldId,
    required int sortOrder,
  }) {
    return (update(personalDatabasePersonFields)
          ..where((table) => table.personId.equals(personId))
          ..where((table) => table.fieldId.equals(fieldId)))
        .write(
          PersonalDatabasePersonFieldsCompanion(sortOrder: Value(sortOrder)),
        );
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

  PersonalDatabaseField? _fieldById(
    List<PersonalDatabaseField> fields,
    String fieldId,
  ) {
    for (final field in fields) {
      if (field.id == fieldId) {
        return field;
      }
    }
    return null;
  }

  Future<PersonalDatabaseField?> getChildFieldByKey({
    required String parentFieldId,
    required String key,
  }) {
    return (select(personalDatabaseFields)
          ..where((table) => table.parentFieldId.equals(parentFieldId))
          ..where((table) => table.key.equals(key.trim())))
        .getSingleOrNull();
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

  _FieldRow _fieldRowFromDefinition(PersonalDatabaseField field) {
    final type = personalDatabaseValueTypeFromDb(field.valueType);
    return _FieldRow(
      id: field.id,
      key: field.key,
      type: type,
      isPublic: field.isPublic,
      parentFieldId: field.parentFieldId,
      sortOrder: field.sortOrder,
      rawJsonValue: type.defaultJsonValue,
    );
  }

  List<PersonalDatabaseFieldNode> _buildFieldTree(
    List<TypedResult> rows,
    $PersonalDatabasePersonFieldsTable personFieldsAlias,
    $PersonalDatabaseValuesTable valuesAlias,
  ) {
    final fieldRows = <String, _FieldRow>{};
    for (final row in rows) {
      final field = row.readTable(personalDatabaseFields);
      final personField = row.readTable(personFieldsAlias);
      final valueForPerson = row.readTableOrNull(valuesAlias);
      final type = personalDatabaseValueTypeFromDb(field.valueType);
      fieldRows[field.id] = _FieldRow(
        id: field.id,
        key: field.key,
        type: type,
        isPublic: field.isPublic,
        parentFieldId: field.parentFieldId,
        sortOrder: field.parentFieldId == null
            ? personField.sortOrder
            : field.sortOrder,
        rawJsonValue: valueForPerson?.jsonValue ?? type.defaultJsonValue,
      );
    }

    return _buildFieldTreeFromRows(fieldRows.values);
  }

  List<PersonalDatabaseFieldNode> _buildFieldTreeFromDefinitions(
    List<_FieldRow> rows,
  ) {
    return _buildFieldTreeFromRows(rows);
  }

  List<PersonalDatabaseFieldNode> _buildFieldTreeFromRows(
    Iterable<_FieldRow> rows,
  ) {
    final fieldRows = <String, _FieldRow>{};
    final childrenByParentId = <String, List<_FieldRow>>{};

    for (final row in rows) {
      fieldRows[row.id] = row;
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

  String _normalizeJsonValueAfterTypeChange({
    required PersonalDatabaseValueType previousType,
    required PersonalDatabaseValueType newType,
    required String currentJsonValue,
  }) {
    final decodedValue = _decodeJsonValue(
      type: previousType,
      jsonValue: currentJsonValue,
    );
    return _encodeValue(type: newType, value: decodedValue);
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

  String _encodeValue({
    required PersonalDatabaseValueType type,
    required Object? value,
  }) {
    return switch (type) {
      PersonalDatabaseValueType.string => jsonEncode(
        value == null ? '' : '$value',
      ),
      PersonalDatabaseValueType.number => jsonEncode(
        value is num ? value : num.tryParse('${value ?? ''}') ?? 0,
      ),
      PersonalDatabaseValueType.boolean => jsonEncode(value == true),
      PersonalDatabaseValueType.nullType => 'null',
      PersonalDatabaseValueType.list => jsonEncode(
        value is List<dynamic> ? value : const <Object?>[],
      ),
      PersonalDatabaseValueType.object => jsonEncode(
        value is Map<String, dynamic> ? value : const <String, Object?>{},
      ),
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
