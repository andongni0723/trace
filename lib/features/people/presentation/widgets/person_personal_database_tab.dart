import 'dart:io';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/database.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../media_library/providers/media_library_providers.dart';
import '../../data/models/personal_database_field_node.dart';
import '../../data/models/personal_database_media_value.dart';
import '../../data/models/personal_database_mention.dart';
import '../../data/models/personal_database_mention_suggestion.dart';
import '../../data/models/personal_database_value_type.dart';
import '../../providers/people_provider.dart';
import '../../providers/personal_database_provider.dart';
import '../pages/personal_database_array_template_editor_page.dart';
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
  bool _didScheduleBackfill = false;

  @override
  void initState() {
    super.initState();
    _scheduleNestedDefinitionBackfill();
  }

  @override
  void didUpdateWidget(covariant PersonPersonalDatabaseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId) {
      _didScheduleBackfill = false;
      _scheduleNestedDefinitionBackfill();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(
      personalDatabaseFieldTreeProvider(widget.personId),
    );
    final peopleAsync = ref.watch(peopleProvider);
    final mentionCodec = ref.watch(personalDatabaseMentionCodecProvider);

    return fieldsAsync.when(
      data: (fields) {
        final fieldsById = _fieldsById(fields);
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
      _appendFieldRows(
        rows: rows,
        field: field,
        depth: 0,
        peopleById: peopleById,
        mentionCodec: mentionCodec,
      );
    }
    return rows;
  }

  Map<String, PersonalDatabaseFieldNode> _fieldsById(
    List<PersonalDatabaseFieldNode> fields,
  ) {
    final byId = <String, PersonalDatabaseFieldNode>{};

    void visit(List<PersonalDatabaseFieldNode> nodes) {
      for (final node in nodes) {
        byId[node.id] = node;
        if (node.children.isNotEmpty) {
          visit(node.children);
        }
      }
    }

    visit(fields);
    return byId;
  }

  void _scheduleNestedDefinitionBackfill() {
    if (_didScheduleBackfill) {
      return;
    }
    _didScheduleBackfill = true;

    Future<void>.microtask(() async {
      await ref
          .read(personalDatabaseActionsProvider)
          .ensureObjectSubtreeDefinitions(personId: widget.personId);
    });
  }

  void _appendFieldRows({
    required List<PersonalDatabaseEditorRowData> rows,
    required PersonalDatabaseFieldNode field,
    required int depth,
    required Map<String, PeopleData> peopleById,
    required PersonalDatabaseMentionCodec mentionCodec,
  }) {
    final nodeId = _nodeId(rootFieldId: field.id, path: const []);
    final isExpanded = _expandedNodeIds.contains(nodeId);
    final isContainer =
        field.type == PersonalDatabaseValueType.object ||
        field.type == PersonalDatabaseValueType.list;

    rows.add(
      PersonalDatabaseEditorRowData(
        nodeId: nodeId,
        fieldId: field.id,
        rootFieldId: field.id,
        path: const [],
        keyLabel: field.key,
        valuePreview: _fieldValuePreview(field, mentionCodec: mentionCodec),
        rawValue: field.value,
        valueType: field.type,
        depth: depth,
        isExpanded: isExpanded,
        isContainer: isContainer,
        isDefinitionBacked: true,
        parentIsList: false,
        canAddFromTemplate:
            field.type == PersonalDatabaseValueType.list &&
            field.hasArrayElementTemplate,
        canEditTemplate: field.type == PersonalDatabaseValueType.list,
        valueSegments: _valueSegments(
          field.value,
          peopleById: peopleById,
          mentionCodec: mentionCodec,
        ),
      ),
    );

    if (!isContainer || !isExpanded) {
      return;
    }

    if (field.type == PersonalDatabaseValueType.object) {
      for (final child in field.children) {
        _appendFieldRows(
          rows: rows,
          field: child,
          depth: depth + 1,
          peopleById: peopleById,
          mentionCodec: mentionCodec,
        );
      }
      return;
    }

    final listValue = field.value;
    if (listValue is List<dynamic>) {
      for (var index = 0; index < listValue.length; index++) {
        _appendValueRows(
          rows: rows,
          rootField: field,
          fieldId: field.id,
          rootFieldId: field.id,
          path: [index],
          keyLabel: '[$index]',
          value: listValue[index],
          depth: depth + 1,
          parentIsList: true,
          peopleById: peopleById,
          mentionCodec: mentionCodec,
        );
      }
    }
  }

  void _appendValueRows({
    required List<PersonalDatabaseEditorRowData> rows,
    required PersonalDatabaseFieldNode rootField,
    required String fieldId,
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
    final arrayTemplateMetadata = valueType == PersonalDatabaseValueType.list
        ? _resolveArrayTemplateMetadata(rootField: rootField, path: path)
        : null;
    final nodeId = _nodeId(rootFieldId: rootFieldId, path: path);
    final isExpanded = _expandedNodeIds.contains(nodeId);
    final isContainer =
        valueType == PersonalDatabaseValueType.object ||
        valueType == PersonalDatabaseValueType.list;

    rows.add(
      PersonalDatabaseEditorRowData(
        nodeId: nodeId,
        fieldId: fieldId,
        rootFieldId: rootFieldId,
        path: path,
        keyLabel: keyLabel,
        valuePreview: _valuePreview(
          value,
          arrayElementType: arrayTemplateMetadata?.elementType,
          mentionCodec: mentionCodec,
        ),
        rawValue: value,
        valueType: valueType,
        depth: depth,
        isExpanded: isExpanded,
        isContainer: isContainer,
        isDefinitionBacked: false,
        parentIsList: parentIsList,
        canAddFromTemplate:
            valueType == PersonalDatabaseValueType.list &&
            arrayTemplateMetadata?.hasObjectTemplate == true,
        canEditTemplate:
            valueType == PersonalDatabaseValueType.list &&
            _canEditNestedArrayTemplate(rootField: rootField),
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
        _appendValueRows(
          rows: rows,
          rootField: rootField,
          fieldId: fieldId,
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
        _appendValueRows(
          rows: rows,
          rootField: rootField,
          fieldId: fieldId,
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

    if (row.valueType == PersonalDatabaseValueType.media) {
      await _openMediaValue(row.rawValue);
      return;
    }

    await _editRow(row, fieldsById);
  }

  Future<void> _openMediaValue(Object? rawValue) async {
    final mediaValue = personalDatabaseMediaValueFromObject(rawValue);
    if (!mediaValue.hasFile || mediaValue.mediaAssetId.trim().isEmpty) {
      _showMediaOpenError();
      return;
    }

    AppHaptics.primaryAction();
    try {
      final asset = await ref
          .read(mediaAssetsDaoProvider)
          .getMediaAssetById(mediaValue.mediaAssetId);
      final filePath = asset?.filePath.trim();
      if (filePath == null || filePath.isEmpty) {
        _showMediaOpenError();
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        _showMediaOpenError();
        return;
      }

      final didOpen = await ref
          .read(mediaAssetOpenerProvider)
          .openMediaFile(filePath: file.path, mimeType: asset?.mimeType);
      if (!didOpen) {
        _showMediaOpenError();
      }
    } catch (_) {
      _showMediaOpenError();
    }
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
      case PersonalDatabaseEditorAction.addFromTemplate:
        await _addFromTemplate(row, fieldsById);
        return;
      case PersonalDatabaseEditorAction.editTemplate:
        await _editTemplate(row, fieldsById);
        return;
      case PersonalDatabaseEditorAction.edit:
        await _editRow(row, fieldsById);
        return;
      case PersonalDatabaseEditorAction.delete:
        await _deleteRow(row, fieldsById);
        return;
    }
  }

  Future<void> _editTemplate(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    final targetField = fieldsById[row.fieldId];
    if (targetField == null ||
        targetField.type != PersonalDatabaseValueType.list) {
      return;
    }

    final initialTemplate = row.isDefinitionBacked
        ? targetField.arrayElementTemplate ?? const <String, Object?>{}
        : _resolveArrayTemplateMetadata(
                rootField: targetField,
                path: row.path,
              )?.template ??
              const <String, Object?>{};
    final titleKey = row.isDefinitionBacked
        ? 'personalDatabaseTemplateEditor.rootTitle'
        : 'personalDatabaseTemplateEditor.nestedTitle';
    final titleArg = row.isDefinitionBacked ? targetField.key : row.keyLabel;

    final result = await showPersonalDatabaseArrayTemplateEditorPage(
      context: context,
      title: titleKey.tr(namedArgs: {'key': titleArg}),
      initialTemplate: initialTemplate,
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final actions = ref.read(personalDatabaseActionsProvider);
      if (row.isDefinitionBacked) {
        if (targetField.arrayElementType != PersonalDatabaseValueType.object) {
          await actions.updateArrayElementType(
            fieldId: targetField.id,
            elementType: PersonalDatabaseValueType.object,
          );
        }
        await actions.updateArrayElementTemplate(
          fieldId: targetField.id,
          template: result,
        );
        return;
      }

      final updatedTemplate = _upsertNestedArrayTemplate(
        rootField: targetField,
        path: row.path,
        template: result,
      );
      if (updatedTemplate == null) {
        _showError();
        return;
      }

      await actions.updateArrayElementTemplate(
        fieldId: targetField.id,
        template: updatedTemplate,
      );
    } catch (_) {
      _showError();
    }
  }

  Future<void> _addFromTemplate(
    PersonalDatabaseEditorRowData row,
    Map<String, PersonalDatabaseFieldNode> fieldsById,
  ) async {
    final targetField = fieldsById[row.fieldId];
    if (targetField == null) {
      return;
    }

    final metadata = row.isDefinitionBacked
        ? _ArrayTemplateMetadataView(
            elementType: targetField.arrayElementType,
            template: targetField.arrayElementTemplate,
          )
        : _resolveArrayTemplateMetadata(rootField: targetField, path: row.path);
    if (metadata?.hasObjectTemplate != true) {
      return;
    }

    try {
      AppHaptics.primaryAction();

      if (row.isDefinitionBacked) {
        await ref
            .read(personalDatabaseActionsProvider)
            .addArrayElementFromTemplate(
              personId: widget.personId,
              field: targetField,
            );
      } else {
        final currentValue = row.rawValue;
        if (currentValue is! List<dynamic>) {
          return;
        }

        final nextValue = _deepCloneJson(currentValue);
        if (nextValue is! List<dynamic>) {
          return;
        }
        nextValue.add(_materializeTemplateValue(metadata!.template));

        await ref
            .read(personalDatabaseActionsProvider)
            .updateNodeValue(
              personId: widget.personId,
              field: targetField,
              path: row.path,
              value: nextValue,
            );
      }

      if (!_expandedNodeIds.contains(row.nodeId) && mounted) {
        _toggleExpand(row);
      }
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

    final targetField = fieldsById[row.fieldId];
    if (targetField == null) {
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
      final actions = ref.read(personalDatabaseActionsProvider);
      if (row.isDefinitionBacked &&
          row.valueType == PersonalDatabaseValueType.object) {
        await actions.createChildPropertyForPerson(
          personId: widget.personId,
          parentField: targetField,
          key: result.key ?? '',
          type: result.type,
          value: result.value,
        );
      } else {
        await actions.addChildNode(
          personId: widget.personId,
          field: targetField,
          parentPath: row.path,
          key: row.valueType == PersonalDatabaseValueType.object
              ? result.key
              : null,
          value: result.value,
        );
      }

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
    final targetField = fieldsById[row.fieldId];
    if (targetField == null) {
      return;
    }

    final isDefinitionBacked = row.isDefinitionBacked;
    final canEditKey = !isDefinitionBacked && !row.parentIsList;
    final initialKey = switch (row.path.lastOrNull) {
      String key => key,
      _ => null,
    };
    final initialType = isDefinitionBacked ? targetField.type : row.valueType;

    AppHaptics.primaryAction();
    final mentionSuggestions = _mentionSuggestions();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.database.sheet.editTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.update'.tr(),
      showKeyInput: canEditKey,
      showTypeInput: !isDefinitionBacked,
      readOnlyKeyText: isDefinitionBacked ? targetField.key : null,
      readOnlyTypeText: isDefinitionBacked
          ? targetField.type.localizationKey.tr()
          : null,
      initialKey: canEditKey ? initialKey : null,
      initialType: initialType,
      initialValue:
          isDefinitionBacked && initialType == PersonalDatabaseValueType.object
          ? const <String, Object?>{}
          : row.rawValue,
      mentionSuggestions: mentionSuggestions,
      mentionCodec: ref.read(personalDatabaseMentionCodecProvider),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final actions = ref.read(personalDatabaseActionsProvider);
      if (isDefinitionBacked) {
        final hasDefinitionChildren = targetField.children.isNotEmpty;
        final nextValue =
            hasDefinitionChildren &&
                targetField.type == PersonalDatabaseValueType.object
            ? targetField.value
            : result.value;

        await actions.updatePropertyAndValueForPerson(
          personId: widget.personId,
          fieldId: targetField.id,
          key: targetField.key,
          type: targetField.type,
          value: nextValue,
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
            field: targetField,
            path: row.path,
            newKey: newKey,
          );
          targetPath = [...row.path]..[row.path.length - 1] = newKey;
        }
      }

      await actions.updateNodeValue(
        personId: widget.personId,
        field: targetField,
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
    final targetField = fieldsById[row.fieldId];
    if (targetField == null) {
      return;
    }

    if (row.isDefinitionBacked &&
        targetField.type == PersonalDatabaseValueType.object &&
        _hasVisibleDescendants(targetField)) {
      AppHaptics.selection();
      await _showCannotDeleteObjectDialog(row.keyLabel);
      return;
    }

    AppHaptics.primaryAction();
    final isRoot = row.isDefinitionBacked ? row.depth == 0 : row.path.isEmpty;
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
          fieldId: targetField.id,
        );
        _expandedNodeIds.removeWhere(
          (nodeId) => nodeId.startsWith('${targetField.id}:'),
        );
        AppHaptics.confirm();
        return;
      }

      if (row.isDefinitionBacked) {
        await actions.removeChildPropertyFromPerson(
          personId: widget.personId,
          fieldId: targetField.id,
        );
        _expandedNodeIds.removeWhere(
          (nodeId) => nodeId.startsWith('${targetField.id}:'),
        );
        AppHaptics.confirm();
        return;
      }

      await actions.deleteNode(
        personId: widget.personId,
        field: targetField,
        path: row.path,
      );
      _expandedNodeIds.remove(row.nodeId);
      AppHaptics.confirm();
    } catch (_) {
      _showError();
    }
  }

  bool _hasVisibleDescendants(PersonalDatabaseFieldNode field) {
    if (field.children.isNotEmpty) {
      return true;
    }

    for (final child in field.children) {
      if (_hasVisibleDescendants(child)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _showCannotDeleteObjectDialog(String keyLabel) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('personTodo.database.cannotDeleteDialog.title'.tr()),
          content: Text(
            'personTodo.database.cannotDeleteDialog.body'.tr(
              namedArgs: {'key': keyLabel},
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'personTodo.database.cannotDeleteDialog.confirm'.tr(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('personTodo.database.actionError'.tr())),
    );
  }

  void _showMediaOpenError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('personTodo.database.mediaOpenError'.tr())),
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

class _ArrayTemplateMetadataView {
  const _ArrayTemplateMetadataView({this.elementType, this.template});

  final PersonalDatabaseValueType? elementType;
  final Map<String, Object?>? template;

  bool get hasObjectTemplate =>
      elementType == PersonalDatabaseValueType.object && template != null;
}

String _nodeId({required String rootFieldId, required List<Object> path}) {
  return '$rootFieldId:${jsonEncode(path)}';
}

bool _canEditNestedArrayTemplate({
  required PersonalDatabaseFieldNode rootField,
}) {
  return rootField.type == PersonalDatabaseValueType.list &&
      rootField.arrayElementType == PersonalDatabaseValueType.object;
}

_ArrayTemplateMetadataView? _resolveArrayTemplateMetadata({
  required PersonalDatabaseFieldNode rootField,
  required List<Object> path,
}) {
  if (!_canEditNestedArrayTemplate(rootField: rootField)) {
    return null;
  }

  var currentList = _ArrayTemplateMetadataView(
    elementType: rootField.arrayElementType,
    template: rootField.arrayElementTemplate,
  );
  if (path.isEmpty) {
    return currentList;
  }

  Map<String, Object?>? currentObjectTemplate;

  for (final segment in path) {
    if (segment is int) {
      if (currentList.elementType != PersonalDatabaseValueType.object ||
          currentList.template == null) {
        return null;
      }
      currentObjectTemplate = currentList.template;
      continue;
    }

    if (segment is! String || currentObjectTemplate == null) {
      return null;
    }

    final propertyValue = currentObjectTemplate[segment];
    if (propertyValue is List) {
      currentList =
          _readArrayTemplateMetadataForKey(currentObjectTemplate, segment) ??
          const _ArrayTemplateMetadataView();
      currentObjectTemplate = null;
      continue;
    }

    if (propertyValue is Map<String, dynamic>) {
      currentObjectTemplate = propertyValue.cast<String, Object?>();
      continue;
    }

    if (propertyValue is Map<String, Object?>) {
      currentObjectTemplate = propertyValue;
      continue;
    }

    return null;
  }

  return currentList;
}

_ArrayTemplateMetadataView? _readArrayTemplateMetadataForKey(
  Map<String, Object?> objectTemplate,
  String key,
) {
  final metadataRoot = _mutableTemplateMap(
    objectTemplate[personalDatabaseArrayTemplateMetadataKey],
  );
  final rawMetadata = _mutableTemplateMap(metadataRoot?[key]);
  final dbKey = rawMetadata?['elementType'];
  if (dbKey is! String) {
    return null;
  }

  final elementType = personalDatabaseValueTypeFromDb(dbKey);
  return _ArrayTemplateMetadataView(
    elementType: elementType,
    template: elementType == PersonalDatabaseValueType.object
        ? _mutableTemplateMap(rawMetadata?['template']) ??
              const <String, Object?>{}
        : null,
  );
}

Map<String, Object?>? _upsertNestedArrayTemplate({
  required PersonalDatabaseFieldNode rootField,
  required List<Object> path,
  required Map<String, Object?> template,
}) {
  if (!_canEditNestedArrayTemplate(rootField: rootField) || path.isEmpty) {
    return null;
  }

  final rootTemplateValue = _deepCloneJson(
    rootField.arrayElementTemplate ?? const <String, Object?>{},
  );
  final rootTemplate = _mutableTemplateMap(rootTemplateValue);
  if (rootTemplate == null) {
    return null;
  }

  Map<String, Object?>? currentObjectTemplate;

  for (var index = 0; index < path.length; index++) {
    final segment = path[index];
    if (segment is int) {
      currentObjectTemplate ??= rootTemplate;
      continue;
    }

    if (segment is! String || currentObjectTemplate == null) {
      return null;
    }

    final isLast = index == path.length - 1;
    if (isLast) {
      if (currentObjectTemplate[segment] is! List) {
        currentObjectTemplate[segment] = <Object?>[];
      }
      _writeArrayTemplateMetadataForKey(
        currentObjectTemplate,
        segment,
        template: template,
      );
      return rootTemplate;
    }

    final nextSegment = path[index + 1];
    if (nextSegment is int) {
      if (currentObjectTemplate[segment] is! List) {
        currentObjectTemplate[segment] = <Object?>[];
      }
      currentObjectTemplate = _writeArrayTemplateMetadataForKey(
        currentObjectTemplate,
        segment,
      ).template;
      continue;
    }

    final existingObject = _mutableTemplateMap(currentObjectTemplate[segment]);
    if (existingObject != null) {
      currentObjectTemplate = existingObject;
      continue;
    }

    final createdObject = <String, Object?>{};
    currentObjectTemplate[segment] = createdObject;
    currentObjectTemplate = createdObject;
  }

  return rootTemplate;
}

_ArrayTemplateMetadataView _writeArrayTemplateMetadataForKey(
  Map<String, Object?> objectTemplate,
  String key, {
  Map<String, Object?>? template,
}) {
  final metadataRoot = _ensureArrayTemplateMetadataRoot(objectTemplate);
  final metadata =
      _mutableTemplateMap(metadataRoot[key]) ?? <String, Object?>{};
  final nextTemplate =
      _mutableTemplateMap(metadata['template']) ??
      _deepCloneJson(template ?? const <String, Object?>{})
          as Map<String, Object?>;

  metadata['elementType'] = PersonalDatabaseValueType.object.dbKey;
  metadata['template'] = nextTemplate;
  metadataRoot[key] = metadata;

  return _ArrayTemplateMetadataView(
    elementType: PersonalDatabaseValueType.object,
    template: nextTemplate,
  );
}

Map<String, Object?> _ensureArrayTemplateMetadataRoot(
  Map<String, Object?> objectTemplate,
) {
  final existing = _mutableTemplateMap(
    objectTemplate[personalDatabaseArrayTemplateMetadataKey],
  );
  if (existing != null) {
    return existing;
  }

  final created = <String, Object?>{};
  objectTemplate[personalDatabaseArrayTemplateMetadataKey] = created;
  return created;
}

Map<String, Object?>? _mutableTemplateMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return value.cast<String, Object?>();
  }
  return null;
}

Object? _deepCloneJson(Object? value) {
  if (value == null) {
    return null;
  }
  return jsonDecode(jsonEncode(value));
}

Object? _materializeTemplateValue(Object? value) {
  return _stripTemplateMetadata(_deepCloneJson(value));
}

Object? _stripTemplateMetadata(Object? value) {
  if (value is Map<String, dynamic>) {
    return {
      for (final entry in value.entries)
        if (entry.key != personalDatabaseArrayTemplateMetadataKey)
          entry.key: _stripTemplateMetadata(entry.value),
    };
  }
  if (value is Map<String, Object?>) {
    return {
      for (final entry in value.entries)
        if (entry.key != personalDatabaseArrayTemplateMetadataKey)
          entry.key: _stripTemplateMetadata(entry.value),
    };
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if ('${entry.key}' != personalDatabaseArrayTemplateMetadataKey)
          '${entry.key}': _stripTemplateMetadata(entry.value),
    };
  }
  if (value is List) {
    return value.map(_stripTemplateMetadata).toList(growable: false);
  }
  return value;
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
  if (value is PersonalDatabaseMediaValue) {
    return PersonalDatabaseValueType.media;
  }
  if (value is List) {
    return PersonalDatabaseValueType.list;
  }
  if (value is Map) {
    return PersonalDatabaseValueType.object;
  }
  return PersonalDatabaseValueType.string;
}

String _fieldValuePreview(
  PersonalDatabaseFieldNode field, {
  required PersonalDatabaseMentionCodec mentionCodec,
}) {
  if (field.type == PersonalDatabaseValueType.object) {
    return '{${field.children.length}}';
  }
  if (field.type == PersonalDatabaseValueType.media) {
    return _mediaFileNamePreview(field.value);
  }
  return _valuePreview(
    field.value,
    arrayElementType: field.arrayElementType,
    mentionCodec: mentionCodec,
  );
}

String _valuePreview(
  Object? value, {
  PersonalDatabaseValueType? arrayElementType,
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
  if (value is PersonalDatabaseMediaValue) {
    return _mediaFileNamePreview(value);
  }
  if (value is Map) {
    return '{${value.length}}';
  }
  if (value is List) {
    final elementTypeLabel =
        arrayElementType?.localizationKey.tr() ??
        'databasePropertyManager.arrayElement.unspecified'.tr();
    return '[${value.length}] <$elementTypeLabel>';
  }
  return '$value';
}

String _mediaFileNamePreview(Object? value) {
  final mediaValue = personalDatabaseMediaValueFromObject(value);
  final fileName = mediaValue.fileName.trim();
  if (fileName.isEmpty) {
    return 'personTodo.database.sheet.mediaEmpty'.tr();
  }
  return fileName;
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
