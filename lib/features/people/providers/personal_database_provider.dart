import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../data/models/personal_database_field_node.dart';
import '../data/models/personal_database_management_error.dart';
import '../data/models/personal_database_media_value.dart';
import '../data/models/personal_database_mention.dart';
import '../data/models/personal_database_value_type.dart';
import 'people_database_providers.dart';

typedef PersonalDatabaseFieldViewModel = PersonalDatabaseFieldNode;
typedef PersonalDatabaseLibraryFieldViewModel = PersonalDatabaseFieldNode;

final personalDatabaseLibraryProvider =
    StreamProvider<List<PersonalDatabaseFieldNode>>((ref) {
      return ref.watch(personalDatabaseDaoProvider).watchFieldLibrary();
    });

final personalDatabaseFieldTreeProvider =
    StreamProvider.family<List<PersonalDatabaseFieldNode>, String>((
      ref,
      personId,
    ) {
      return ref
          .watch(personalDatabaseDaoProvider)
          .watchFieldTreeForPerson(personId);
    });

final personalDatabaseFieldsProvider = personalDatabaseFieldTreeProvider;

final personalDatabaseAssignedFieldIdsProvider =
    StreamProvider.family<Set<String>, String>((ref, personId) {
      return ref
          .watch(personalDatabaseDaoProvider)
          .watchAssignedFieldIdsForPerson(personId);
    });

final personalDatabaseMentionCodecProvider =
    Provider<PersonalDatabaseMentionCodec>((ref) {
      return const PersonalDatabaseMentionCodec();
    });

final personalDatabaseManagementLibraryProvider =
    StreamProvider<List<PersonalDatabaseFieldNode>>((ref) {
      return ref.watch(personalDatabaseDaoProvider).watchFieldLibrary();
    });

final personalDatabaseActionsProvider = Provider<PersonalDatabaseActions>((
  ref,
) {
  return PersonalDatabaseActions(ref: ref, uuid: const Uuid());
});

class PersonalDatabaseActions {
  PersonalDatabaseActions({required Ref ref, required Uuid uuid})
    : _ref = ref,
      _uuid = uuid;

  final Ref _ref;
  final Uuid _uuid;

  Future<void> createField({
    required String actorPersonId,
    required String key,
    required PersonalDatabaseValueType type,
    required bool isPublic,
    required Object? value,
    String? parentFieldId,
  }) {
    return createPropertyAndAssignToPerson(
      personId: actorPersonId,
      key: key,
      type: type,
      isPublic: isPublic,
      value: value,
      parentFieldId: parentFieldId,
    );
  }

  Future<void> updateField({
    required String actorPersonId,
    required String fieldId,
    required String key,
    required PersonalDatabaseValueType type,
    required bool isPublic,
    required Object? value,
  }) {
    return updatePropertyAndValueForPerson(
      personId: actorPersonId,
      fieldId: fieldId,
      key: key,
      type: type,
      value: value,
    );
  }

  Future<void> updateFieldValue({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required Object? value,
  }) {
    return _ref
        .read(personalDatabaseDaoProvider)
        .updateFieldValueForPerson(
          fieldId: field.id,
          personId: personId,
          type: field.type,
          jsonValue: _encodeValue(type: field.type, value: value),
        );
  }

  Future<void> deleteField(String fieldId) {
    return deletePropertyDefinition(fieldId);
  }

  Future<void> createPropertyAndAssignToPerson({
    required String personId,
    required String key,
    required PersonalDatabaseValueType type,
    bool isPublic = true,
    required Object? value,
    String? parentFieldId,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    final sortOrder = await dao.getNextFieldLibrarySortOrder(
      parentFieldId: parentFieldId,
    );
    final assignmentSortOrder = await dao.getNextAssignedFieldSortOrder(
      personId,
    );

    await dao.createFieldAndAssignToPerson(
      id: _uuid.v4(),
      personId: personId,
      key: trimmedKey,
      type: type,
      isPublic: isPublic,
      ownerPersonId: isPublic ? null : personId,
      jsonValue: _encodeValue(type: type, value: value),
      parentFieldId: parentFieldId,
      sortOrder: sortOrder,
      assignmentSortOrder: assignmentSortOrder,
    );
  }

  Future<void> assignFieldToPerson({
    required String personId,
    required String fieldId,
    Object? value,
  }) {
    final dao = _ref.read(personalDatabaseDaoProvider);
    return dao.assignFieldToPerson(
      fieldId: fieldId,
      personId: personId,
      jsonValue: value == null ? null : jsonEncode(value),
    );
  }

  Future<void> removeFieldFromPerson({
    required String personId,
    required String fieldId,
  }) {
    return _ref
        .read(personalDatabaseDaoProvider)
        .removeFieldFromPerson(fieldId: fieldId, personId: personId);
  }

  Future<void> removeChildPropertyFromPerson({
    required String personId,
    required String fieldId,
  }) {
    return _ref
        .read(personalDatabaseDaoProvider)
        .removeFieldSubtreeFromPerson(fieldId: fieldId, personId: personId);
  }

  Future<void> updatePropertyDefinition({
    required String fieldId,
    required String key,
    required PersonalDatabaseValueType type,
  }) {
    return _ref
        .read(personalDatabaseDaoProvider)
        .updatePropertyDefinition(fieldId: fieldId, key: key, type: type);
  }

  Future<void> deletePropertyDefinition(String fieldId) {
    return _ref
        .read(personalDatabaseDaoProvider)
        .deleteFieldDefinition(fieldId);
  }

  Future<void> updateManagedPropertyDefinition({
    required String fieldId,
    required String key,
    required PersonalDatabaseValueType type,
  }) async {
    final library = await _ref
        .read(personalDatabaseDaoProvider)
        .getFieldLibrary();
    final field = _findFieldInNodes(nodes: library, fieldId: fieldId);
    if (field == null) {
      return;
    }

    if (field.type == PersonalDatabaseValueType.object &&
        field.children.isNotEmpty &&
        type != PersonalDatabaseValueType.object) {
      throw const PersonalDatabaseManagementException(
        PersonalDatabaseManagementErrorCode.objectWithChildrenCannotRetype,
      );
    }

    await updatePropertyDefinition(fieldId: fieldId, key: key, type: type);
  }

  Future<void> deleteManagedPropertyDefinition(String fieldId) async {
    final assignmentCount = await _ref
        .read(personalDatabaseDaoProvider)
        .countAssignmentsForFieldSubtree(fieldId);
    if (assignmentCount > 0) {
      throw const PersonalDatabaseManagementException(
        PersonalDatabaseManagementErrorCode.propertyInUseCannotDelete,
      );
    }

    await deletePropertyDefinition(fieldId);
  }

  Future<String?> createManagedPropertyDefinition({
    required String key,
    required PersonalDatabaseValueType type,
    String? parentFieldId,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return null;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    bool isPublic = true;
    String? ownerPersonId;

    if (parentFieldId != null) {
      final parentDefinition = await dao.getFieldById(parentFieldId);
      if (parentDefinition == null) {
        return null;
      }
      isPublic = parentDefinition.isPublic;
      ownerPersonId = parentDefinition.ownerPersonId;
    }

    final sortOrder = await dao.getNextFieldLibrarySortOrder(
      parentFieldId: parentFieldId,
    );
    final fieldId = _uuid.v4();

    await dao.createFieldDefinition(
      id: fieldId,
      key: trimmedKey,
      type: type,
      isPublic: isPublic,
      ownerPersonId: ownerPersonId,
      parentFieldId: parentFieldId,
      sortOrder: sortOrder,
    );

    return fieldId;
  }

  Future<void> moveManagedProperty({
    required String fieldId,
    required String? newParentFieldId,
    required int newIndex,
  }) async {
    final dao = _ref.read(personalDatabaseDaoProvider);
    final fieldsBeforeMove = await dao.getAllFieldDefinitions();
    final fieldsByIdBeforeMove = {
      for (final field in fieldsBeforeMove) field.id: field,
    };
    final affectedPersonIds = await dao.getAssignedPersonIdsForFieldSubtree(
      fieldId,
    );
    final oldAncestorIds = _ancestorIdsForField(
      fieldId: fieldId,
      fieldsById: fieldsByIdBeforeMove,
    );
    final library = await dao.getFieldLibrary();
    final movingField = _findFieldInNodes(nodes: library, fieldId: fieldId);
    if (movingField == null) {
      return;
    }

    if (newParentFieldId != null) {
      final targetParent = _findFieldInNodes(
        nodes: library,
        fieldId: newParentFieldId,
      );
      if (targetParent == null) {
        return;
      }
      if (targetParent.type != PersonalDatabaseValueType.object) {
        throw const PersonalDatabaseManagementException(
          PersonalDatabaseManagementErrorCode.moveTargetMustBeObject,
        );
      }
      if (targetParent.id == movingField.id ||
          _containsField(movingField, targetParent.id)) {
        throw const PersonalDatabaseManagementException(
          PersonalDatabaseManagementErrorCode.moveTargetCannotBeDescendant,
        );
      }

      final movingDefinition = await dao.getFieldById(fieldId);
      final targetDefinition = await dao.getFieldById(newParentFieldId);
      if (movingDefinition == null || targetDefinition == null) {
        return;
      }
      if (movingDefinition.isPublic != targetDefinition.isPublic ||
          movingDefinition.ownerPersonId != targetDefinition.ownerPersonId) {
        throw const PersonalDatabaseManagementException(
          PersonalDatabaseManagementErrorCode.moveScopeConflict,
        );
      }
    }

    await dao.moveFieldDefinition(
      fieldId: fieldId,
      newParentFieldId: newParentFieldId,
      newSortOrder: newIndex,
    );

    final fieldsAfterMove = await dao.getAllFieldDefinitions();
    final fieldsByIdAfterMove = {
      for (final field in fieldsAfterMove) field.id: field,
    };
    final newAncestorIds = _ancestorIdsForField(
      fieldId: fieldId,
      fieldsById: fieldsByIdAfterMove,
    );

    await _ensureAncestorAssignmentsForSubtreeUsers(
      personIds: affectedPersonIds,
      ancestorIds: newAncestorIds,
    );
    await _removeStaleAncestorAssignments(
      personIds: affectedPersonIds,
      staleAncestorIds: oldAncestorIds
          .where((ancestorId) => !newAncestorIds.contains(ancestorId))
          .toList(growable: false),
    );
    await _syncRootAssignmentSortOrders(
      personIds: affectedPersonIds,
      fieldsById: fieldsByIdAfterMove,
    );
  }

  Future<void> updatePropertyAndValueForPerson({
    required String personId,
    required String fieldId,
    required String key,
    required PersonalDatabaseValueType type,
    required Object? value,
  }) async {
    await updatePropertyDefinition(fieldId: fieldId, key: key, type: type);
    await _ref
        .read(personalDatabaseDaoProvider)
        .updateFieldValueForPerson(
          fieldId: fieldId,
          personId: personId,
          type: type,
          jsonValue: _encodeValue(type: type, value: value),
        );
  }

  Future<void> updateRootFieldKey({
    required String actorPersonId,
    required PersonalDatabaseFieldNode field,
    required String key,
  }) {
    return updatePropertyAndValueForPerson(
      personId: actorPersonId,
      fieldId: field.id,
      key: key,
      type: field.type,
      value: field.value,
    );
  }

  Future<void> upsertRootValue({
    required String personId,
    required String fieldId,
    required Object? value,
  }) async {
    final field = await _findField(personId: personId, fieldId: fieldId);
    if (field == null) {
      return;
    }

    return updateFieldValue(personId: personId, field: field, value: value);
  }

  Future<void> updateNodeValue({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required List<Object> path,
    required Object? value,
  }) async {
    if (path.isEmpty) {
      await updateFieldValue(personId: personId, field: field, value: value);
      return;
    }

    final root = _deepClone(field.value);
    _writeNodeByPath(root: root, path: path, value: value);

    await updateFieldValue(personId: personId, field: field, value: root);
  }

  Future<void> renameObjectKey({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required List<Object> path,
    required String newKey,
  }) async {
    if (path.isEmpty || path.last is! String) {
      return;
    }

    final trimmedKey = newKey.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final root = _deepClone(field.value);
    final parentPath = path.sublist(0, path.length - 1);
    final parent = _readNodeByPath(root: root, path: parentPath);
    if (parent is! Map<String, dynamic>) {
      return;
    }

    final oldKey = path.last as String;
    if (oldKey == trimmedKey || !parent.containsKey(oldKey)) {
      return;
    }
    if (parent.containsKey(trimmedKey)) {
      throw StateError('Duplicate object key: $trimmedKey');
    }

    final movedValue = parent.remove(oldKey);
    parent[trimmedKey] = movedValue;

    await updateFieldValue(personId: personId, field: field, value: root);
  }

  Future<void> addChildNode({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required List<Object> parentPath,
    String? key,
    required Object? value,
  }) async {
    final root = _deepClone(field.value);
    final parent = _readNodeByPath(root: root, path: parentPath);

    if (parent is Map<String, dynamic>) {
      final trimmedKey = key?.trim() ?? '';
      if (trimmedKey.isEmpty) {
        return;
      }
      if (parent.containsKey(trimmedKey)) {
        throw StateError('Duplicate object key: $trimmedKey');
      }
      parent[trimmedKey] = value;
    } else if (parent is List<dynamic>) {
      parent.add(value);
    } else {
      return;
    }

    await updateFieldValue(personId: personId, field: field, value: root);
  }

  Future<String?> createChildPropertyForPerson({
    required String personId,
    required PersonalDatabaseFieldNode parentField,
    required String key,
    required PersonalDatabaseValueType type,
    required Object? value,
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return null;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    final parentDefinition = await dao.getFieldById(parentField.id);
    if (parentDefinition == null) {
      return null;
    }

    final existingChild = await dao.getChildFieldByKey(
      parentFieldId: parentField.id,
      key: trimmedKey,
    );

    if (existingChild != null) {
      final assignedFieldIds = await dao.getAssignedFieldIdsForPerson(personId);
      if (assignedFieldIds.contains(existingChild.id)) {
        throw StateError('Duplicate object key: $trimmedKey');
      }

      final existingType = personalDatabaseValueTypeFromDb(
        existingChild.valueType,
      );
      await dao.assignFieldToPerson(
        fieldId: existingChild.id,
        personId: personId,
        jsonValue: _encodeValue(type: existingType, value: value),
      );
      await ensureObjectSubtreeDefinitionsForField(
        personId: personId,
        fieldId: existingChild.id,
        rawValueOverride: value,
      );
      return existingChild.id;
    }

    final sortOrder = await dao.getNextFieldLibrarySortOrder(
      parentFieldId: parentField.id,
    );
    final assignmentSortOrder = await dao.getNextAssignedFieldSortOrder(
      personId,
    );
    final fieldId = _uuid.v4();

    await dao.createFieldAndAssignToPerson(
      id: fieldId,
      personId: personId,
      key: trimmedKey,
      type: type,
      isPublic: parentDefinition.isPublic,
      ownerPersonId: parentDefinition.ownerPersonId,
      jsonValue: _encodeValue(type: type, value: value),
      parentFieldId: parentField.id,
      sortOrder: sortOrder,
      assignmentSortOrder: assignmentSortOrder,
    );

    await ensureObjectSubtreeDefinitionsForField(
      personId: personId,
      fieldId: fieldId,
      rawValueOverride: value,
    );
    return fieldId;
  }

  Future<void> ensureObjectSubtreeDefinitions({
    required String personId,
  }) async {
    final fieldTree = await _ref
        .read(personalDatabaseDaoProvider)
        .getFieldTreeForPerson(personId);

    for (final field in fieldTree) {
      await _ensureObjectSubtreeDefinitionsForNode(
        personId: personId,
        field: field,
      );
    }
  }

  Future<void> ensureObjectSubtreeDefinitionsForField({
    required String personId,
    required String fieldId,
    Object? rawValueOverride,
  }) async {
    final field = await _findField(personId: personId, fieldId: fieldId);
    if (field == null) {
      return;
    }

    await _ensureObjectSubtreeDefinitionsForNode(
      personId: personId,
      field: field,
      rawValueOverride: rawValueOverride,
    );
  }

  Future<void> deleteNode({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required List<Object> path,
  }) async {
    if (path.isEmpty) {
      await removeFieldFromPerson(personId: personId, fieldId: field.id);
      return;
    }

    final root = _deepClone(field.value);
    final parentPath = path.sublist(0, path.length - 1);
    final parent = _readNodeByPath(root: root, path: parentPath);
    final target = path.last;

    if (target is String && parent is Map<String, dynamic>) {
      parent.remove(target);
    } else if (target is int && parent is List<dynamic>) {
      if (target < 0 || target >= parent.length) {
        return;
      }
      parent.removeAt(target);
    } else {
      return;
    }

    await updateFieldValue(personId: personId, field: field, value: root);
  }

  Future<void> _ensureObjectSubtreeDefinitionsForNode({
    required String personId,
    required PersonalDatabaseFieldNode field,
    Object? rawValueOverride,
  }) async {
    if (field.type == PersonalDatabaseValueType.object) {
      final rawMap = _asStringKeyedMap(rawValueOverride ?? field.value);
      if (rawMap.isNotEmpty) {
        final childrenByKey = {
          for (final child in field.children) child.key: child,
        };
        final dao = _ref.read(personalDatabaseDaoProvider);

        for (final entry in rawMap.entries) {
          var childNode = childrenByKey[entry.key];
          if (childNode == null) {
            final existingDefinition = await dao.getChildFieldByKey(
              parentFieldId: field.id,
              key: entry.key,
            );
            if (existingDefinition != null) {
              final existingType = personalDatabaseValueTypeFromDb(
                existingDefinition.valueType,
              );
              await dao.assignFieldToPerson(
                fieldId: existingDefinition.id,
                personId: personId,
                jsonValue: _encodeValue(type: existingType, value: entry.value),
              );
              childNode = await _findField(
                personId: personId,
                fieldId: existingDefinition.id,
              );
            } else {
              final createdFieldId = await createChildPropertyForPerson(
                personId: personId,
                parentField: field,
                key: entry.key,
                type: personalDatabaseValueTypeFromValue(entry.value),
                value: entry.value,
              );
              if (createdFieldId != null) {
                childNode = await _findField(
                  personId: personId,
                  fieldId: createdFieldId,
                );
              }
            }
          }

          if (childNode != null) {
            await _ensureObjectSubtreeDefinitionsForNode(
              personId: personId,
              field: childNode,
              rawValueOverride: entry.value,
            );
          }
        }

        await _ref
            .read(personalDatabaseDaoProvider)
            .updateFieldValueForPerson(
              fieldId: field.id,
              personId: personId,
              type: PersonalDatabaseValueType.object,
              jsonValue: PersonalDatabaseValueType.object.defaultJsonValue,
            );
      }
    }

    for (final child in field.children) {
      await _ensureObjectSubtreeDefinitionsForNode(
        personId: personId,
        field: child,
      );
    }
  }

  Future<PersonalDatabaseFieldNode?> _findField({
    required String personId,
    required String fieldId,
  }) async {
    final fieldTree = await _ref
        .read(personalDatabaseDaoProvider)
        .getFieldTreeForPerson(personId);

    PersonalDatabaseFieldNode? visit(List<PersonalDatabaseFieldNode> nodes) {
      for (final node in nodes) {
        if (node.id == fieldId) {
          return node;
        }
        final child = visit(node.children);
        if (child != null) {
          return child;
        }
      }
      return null;
    }

    return visit(fieldTree);
  }

  PersonalDatabaseFieldNode? _findFieldInNodes({
    required List<PersonalDatabaseFieldNode> nodes,
    required String fieldId,
  }) {
    for (final node in nodes) {
      if (node.id == fieldId) {
        return node;
      }
      final child = _findFieldInNodes(nodes: node.children, fieldId: fieldId);
      if (child != null) {
        return child;
      }
    }
    return null;
  }

  bool _containsField(PersonalDatabaseFieldNode root, String fieldId) {
    for (final child in root.children) {
      if (child.id == fieldId || _containsField(child, fieldId)) {
        return true;
      }
    }
    return false;
  }

  List<String> _ancestorIdsForField({
    required String fieldId,
    required Map<String, PersonalDatabaseField> fieldsById,
  }) {
    final ancestorIds = <String>[];
    var cursor = fieldsById[fieldId]?.parentFieldId;
    while (cursor != null) {
      ancestorIds.add(cursor);
      cursor = fieldsById[cursor]?.parentFieldId;
    }
    return ancestorIds;
  }

  Future<void> _ensureAncestorAssignmentsForSubtreeUsers({
    required Set<String> personIds,
    required List<String> ancestorIds,
  }) async {
    if (personIds.isEmpty || ancestorIds.isEmpty) {
      return;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    for (final personId in personIds) {
      for (final ancestorId in ancestorIds.reversed) {
        await dao.assignFieldToPerson(fieldId: ancestorId, personId: personId);
      }
    }
  }

  Future<void> _removeStaleAncestorAssignments({
    required Set<String> personIds,
    required List<String> staleAncestorIds,
  }) async {
    if (personIds.isEmpty || staleAncestorIds.isEmpty) {
      return;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    for (final personId in personIds) {
      for (final ancestorId in staleAncestorIds) {
        final fieldTree = await dao.getFieldTreeForPerson(personId);
        final ancestor = _findFieldInNodes(
          nodes: fieldTree,
          fieldId: ancestorId,
        );
        if (ancestor == null ||
            ancestor.children.isNotEmpty ||
            !_isEmptyContainerNode(ancestor)) {
          continue;
        }
        await dao.removeFieldFromPerson(
          fieldId: ancestorId,
          personId: personId,
        );
      }
    }
  }

  bool _isEmptyContainerNode(PersonalDatabaseFieldNode field) {
    if (field.type == PersonalDatabaseValueType.object) {
      return _asStringKeyedMap(field.value).isEmpty;
    }
    if (field.type == PersonalDatabaseValueType.list) {
      final value = field.value;
      return value is! List || value.isEmpty;
    }
    return false;
  }

  Future<void> _syncRootAssignmentSortOrders({
    required Set<String> personIds,
    required Map<String, PersonalDatabaseField> fieldsById,
  }) async {
    if (personIds.isEmpty) {
      return;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    final rootFields =
        fieldsById.values.where((field) => field.parentFieldId == null).toList()
          ..sort((left, right) {
            final sortCompare = left.sortOrder.compareTo(right.sortOrder);
            if (sortCompare != 0) {
              return sortCompare;
            }
            final createdAtCompare = left.createdAt.compareTo(right.createdAt);
            if (createdAtCompare != 0) {
              return createdAtCompare;
            }
            return left.key.compareTo(right.key);
          });
    final rootIndexById = {
      for (var index = 0; index < rootFields.length; index++)
        rootFields[index].id: index,
    };

    for (final personId in personIds) {
      final assignedFieldIds = await dao.getAssignedFieldIdsForPerson(personId);
      final orderedRootIds =
          assignedFieldIds
              .where(rootIndexById.containsKey)
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  rootIndexById[left]!.compareTo(rootIndexById[right]!),
            );

      for (var index = 0; index < orderedRootIds.length; index++) {
        await dao.updateFieldAssignmentSortOrder(
          personId: personId,
          fieldId: orderedRootIds[index],
          sortOrder: index,
        );
      }
    }
  }

  Object? _deepClone(Object? value) {
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
  }

  Map<String, Object?> _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return {for (final entry in value.entries) '${entry.key}': entry.value};
    }
    return const <String, Object?>{};
  }

  Object? _readNodeByPath({required Object? root, required List<Object> path}) {
    Object? current = root;
    for (final segment in path) {
      if (segment is String && current is Map<String, dynamic>) {
        current = current[segment];
        continue;
      }
      if (segment is int && current is List<dynamic>) {
        if (segment < 0 || segment >= current.length) {
          throw StateError('JSON path index out of range');
        }
        current = current[segment];
        continue;
      }
      throw StateError('Invalid JSON path segment');
    }
    return current;
  }

  void _writeNodeByPath({
    required Object? root,
    required List<Object> path,
    required Object? value,
  }) {
    if (path.isEmpty) {
      throw StateError('Root path should be handled separately');
    }

    final parent = _readNodeByPath(
      root: root,
      path: path.sublist(0, path.length - 1),
    );
    final target = path.last;
    if (target is String && parent is Map<String, dynamic>) {
      parent[target] = value;
      return;
    }
    if (target is int && parent is List<dynamic>) {
      if (target < 0 || target >= parent.length) {
        throw StateError('JSON path index out of range');
      }
      parent[target] = value;
      return;
    }

    throw StateError('Invalid JSON path segment');
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
      PersonalDatabaseValueType.media => jsonEncode(
        personalDatabaseMediaValueFromObject(value).toJson(),
      ),
      PersonalDatabaseValueType.nullType => 'null',
      PersonalDatabaseValueType.list => jsonEncode(
        value is List<dynamic> ? value : const <Object?>[],
      ),
      PersonalDatabaseValueType.object => jsonEncode(
        value is Map<String, dynamic> ? value : const <String, Object?>{},
      ),
    };
  }
}
