import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trace/shared/widgets/bottom_sheet_keyboard_inset.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../data/models/personal_database_value_type.dart';

class PersonalDatabaseFieldSheetResult {
  const PersonalDatabaseFieldSheetResult({
    this.key,
    required this.type,
    required this.value,
  });

  final String? key;
  final PersonalDatabaseValueType type;
  final Object? value;
}

Future<PersonalDatabaseFieldSheetResult?> showPersonalDatabaseFieldSheet({
  required BuildContext context,
  required String title,
  required String submitLabel,
  required bool showKeyInput,
  String? initialKey,
  PersonalDatabaseValueType initialType = PersonalDatabaseValueType.string,
  Object? initialValue,
}) {
  return showModalBottomSheet<PersonalDatabaseFieldSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    requestFocus: false,
    backgroundColor: context.cs.surface,
    builder: (_) => _PersonalDatabaseFieldSheet(
      title: title,
      submitLabel: submitLabel,
      showKeyInput: showKeyInput,
      initialKey: initialKey,
      initialType: initialType,
      initialValue: initialValue,
    ),
  );
}

class _PersonalDatabaseFieldSheet extends StatefulWidget {
  const _PersonalDatabaseFieldSheet({
    required this.title,
    required this.submitLabel,
    required this.showKeyInput,
    required this.initialType,
    this.initialKey,
    this.initialValue,
  });

  final String title;
  final String submitLabel;
  final bool showKeyInput;
  final String? initialKey;
  final PersonalDatabaseValueType initialType;
  final Object? initialValue;

  @override
  State<_PersonalDatabaseFieldSheet> createState() =>
      _PersonalDatabaseFieldSheetState();
}

class _PersonalDatabaseFieldSheetState
    extends State<_PersonalDatabaseFieldSheet> {
  static const _sheetFocusDelay = Duration(milliseconds: 220);

  late final TextEditingController _keyController;
  late final TextEditingController _valueController;
  late final FocusNode _keyFocusNode;
  late final FocusNode _valueFocusNode;
  late PersonalDatabaseValueType _type;
  bool _boolValue = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _valueController = TextEditingController(
      text: _initialValueText(
        value: widget.initialValue,
        type: widget.initialType,
      ),
    );
    _keyFocusNode = FocusNode();
    _valueFocusNode = FocusNode();
    _type = widget.initialType;
    _boolValue = widget.initialValue == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_sheetFocusDelay, () {
        if (!mounted) {
          return;
        }
        _initialFocusNode()?.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _keyFocusNode.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetKeyboardInset(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (widget.showKeyInput) ...[
            TextField(
              controller: _keyController,
              focusNode: _keyFocusNode,
              onChanged: (_) => _clearError(),
              decoration: InputDecoration(
                labelText: 'personTodo.database.sheet.key'.tr(),
                filled: true,
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          DropdownMenu<PersonalDatabaseValueType>(
            initialSelection: _type,
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
              if (type == null) {
                return;
              }
              AppHaptics.selection();
              setState(() {
                _type = type;
                _valueController.text = _defaultValueTextByType(type);
                if (type == PersonalDatabaseValueType.boolean) {
                  _boolValue = false;
                }
                _clearError();
              });
            },
            dropdownMenuEntries: PersonalDatabaseValueType.values
                .map(
                  (type) => DropdownMenuEntry(
                    value: type,
                    label: type.localizationKey.tr(),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          _buildValueInput(context),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: context.tt.bodySmall?.copyWith(color: context.cs.error),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueInput(BuildContext context) {
    if (_type == PersonalDatabaseValueType.boolean) {
      return SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: true,
            label: Text('personTodo.database.sheet.boolTrue'.tr()),
          ),
          ButtonSegment(
            value: false,
            label: Text('personTodo.database.sheet.boolFalse'.tr()),
          ),
        ],
        selected: {_boolValue},
        onSelectionChanged: (selection) {
          AppHaptics.selection();
          setState(() {
            _boolValue = selection.first;
          });
        },
      );
    }

    if (_type == PersonalDatabaseValueType.nullType) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'personTodo.database.sheet.nullValue'.tr(),
          style: context.tt.bodyMedium?.copyWith(
            color: context.cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final isJsonInput = _type.isContainer;
    return TextField(
      controller: _valueController,
      focusNode: _valueFocusNode,
      minLines: isJsonInput ? 4 : 1,
      maxLines: isJsonInput ? 8 : 1,
      onChanged: (_) => _clearError(),
      keyboardType: _type == PersonalDatabaseValueType.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.multiline,
      decoration: InputDecoration(
        labelText: 'personTodo.database.sheet.value'.tr(),
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  void _submit() {
    final keyText = _keyController.text.trim();
    if (widget.showKeyInput && keyText.isEmpty) {
      setState(() {
        _errorText = 'personTodo.database.sheet.keyRequired'.tr();
      });
      return;
    }

    final parsedValue = _parseValue();
    if (parsedValue == null && _type != PersonalDatabaseValueType.nullType) {
      return;
    }

    AppHaptics.confirm();
    Navigator.of(context).pop(
      PersonalDatabaseFieldSheetResult(
        key: widget.showKeyInput ? keyText : null,
        type: _type,
        value: parsedValue,
      ),
    );
  }

  Object? _parseValue() {
    switch (_type) {
      case PersonalDatabaseValueType.string:
        return _valueController.text;
      case PersonalDatabaseValueType.number:
        final parsed = num.tryParse(_valueController.text.trim());
        if (parsed != null) {
          return parsed;
        }
        setState(() {
          _errorText = 'personTodo.database.sheet.invalidNumber'.tr();
        });
        return null;
      case PersonalDatabaseValueType.boolean:
        return _boolValue;
      case PersonalDatabaseValueType.nullType:
        return null;
      case PersonalDatabaseValueType.list:
        final raw = _valueController.text.trim();
        if (raw.isEmpty) {
          return const <Object?>[];
        }
        try {
          final parsed = jsonDecode(raw);
          if (parsed is List) {
            return parsed;
          }
        } catch (_) {
          // fall through
        }
        setState(() {
          _errorText = 'personTodo.database.sheet.invalidList'.tr();
        });
        return null;
      case PersonalDatabaseValueType.object:
        final raw = _valueController.text.trim();
        if (raw.isEmpty) {
          return const <String, Object?>{};
        }
        try {
          final parsed = jsonDecode(raw);
          if (parsed is Map<String, dynamic>) {
            return parsed;
          }
          if (parsed is Map) {
            return parsed.map((key, value) => MapEntry('$key', value));
          }
        } catch (_) {
          // fall through
        }
        setState(() {
          _errorText = 'personTodo.database.sheet.invalidObject'.tr();
        });
        return null;
    }
  }

  void _clearError() {
    if (_errorText == null) {
      return;
    }
    setState(() {
      _errorText = null;
    });
  }

  FocusNode? _initialFocusNode() {
    if (widget.showKeyInput) {
      return _keyFocusNode;
    }
    if (_type == PersonalDatabaseValueType.boolean ||
        _type == PersonalDatabaseValueType.nullType) {
      return null;
    }
    return _valueFocusNode;
  }
}

String _initialValueText({
  required Object? value,
  required PersonalDatabaseValueType type,
}) {
  if (value == null) {
    return _defaultValueTextByType(type);
  }
  return switch (type) {
    PersonalDatabaseValueType.string => value.toString(),
    PersonalDatabaseValueType.number => value.toString(),
    PersonalDatabaseValueType.boolean => value == true ? 'true' : 'false',
    PersonalDatabaseValueType.nullType => 'null',
    PersonalDatabaseValueType.list => jsonEncode(value),
    PersonalDatabaseValueType.object => jsonEncode(value),
  };
}

String _defaultValueTextByType(PersonalDatabaseValueType type) {
  return switch (type) {
    PersonalDatabaseValueType.string => '',
    PersonalDatabaseValueType.number => '0',
    PersonalDatabaseValueType.boolean => 'false',
    PersonalDatabaseValueType.nullType => 'null',
    PersonalDatabaseValueType.list => '[\n  \n]',
    PersonalDatabaseValueType.object => '{\n  \n}',
  };
}
