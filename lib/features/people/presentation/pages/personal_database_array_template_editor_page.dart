import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../../shared/widgets/bottom_sheet_keyboard_inset.dart';
import '../../data/models/personal_database_value_type.dart';
import '../../providers/personal_database_provider.dart';
import '../widgets/personal_database_editor.dart';
import '../widgets/personal_database_field_sheet.dart';
import '../widgets/personal_database_type_tags.dart';

class PersonalDatabaseArrayTemplateEditorPage extends StatefulWidget {
  const PersonalDatabaseArrayTemplateEditorPage({
    required this.title,
    required this.initialTemplate,
    super.key,
  });

  final String title;
  final Map<String, Object?> initialTemplate;

  @override
  State<PersonalDatabaseArrayTemplateEditorPage> createState() =>
      _PersonalDatabaseArrayTemplateEditorPageState();
}

Future<Map<String, Object?>?> showPersonalDatabaseArrayTemplateEditorPage({
  required BuildContext context,
  required String title,
  required Map<String, Object?> initialTemplate,
}) {
  return Navigator.of(context).push<Map<String, Object?>>(
    MaterialPageRoute(
      builder: (_) => PersonalDatabaseArrayTemplateEditorPage(
        title: title,
        initialTemplate: initialTemplate,
      ),
    ),
  );
}

class _PersonalDatabaseArrayTemplateEditorPageState
    extends State<PersonalDatabaseArrayTemplateEditorPage> {
  static const _documentEquality = DeepCollectionEquality();
  static const _tileOuterRadius = 28.0;
  static const _tileInnerRadius = 4.0;
  static const _tileSpacing = 4.0;
  static const _availableTemplateTypes = [
    PersonalDatabaseValueType.string,
    PersonalDatabaseValueType.number,
    PersonalDatabaseValueType.boolean,
    PersonalDatabaseValueType.nullType,
    PersonalDatabaseValueType.list,
    PersonalDatabaseValueType.object,
  ];

  late Map<String, Object?> _values;
  late Map<String, _ArrayTemplateMetadata> _arrayMetadata;
  late Map<String, Object?> _initialDocumentJson;

  @override
  void initState() {
    super.initState();
    final parsed = _TemplateDocument.parse(widget.initialTemplate);
    _values = parsed.values;
    _arrayMetadata = parsed.arrayMetadata;
    _initialDocumentJson = parsed.toJson();
  }

  bool get _hasUnsavedChanges => !_documentEquality.equals(
    _TemplateDocument(_values, _arrayMetadata).toJson(),
    _initialDocumentJson,
  );

  @override
  Widget build(BuildContext context) {
    final entries = _values.entries.toList(growable: false);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasUnsavedChanges) {
          return;
        }
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmLeaveIfNeeded();
        if (!mounted || shouldLeave != true) {
          return;
        }
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('personalDatabaseTemplateEditor.save'.tr()),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          tooltip: 'personalDatabaseTemplateEditor.addProperty'.tr(),
          onPressed: _addProperty,
          child: const Icon(Icons.add),
        ),
        body: entries.isEmpty
            ? _EmptyTemplateState(onAdd: _addProperty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: _tileSpacing),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _TemplatePropertyTile(
                    name: entry.key,
                    value: entry.value,
                    arrayMetadata: _arrayMetadata[entry.key],
                    borderRadius: _tileBorderRadiusFor(
                      index: index,
                      length: entries.length,
                    ),
                    onPressedValue: () => _onPressedPropertyValue(entry.key),
                    onSelectedAction: (action) =>
                        _onSelectedPropertyAction(entry.key, action),
                    onPressedArrayElementType:
                        _valueTypeFromValue(entry.value) ==
                            PersonalDatabaseValueType.list
                        ? () => _showArrayElementTypeActions(entry.key)
                        : null,
                  );
                },
              ),
      ),
    );
  }

  Future<void> _addProperty() async {
    AppHaptics.primaryAction();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personalDatabaseTemplateEditor.addPropertyTitle'.tr(),
      submitLabel: 'personalDatabaseTemplateEditor.create'.tr(),
      showKeyInput: true,
      availableTypes: _availableTemplateTypes,
    );

    if (!mounted || result == null || result.key == null) {
      return;
    }

    final key = result.key!.trim();
    if (_isInvalidTemplateKey(key) || _values.containsKey(key)) {
      _showError();
      return;
    }

    setState(() {
      _values[key] = _templateValueFromResult(result);
      if (result.type != PersonalDatabaseValueType.list) {
        _arrayMetadata.remove(key);
      }
    });
  }

  Future<void> _editProperty(String key) async {
    final value = _values[key];
    final type = _valueTypeFromValue(value);
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personalDatabaseTemplateEditor.editPropertyTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.update'.tr(),
      showKeyInput: true,
      initialKey: key,
      initialType: type,
      initialValue: value,
      availableTypes: _availableTemplateTypes,
    );

    if (!mounted || result == null || result.key == null) {
      return;
    }

    final nextKey = result.key!.trim();
    if (_isInvalidTemplateKey(nextKey) ||
        (nextKey != key && _values.containsKey(nextKey))) {
      _showError();
      return;
    }

    setState(() {
      final metadata = _arrayMetadata.remove(key);
      final nextValue = _templateValueFromResult(result);
      _values.remove(key);
      _values[nextKey] = nextValue;
      if (result.type == PersonalDatabaseValueType.list && metadata != null) {
        _arrayMetadata[nextKey] = metadata;
      }
    });
  }

  Future<void> _editObjectTemplate(String key) async {
    final value = _values[key];
    final object = _asStringKeyedMap(value) ?? const <String, Object?>{};
    final result = await showPersonalDatabaseArrayTemplateEditorPage(
      context: context,
      title: key,
      initialTemplate: object,
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _values[key] = result;
    });
  }

  Future<void> _showArrayElementTypeActions(String key) async {
    final metadata = _arrayMetadata[key];
    if (metadata?.elementType != PersonalDatabaseValueType.object) {
      await _showArrayElementTypeSheet(key);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.cs.surface,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: BottomSheetKeyboardInset(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(
                    'databasePropertyManager.action.changeElementType'.tr(),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _showArrayElementTypeSheet(key);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.data_object_rounded),
                  title: Text(
                    'databasePropertyManager.action.editElementTemplate'.tr(),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _editArrayElementTemplate(key);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showArrayElementTypeSheet(String key) async {
    final selectedType = await showModalBottomSheet<PersonalDatabaseValueType?>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _TemplateTypeSheet(
        title: 'databasePropertyManager.elementTypeDialog.title'.tr(),
        initialType: _arrayMetadata[key]?.elementType,
      ),
    );

    if (!mounted || selectedType == _arrayMetadata[key]?.elementType) {
      return;
    }

    setState(() {
      final current = _arrayMetadata[key];
      if (selectedType == null) {
        _arrayMetadata.remove(key);
        return;
      }
      _arrayMetadata[key] = _ArrayTemplateMetadata(
        elementType: selectedType,
        template: selectedType == PersonalDatabaseValueType.object
            ? current?.template ?? const <String, Object?>{}
            : null,
      );
    });
  }

  Future<void> _editArrayElementTemplate(String key) async {
    if (_valueTypeFromValue(_values[key]) != PersonalDatabaseValueType.list) {
      return;
    }

    final current = _arrayMetadata[key];
    if (current?.elementType != PersonalDatabaseValueType.object) {
      setState(() {
        _arrayMetadata[key] = const _ArrayTemplateMetadata(
          elementType: PersonalDatabaseValueType.object,
          template: <String, Object?>{},
        );
      });
    }

    final metadata = _arrayMetadata[key];
    final result = await showPersonalDatabaseArrayTemplateEditorPage(
      context: context,
      title: 'personalDatabaseTemplateEditor.nestedTitle'.tr(
        namedArgs: {'key': key},
      ),
      initialTemplate: metadata?.template ?? const <String, Object?>{},
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _arrayMetadata[key] = _ArrayTemplateMetadata(
        elementType: PersonalDatabaseValueType.object,
        template: result,
      );
    });
  }

  void _deleteProperty(String key) {
    AppHaptics.confirm();
    setState(() {
      _values.remove(key);
      _arrayMetadata.remove(key);
    });
  }

  void _save() {
    AppHaptics.confirm();
    Navigator.of(
      context,
    ).pop(_TemplateDocument(_values, _arrayMetadata).toJson());
  }

  Future<bool?> _confirmLeaveIfNeeded() {
    if (!_hasUnsavedChanges) {
      return Future.value(true);
    }
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('personalDatabaseTemplateEditor.leaveDialog.title'.tr()),
          content: Text('personalDatabaseTemplateEditor.leaveDialog.body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('databasePropertyManager.renameDialog.cancel'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.cs.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'personalDatabaseTemplateEditor.leaveDialog.leave'.tr(),
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

  Future<void> _onPressedPropertyValue(String key) async {
    final value = _values[key];
    final type = _valueTypeFromValue(value);
    switch (type) {
      case PersonalDatabaseValueType.object:
        await _editObjectTemplate(key);
        return;
      case PersonalDatabaseValueType.list:
        final metadata = _arrayMetadata[key];
        if (metadata?.elementType == PersonalDatabaseValueType.object) {
          await _editArrayElementTemplate(key);
        } else {
          await _showArrayElementTypeActions(key);
        }
        return;
      default:
        await _editProperty(key);
        return;
    }
  }

  Future<void> _onSelectedPropertyAction(
    String key,
    _TemplatePropertyAction action,
  ) async {
    switch (action) {
      case _TemplatePropertyAction.editObject:
        await _editObjectTemplate(key);
        return;
      case _TemplatePropertyAction.editTemplate:
        await _editArrayElementTemplate(key);
        return;
      case _TemplatePropertyAction.editProperty:
        await _editProperty(key);
        return;
      case _TemplatePropertyAction.delete:
        _deleteProperty(key);
        return;
    }
  }
}

class _TemplatePropertyTile extends StatelessWidget {
  const _TemplatePropertyTile({
    required this.name,
    required this.value,
    required this.arrayMetadata,
    required this.borderRadius,
    required this.onPressedArrayElementType,
    required this.onPressedValue,
    required this.onSelectedAction,
  });

  final String name;
  final Object? value;
  final _ArrayTemplateMetadata? arrayMetadata;
  final BorderRadius borderRadius;
  final VoidCallback? onPressedArrayElementType;
  final VoidCallback onPressedValue;
  final ValueChanged<_TemplatePropertyAction> onSelectedAction;

  @override
  Widget build(BuildContext context) {
    final type = _valueTypeFromValue(value);
    return PersonalDatabasePropertyRow<_TemplatePropertyAction>(
      borderRadius: borderRadius,
      leadingFlex: 8,
      valueFlex: 2,
      onPressedValue: onPressedValue,
      onSelectedMenu: onSelectedAction,
      itemBuilder: (_) => [
        if (type == PersonalDatabaseValueType.object)
          PopupMenuItem(
            value: _TemplatePropertyAction.editObject,
            child: Text(
              'personalDatabaseTemplateEditor.action.editObject'.tr(),
            ),
          ),
        if (type == PersonalDatabaseValueType.list)
          PopupMenuItem(
            value: _TemplatePropertyAction.editTemplate,
            child: Text(
              'personalDatabaseTemplateEditor.action.editTemplate'.tr(),
            ),
          ),
        PopupMenuItem(
          value: _TemplatePropertyAction.editProperty,
          child: Text(
            'personalDatabaseTemplateEditor.action.editProperty'.tr(),
          ),
        ),
        PopupMenuItem(
          value: _TemplatePropertyAction.delete,
          child: Text('personTodo.database.action.delete'.tr()),
        ),
      ],
      leading: Row(
        children: [
          Flexible(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _RoundedTypeTag(label: type.localizationKey.tr()),
                if (type == PersonalDatabaseValueType.list)
                  ArrayElementTypeTag(
                    label:
                        arrayMetadata?.elementType.localizationKey.tr() ??
                        'databasePropertyManager.arrayElement.unspecified'.tr(),
                    onTap: onPressedArrayElementType,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      value: Text(
        _valuePreview(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: context.tt.bodySmall?.copyWith(
          color: context.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum _TemplatePropertyAction { editObject, editTemplate, editProperty, delete }

class _EmptyTemplateState extends StatelessWidget {
  const _EmptyTemplateState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'personalDatabaseTemplateEditor.emptyTitle'.tr(),
              textAlign: TextAlign.center,
              style: context.tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('personalDatabaseTemplateEditor.addProperty'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTypeSheet extends StatefulWidget {
  const _TemplateTypeSheet({required this.title, required this.initialType});

  final String title;
  final PersonalDatabaseValueType? initialType;

  @override
  State<_TemplateTypeSheet> createState() => _TemplateTypeSheetState();
}

class _TemplateTypeSheetState extends State<_TemplateTypeSheet> {
  PersonalDatabaseValueType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetKeyboardInset(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownMenu<PersonalDatabaseValueType?>(
            initialSelection: _selectedType,
            width: double.infinity,
            label: Text('personTodo.database.sheet.type'.tr()),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            onSelected: (type) {
              setState(() {
                _selectedType = type;
              });
            },
            dropdownMenuEntries: [
              DropdownMenuEntry(
                value: null,
                label: 'databasePropertyManager.arrayElement.unspecified'.tr(),
              ),
              ...PersonalDatabaseValueType.values.map(
                (type) => DropdownMenuEntry(
                  value: type,
                  label: type.localizationKey.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selectedType),
            child: Text('databasePropertyManager.elementTypeDialog.save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _RoundedTypeTag extends StatelessWidget {
  const _RoundedTypeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: context.tt.labelMedium?.copyWith(
            color: context.cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TemplateDocument {
  const _TemplateDocument(this.values, this.arrayMetadata);

  factory _TemplateDocument.parse(Map<String, Object?> raw) {
    final values = <String, Object?>{};
    final metadata = <String, _ArrayTemplateMetadata>{};
    final rawMetadata = _asStringKeyedMap(
      raw[personalDatabaseArrayTemplateMetadataKey],
    );

    for (final entry in raw.entries) {
      if (entry.key == personalDatabaseArrayTemplateMetadataKey) {
        continue;
      }
      values[entry.key] = entry.value;
    }

    if (rawMetadata != null) {
      for (final entry in rawMetadata.entries) {
        final item = _ArrayTemplateMetadata.tryParse(entry.value);
        if (item != null) {
          metadata[entry.key] = item;
        }
      }
    }

    return _TemplateDocument(values, metadata);
  }

  final Map<String, Object?> values;
  final Map<String, _ArrayTemplateMetadata> arrayMetadata;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{...values};
    final metadataJson = <String, Object?>{};

    for (final entry in arrayMetadata.entries) {
      if (_valueTypeFromValue(values[entry.key]) !=
          PersonalDatabaseValueType.list) {
        continue;
      }
      metadataJson[entry.key] = entry.value.toJson();
    }

    if (metadataJson.isNotEmpty) {
      json[personalDatabaseArrayTemplateMetadataKey] = metadataJson;
    }
    return json;
  }
}

class _ArrayTemplateMetadata {
  const _ArrayTemplateMetadata({required this.elementType, this.template});

  static _ArrayTemplateMetadata? tryParse(Object? value) {
    final map = _asStringKeyedMap(value);
    if (map == null) {
      return null;
    }
    final elementTypeKey = map['elementType'];
    if (elementTypeKey is! String) {
      return null;
    }
    final elementType = personalDatabaseValueTypeFromDb(elementTypeKey);
    return _ArrayTemplateMetadata(
      elementType: elementType,
      template: elementType == PersonalDatabaseValueType.object
          ? _asStringKeyedMap(map['template']) ?? const <String, Object?>{}
          : null,
    );
  }

  final PersonalDatabaseValueType elementType;
  final Map<String, Object?>? template;

  Map<String, Object?> toJson() {
    return {
      'elementType': elementType.dbKey,
      if (elementType == PersonalDatabaseValueType.object)
        'template': template ?? const <String, Object?>{},
    };
  }
}

Object? _templateValueFromResult(PersonalDatabaseFieldSheetResult result) {
  return switch (result.type) {
    PersonalDatabaseValueType.object =>
      _asStringKeyedMap(result.value) ?? const <String, Object?>{},
    PersonalDatabaseValueType.list =>
      result.value is List ? result.value : const <Object?>[],
    _ => result.value,
  };
}

PersonalDatabaseValueType _valueTypeFromValue(Object? value) {
  return personalDatabaseValueTypeFromValue(value);
}

Map<String, Object?>? _asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }
  return null;
}

bool _isInvalidTemplateKey(String key) {
  return key.isEmpty || key == personalDatabaseArrayTemplateMetadataKey;
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
  if (value is List) {
    return '[${value.length}]';
  }
  if (value is Map) {
    return '{${value.length}}';
  }
  return jsonEncode(value);
}

BorderRadius _tileBorderRadiusFor({required int index, required int length}) {
  if (length == 1) {
    return BorderRadius.circular(
      _PersonalDatabaseArrayTemplateEditorPageState._tileOuterRadius,
    );
  }
  if (index == 0) {
    return const BorderRadius.only(
      topLeft: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileOuterRadius,
      ),
      topRight: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileOuterRadius,
      ),
      bottomLeft: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileInnerRadius,
      ),
      bottomRight: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileInnerRadius,
      ),
    );
  }
  if (index == length - 1) {
    return const BorderRadius.only(
      topLeft: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileInnerRadius,
      ),
      topRight: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileInnerRadius,
      ),
      bottomLeft: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileOuterRadius,
      ),
      bottomRight: Radius.circular(
        _PersonalDatabaseArrayTemplateEditorPageState._tileOuterRadius,
      ),
    );
  }
  return BorderRadius.circular(
    _PersonalDatabaseArrayTemplateEditorPageState._tileInnerRadius,
  );
}
