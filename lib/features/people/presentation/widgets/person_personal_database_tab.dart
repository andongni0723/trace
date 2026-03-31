import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../data/models/personal_database_field_node.dart';
import '../../data/models/personal_database_mention.dart';
import '../../data/models/personal_database_value_type.dart';
import '../widgets/personal_database_mention_input.dart';
import '../../providers/people_provider.dart';
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
    final peopleAsync = ref.watch(peopleProvider);
    final mentionCodec = ref.watch(personalDatabaseMentionCodecProvider);

    return fieldsAsync.when(
      data: (fields) {
        final fieldsById = {for (final field in fields) field.id: field};
        final peopleById = {
          for (final person
              in peopleAsync.asData?.value ?? const <PeopleData>[])
            person.id: person,
        };
        final rows = _buildRows(
          fields,
          peopleById: peopleById,
          mentionCodec: mentionCodec,
        );

        return PersonalDatabaseEditor(
          rows: rows,
          padding: widget.padding,
          onPressedValue: (row) => _onPressedValue(row, fieldsById),
          onPressedAction: (row, action) {
            _onPressedAction(row, action, fieldsById);
          },
          onPressedMention: (personId) =>
              _handleMentionPressed(personId, peopleById),
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
    List<PersonalDatabaseFieldNode> fields, {
    required Map<String, PeopleData> peopleById,
    required PersonalDatabaseMentionCodec mentionCodec,
  }) {
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
        peopleById: peopleById,
        mentionCodec: mentionCodec,
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
    required Map<String, PeopleData> peopleById,
    required PersonalDatabaseMentionCodec mentionCodec,
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
        valuePreview: _valuePreview(value, mentionCodec: mentionCodec),
        rawValue: value,
        valueType: valueType,
        depth: depth,
        isExpanded: isExpanded,
        isContainer: isContainer,
        parentIsList: parentIsList,
        valueSegments: _valueSegments(
          value,
          peopleById: peopleById,
          mentionCodec: mentionCodec,
        ),
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
          peopleById: peopleById,
          mentionCodec: mentionCodec,
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
          peopleById: peopleById,
          mentionCodec: mentionCodec,
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
    final mentionSuggestions = _mentionSuggestions();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.addChildTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.create'.tr(),
      showKeyInput: row.valueType == PersonalDatabaseValueType.object,
      mentionSuggestions: mentionSuggestions,
      mentionCodec: ref.read(personalDatabaseMentionCodecProvider),
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
    final mentionSuggestions = _mentionSuggestions();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.editTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.update'.tr(),
      showKeyInput: canEditKey,
      initialKey: initialKey,
      initialType: isRoot ? rootField.type : row.valueType,
      initialValue: row.rawValue,
      mentionSuggestions: mentionSuggestions,
      mentionCodec: ref.read(personalDatabaseMentionCodecProvider),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final actions = ref.read(personalDatabaseActionsProvider);
      if (isRoot) {
        await actions.updatePropertyAndValueForPerson(
          personId: widget.personId,
          fieldId: rootField.id,
          key: result.key ?? rootField.key,
          type: result.type,
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
    final isRoot = row.path.isEmpty;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isRoot
                ? 'personTodo.database.removeDialog.title'.tr()
                : 'personTodo.database.deleteDialog.title'.tr(),
          ),
          content: Text(
            (isRoot
                    ? 'personTodo.database.removeDialog.body'
                    : 'personTodo.database.deleteDialog.body')
                .tr(namedArgs: {'key': row.keyLabel}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isRoot
                    ? 'personTodo.database.removeDialog.cancel'.tr()
                    : 'personTodo.database.deleteDialog.cancel'.tr(),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isRoot
                    ? 'personTodo.database.removeDialog.remove'.tr()
                    : 'personTodo.database.deleteDialog.delete'.tr(),
              ),
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
      if (isRoot) {
        await actions.removeFieldFromPerson(
          personId: widget.personId,
          fieldId: rootField.id,
        );
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

  void _handleMentionPressed(
    String personId,
    Map<String, PeopleData> peopleById,
  ) {
    if (personId == widget.personId || !peopleById.containsKey(personId)) {
      return;
    }

    context.push('/people/$personId?tab=database');
  }

  List<PersonalDatabaseMentionSuggestion> _mentionSuggestions() {
    final people =
        ref.read(peopleProvider).asData?.value ?? const <PeopleData>[];
    return [
      for (final person in people)
        PersonalDatabaseMentionSuggestion(
          id: person.id,
          name: person.name,
          colorValue: person.colorValue,
          avatarPath: person.avatarPath,
        ),
    ];
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

String _valuePreview(
  Object? value, {
  required PersonalDatabaseMentionCodec mentionCodec,
}) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    final displayText = mentionCodec.toDisplayText(value);
    return displayText.isEmpty ? '""' : '"$displayText"';
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

List<PersonalDatabaseEditorValueSegment> _valueSegments(
  Object? value, {
  required Map<String, PeopleData> peopleById,
  required PersonalDatabaseMentionCodec mentionCodec,
}) {
  if (value is! String) {
    return const [];
  }

  final segments = mentionCodec.parseSegments(value);
  if (segments.isEmpty) {
    return const [PersonalDatabaseEditorValueSegment(text: '""')];
  }

  return [
    const PersonalDatabaseEditorValueSegment(text: '"'),
    for (final segment in segments)
      switch (segment) {
        PersonalDatabaseMentionPersonSegment(:final mention) =>
          PersonalDatabaseEditorValueSegment(
            text:
                '@${peopleById[mention.personId]?.name ?? mention.displayName}',
            personId: mention.personId,
          ),
        PersonalDatabaseMentionTextSegment(:final text) =>
          PersonalDatabaseEditorValueSegment(text: text),
        _ => PersonalDatabaseEditorValueSegment(text: segment.displayText),
      },
    const PersonalDatabaseEditorValueSegment(text: '"'),
  ];
}
