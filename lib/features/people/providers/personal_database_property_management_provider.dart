import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/personal_database_field_node.dart';
import '../data/models/personal_database_value_type.dart';
import 'people_database_providers.dart';
import 'personal_database_provider.dart';

final personalDatabasePropertyManagementActionsProvider =
    Provider<PersonalDatabasePropertyManagementActions>((ref) {
      return PersonalDatabasePropertyManagementActions(ref);
    });

class PersonalDatabasePropertyManagementActions {
  PersonalDatabasePropertyManagementActions(this._ref);

  final Ref _ref;

  Future<List<PersonalDatabaseFieldNode>> getPropertyLibrary() {
    return _ref.read(personalDatabaseDaoProvider).getFieldLibrary();
  }

  Future<void> renamePropertyDefinition({
    required String fieldId,
    required String key,
  }) async {
    final dao = _ref.read(personalDatabaseDaoProvider);
    final field = await dao.getFieldById(fieldId);
    if (field == null) {
      throw StateError('Field not found: $fieldId');
    }

    await _ref
        .read(personalDatabaseActionsProvider)
        .updateManagedPropertyDefinition(
          fieldId: fieldId,
          key: key,
          type: personalDatabaseValueTypeFromDb(field.valueType),
        );
  }

  Future<bool> canRetypePropertyDefinition({
    required String fieldId,
    required PersonalDatabaseValueType nextType,
  }) async {
    final dao = _ref.read(personalDatabaseDaoProvider);
    final field = await dao.getFieldById(fieldId);
    if (field == null) {
      return false;
    }

    final currentType = personalDatabaseValueTypeFromDb(field.valueType);
    if (currentType != PersonalDatabaseValueType.object ||
        nextType == PersonalDatabaseValueType.object) {
      return true;
    }

    return !await dao.hasChildDefinitions(fieldId);
  }

  Future<void> retypePropertyDefinition({
    required String fieldId,
    required PersonalDatabaseValueType nextType,
  }) async {
    if (!await canRetypePropertyDefinition(
      fieldId: fieldId,
      nextType: nextType,
    )) {
      throw StateError('Cannot retype an object property with children');
    }

    final dao = _ref.read(personalDatabaseDaoProvider);
    final field = await dao.getFieldById(fieldId);
    if (field == null) {
      throw StateError('Field not found: $fieldId');
    }

    await _ref
        .read(personalDatabaseActionsProvider)
        .updateManagedPropertyDefinition(
          fieldId: fieldId,
          key: field.key,
          type: nextType,
        );
  }

  Future<bool> canDeletePropertyDefinition(String fieldId) async {
    final dao = _ref.read(personalDatabaseDaoProvider);
    return await dao.countAssignmentsForFieldSubtree(fieldId) == 0;
  }

  Future<void> deletePropertyDefinition(String fieldId) async {
    if (!await canDeletePropertyDefinition(fieldId)) {
      throw StateError('Cannot delete a property that is still in use');
    }

    await _ref
        .read(personalDatabaseActionsProvider)
        .deleteManagedPropertyDefinition(fieldId);
  }

  Future<String?> createPropertyDefinition({
    required String key,
    required PersonalDatabaseValueType type,
    String? parentFieldId,
  }) {
    return _ref
        .read(personalDatabaseActionsProvider)
        .createManagedPropertyDefinition(
          key: key,
          type: type,
          parentFieldId: parentFieldId,
        );
  }

  Future<void> movePropertyDefinition({
    required String fieldId,
    required String? newParentFieldId,
    required int newSortOrder,
  }) {
    return _ref
        .read(personalDatabaseActionsProvider)
        .moveManagedProperty(
          fieldId: fieldId,
          newParentFieldId: newParentFieldId,
          newIndex: newSortOrder,
        );
  }
}
