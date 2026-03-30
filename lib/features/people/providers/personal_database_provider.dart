import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/personal_database_field_node.dart';
import '../data/models/personal_database_value_type.dart';
import 'people_database_providers.dart';

typedef PersonalDatabaseFieldViewModel = PersonalDatabaseFieldNode;

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
  }) async {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      return;
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    final sortOrder = await dao.getNextSortOrder(
      actorPersonId: actorPersonId,
      isPublic: isPublic,
      parentFieldId: parentFieldId,
    );

    await dao.createField(
      id: _uuid.v4(),
      actorPersonId: actorPersonId,
      key: trimmedKey,
      type: type,
      isPublic: isPublic,
      jsonValue: _encodeValue(type: type, value: value),
      parentFieldId: parentFieldId,
      sortOrder: sortOrder,
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
    return _ref
        .read(personalDatabaseDaoProvider)
        .updateField(
          fieldId: fieldId,
          actorPersonId: actorPersonId,
          key: key,
          type: type,
          isPublic: isPublic,
          jsonValue: _encodeValue(type: type, value: value),
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
    return _ref.read(personalDatabaseDaoProvider).deleteField(fieldId);
  }

  Future<void> updateRootFieldKey({
    required String actorPersonId,
    required PersonalDatabaseFieldNode field,
    required String key,
  }) {
    return updateField(
      actorPersonId: actorPersonId,
      fieldId: field.id,
      key: key,
      type: field.type,
      isPublic: field.isPublic,
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

  Future<void> deleteNode({
    required String personId,
    required PersonalDatabaseFieldNode field,
    required List<Object> path,
  }) async {
    if (path.isEmpty) {
      await deleteField(field.id);
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

  Future<PersonalDatabaseFieldNode?> _findField({
    required String personId,
    required String fieldId,
  }) async {
    final fieldTree = await _ref
        .read(personalDatabaseDaoProvider)
        .watchFieldTreeForPerson(personId)
        .first;

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

  Object? _deepClone(Object? value) {
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
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
