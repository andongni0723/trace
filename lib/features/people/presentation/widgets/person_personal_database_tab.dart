import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../data/models/personal_database_field_node.dart';
import '../../data/models/personal_database_value_type.dart';
import '../../providers/personal_database_provider.dart';
import 'personal_database_editor.dart';
import 'personal_database_field_sheet.dart';

class PersonPersonalDatabaseTab extends ConsumerStatefulWidget {
  const PersonPersonalDatabaseTab({
    required this.personId,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 32),
    super.key,
  });

  final String personId;
  final EdgeInsets padding;

  @override
  ConsumerState<PersonPersonalDatabaseTab> createState() =>
      _PersonPersonalDatabaseTabState();
}

class _PersonPersonalDatabaseTabState
    extends ConsumerState<PersonPersonalDatabaseTab> {
  final Set<String> _expandedNodeIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(
      personalDatabaseFieldTreeProvider(widget.personId),
    );

    return fieldsAsync.when(
      data: (fields) {
        final fieldsById = {for (final field in fields) field.id: field};
        final rows = _buildRows(fields);

        return Stack(
          children: [
            PersonalDatabaseEditor(
              rows: rows,
              padding: widget.padding.copyWith(
                bottom: widget.padding.bottom + 88,
              ),
              onPressedValue: (row) => _onPressedValue(row, fieldsById),
              onPressedAction: (row, action) {
                _onPressedAction(row, action, fieldsById);
              },
            ),
            PositionedDirectional(
              end: 20,
              bottom: 20,
              child: FloatingActionButton(
                heroTag: 'person-database-add-fab-${widget.personId}',
                onPressed: _handleAddRootField,
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'personTodo.database.loadError'.tr(),
            style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  List<PersonalDatabaseEditorRowData> _buildRows(
    List<PersonalDatabaseFieldNode> fields,
  ) {
    final rows = <PersonalDatabaseEditorRowData>[];
    for (final field in fields) {
      _appendRows(
        rows: rows,
        rootFieldId: field.id,
        path: const [],
        keyLabel: field.key,
        value: field.value,
        depth: 0,
        parentIsList: false,
      );
    }
    return rows;
  }

  void _appendRows({
    required List<PersonalDatabaseEditorRowData> rows,
    required String rootFieldId,
    required List<Object> path,
    required String keyLabel,
    required Object? value,
    required int depth,
    required bool parentIsList,
  }) {
    final valueType = _valueTypeFromValue(value);
    final nodeId = _nodeId(rootFieldId: rootFieldId, path: path);
    final isExpanded = _expandedNodeIds.contains(nodeId);
    final isContainer =
        valueType == PersonalDatabaseValueType.object ||
        valueType == PersonalDatabaseValueType.list;

    rows.add(
      PersonalDatabaseEditorRowData(
        nodeId: nodeId,
        rootFieldId: rootFieldId,
        path: path,
        keyLabel: keyLabel,
        valuePreview: _valuePreview(value),
        rawValue: value,
        valueType: valueType,
        depth: depth,
        isExpanded: isExpanded,
        isContainer: isContainer,
        parentIsList: parentIsList,
      ),
    );

    if (!isContainer || !isExpanded) {
      return;
    }

    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        _appendRows(
          rows: rows,
          rootFieldId: rootFieldId,
          path: [...path, entry.key],
          keyLabel: entry.key,
          value: entry.value,
          depth: depth + 1,
          parentIsList: false,
        );
      }
      return;
    }

    if (value is List<dynamic>) {
      for (var index = 0; index < value.length; index++) {
        _appendRows(
          rows: rows,
          rootFieldId: rootFieldId,
          path: [...path, index],
          keyLabel: '[$index]',
          value: value[index],
          depth: depth + 1,
          parentIsList: true,
        );
      }
    }
  }

  void _toggleExpand(
    PersonalDatabaseEditorRowData row, {
    bool shouldHaptic = false,
  }) {
    if (shouldHaptic) {
      AppHaptics.selection();
    }
    setState(() {
      if (_expandedNodeIds.contains(row.nodeId)) {
        _expandedNodeIds.remove(row.nodeId);
      } else {
        _expandedNodeIds.add(row.nodeId);
      }
    });
  }

  Future<void> _onPressedValue(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    if (row.isContainer) {
      _toggleExpand(row, shouldHaptic: true);
      return;
    }

    await _editRow(row, fieldsById);
  }

  Future<void> _onPressedAction(
    PersonalDatabaseEditorRowData row,
    PersonalDatabaseEditorAction action,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    switch (action) {
      case PersonalDatabaseEditorAction.addChild:
        await _addChild(row, fieldsById);
        return;
      case PersonalDatabaseEditorAction.edit:
        await _editRow(row, fieldsById);
        return;
      case PersonalDatabaseEditorAction.delete:
        await _deleteRow(row, fieldsById);
        return;
    }
  }

  Future<void> _handleAddRootField() async {
    AppHaptics.primaryAction();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.addTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.create'.tr(),
      showKeyInput: true,
      showScopeInput: true,
    );

    if (!mounted ||
        result == null ||
        result.key == null ||
        result.scope == null) {
      return;
    }

    try {
      await ref
          .read(personalDatabaseActionsProvider)
          .createField(
            actorPersonId: widget.personId,
            key: result.key!,
            type: result.type,
            isPublic: result.scope == PersonalDatabaseFieldScope.public,
            value: result.value,
          );
    } catch (_) {
      _showError();
    }
  }

  Future<void> _addChild(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    if (!row.isContainer) {
      return;
    }

    final rootField = fieldsById[row.rootFieldId];
    if (rootField == null) {
      return;
    }

    AppHaptics.primaryAction();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.addChildTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.create'.tr(),
      showKeyInput: row.valueType == PersonalDatabaseValueType.object,
      showScopeInput: false,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      await ref
          .read(personalDatabaseActionsProvider)
          .addChildNode(
            personId: widget.personId,
            field: rootField,
            parentPath: row.path,
            key: row.valueType == PersonalDatabaseValueType.object
                ? result.key
                : null,
            value: result.value,
          );

      if (!_expandedNodeIds.contains(row.nodeId) && mounted) {
        _toggleExpand(row);
      }
    } catch (_) {
      _showError();
    }
  }

  Future<void> _editRow(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    final rootField = fieldsById[row.rootFieldId];
    if (rootField == null) {
      return;
    }

    final isRoot = row.path.isEmpty;
    final canEditKey = !row.parentIsList;
    final initialKey = isRoot
        ? rootField.key
        : (row.path.last is String ? row.path.last as String : null);

    AppHaptics.primaryAction();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.editTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.update'.tr(),
      showKeyInput: canEditKey,
      showScopeInput: isRoot,
      initialKey: initialKey,
      initialScope: rootField.isPublic
          ? PersonalDatabaseFieldScope.public
          : PersonalDatabaseFieldScope.private,
      initialType: isRoot ? rootField.type : row.valueType,
      initialValue: row.rawValue,
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final actions = ref.read(personalDatabaseActionsProvider);
      if (isRoot) {
        await actions.updateField(
          actorPersonId: widget.personId,
          fieldId: rootField.id,
          key: result.key ?? rootField.key,
          type: result.type,
          isPublic: result.scope == PersonalDatabaseFieldScope.public,
          value: result.value,
        );
        return;
      }

      var targetPath = row.path;
      if (canEditKey && row.path.last is String && result.key != null) {
        final oldKey = row.path.last as String;
        final newKey = result.key!.trim();
        if (newKey.isNotEmpty && newKey != oldKey) {
          await actions.renameObjectKey(
            personId: widget.personId,
            field: rootField,
            path: row.path,
            newKey: newKey,
          );
          targetPath = [...row.path]..[row.path.length - 1] = newKey;
        }
      }

      await actions.updateNodeValue(
        personId: widget.personId,
        field: rootField,
        path: targetPath,
        value: result.value,
      );
    } catch (_) {
      _showError();
    }
  }

  Future<void> _deleteRow(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    final rootField = fieldsById[row.rootFieldId];
    if (rootField == null) {
      return;
    }

    AppHaptics.primaryAction();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('personTodo.database.deleteDialog.title'.tr()),
          content: Text(
            'personTodo.database.deleteDialog.body'.tr(
              namedArgs: {'key': row.keyLabel},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('personTodo.database.deleteDialog.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('personTodo.database.deleteDialog.delete'.tr()),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    try {
      final actions = ref.read(personalDatabaseActionsProvider);
      if (row.path.isEmpty) {
        await actions.deleteField(rootField.id);
        _expandedNodeIds.removeWhere(
          (nodeId) => nodeId.startsWith('${rootField.id}:'),
        );
        AppHaptics.confirm();
        return;
      }

      await actions.deleteNode(
        personId: widget.personId,
        field: rootField,
        path: row.path,
      );
      _expandedNodeIds.remove(row.nodeId);
      AppHaptics.confirm();
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('personTodo.database.actionError'.tr())),
    );
  }
}

String _nodeId({required String rootFieldId, required List<Object> path}) {
  return '$rootFieldId:${jsonEncode(path)}';
}

PersonalDatabaseValueType _valueTypeFromValue(Object? value) {
  if (value == null) {
    return PersonalDatabaseValueType.nullType;
  }
  if (value is String) {
    return PersonalDatabaseValueType.string;
  }
  if (value is num) {
    return PersonalDatabaseValueType.number;
  }
  if (value is bool) {
    return PersonalDatabaseValueType.boolean;
  }
  if (value is List) {
    return PersonalDatabaseValueType.list;
  }
  if (value is Map) {
    return PersonalDatabaseValueType.object;
  }
  return PersonalDatabaseValueType.string;
}

String _valuePreview(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return value.isEmpty ? '""' : '"$value"';
  }
  if (value is num || value is bool) {
    return '$value';
  }
  if (value is Map) {
    return '{${value.length}}';
  }
  if (value is List) {
    return '[${value.length}]';
  }
  return '$value';
}
