import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trace/shared/widgets/bottom_sheet_keyboard_inset.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../media_library/data/models/media_asset_kind.dart';
import '../../../media_library/data/services/media_asset_picker.dart';
import '../../../media_library/presentation/pages/select_media_library_page.dart';
import '../../../media_library/providers/media_library_providers.dart';
import '../../data/models/personal_database_media_value.dart';
import '../../data/models/personal_database_mention.dart';
import '../../data/models/personal_database_mention_suggestion.dart';
import '../../data/models/personal_database_value_type.dart';
import 'personal_database_mention_input.dart';

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
  bool showTypeInput = true,
  bool showValueInput = true,
  String? readOnlyKeyText,
  String? readOnlyTypeText,
  String? initialKey,
  PersonalDatabaseValueType initialType = PersonalDatabaseValueType.string,
  Object? initialValue,
  List<PersonalDatabaseMentionSuggestion> mentionSuggestions = const [],
  PersonalDatabaseMentionSuggestionSelected? onMentionSelected,
  PersonalDatabaseMentionCodec mentionCodec =
      const PersonalDatabaseMentionCodec(),
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
      showTypeInput: showTypeInput,
      showValueInput: showValueInput,
      readOnlyKeyText: readOnlyKeyText,
      readOnlyTypeText: readOnlyTypeText,
      initialKey: initialKey,
      initialType: initialType,
      initialValue: initialValue,
      mentionSuggestions: mentionSuggestions,
      onMentionSelected: onMentionSelected,
      mentionCodec: mentionCodec,
    ),
  );
}

class _PersonalDatabaseFieldSheet extends ConsumerStatefulWidget {
  const _PersonalDatabaseFieldSheet({
    required this.title,
    required this.submitLabel,
    required this.showKeyInput,
    required this.showTypeInput,
    required this.showValueInput,
    this.readOnlyKeyText,
    this.readOnlyTypeText,
    required this.initialType,
    required this.mentionSuggestions,
    required this.mentionCodec,
    this.initialKey,
    this.initialValue,
    this.onMentionSelected,
  });

  final String title;
  final String submitLabel;
  final bool showKeyInput;
  final bool showTypeInput;
  final bool showValueInput;
  final String? readOnlyKeyText;
  final String? readOnlyTypeText;
  final String? initialKey;
  final PersonalDatabaseValueType initialType;
  final Object? initialValue;
  final List<PersonalDatabaseMentionSuggestion> mentionSuggestions;
  final PersonalDatabaseMentionSuggestionSelected? onMentionSelected;
  final PersonalDatabaseMentionCodec mentionCodec;

  @override
  ConsumerState<_PersonalDatabaseFieldSheet> createState() =>
      _PersonalDatabaseFieldSheetState();
}

class _PersonalDatabaseFieldSheetState
    extends ConsumerState<_PersonalDatabaseFieldSheet>
    with LateInitMixin<_PersonalDatabaseFieldSheet> {
  static const _sheetFocusDelay = Duration(milliseconds: 220);

  late final TextEditingController _keyController;
  late final TextEditingController _valueController;
  late final FocusNode _keyFocusNode;
  late final FocusNode _valueFocusNode;
  late PersonalDatabaseValueType _type;
  late String _lastValueText;
  late PersonalDatabaseMediaValue _mediaValue;
  bool _boolValue = false;
  bool _isImportingMedia = false;
  bool _suppressMentionTracking = false;
  String? _errorText;
  List<_DraftMentionRange> _stringMentions = const [];

  @override
  void initState() {
    super.initState();
    final initialDraft = _initialStringDraft();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _valueController = TextEditingController(
      text: widget.initialType == PersonalDatabaseValueType.string
          ? initialDraft.text
          : _initialValueText(
              value: widget.initialValue,
              type: widget.initialType,
            ),
    );
    _stringMentions = initialDraft.mentions
        .map(
          (mention) => _DraftMentionRange(
            start: mention.start,
            end: mention.end,
            mention: mention.mention,
          ),
        )
        .toList(growable: true);
    _lastValueText = _valueController.text;
    _valueController.addListener(_handleValueControllerChanged);
    _keyFocusNode = FocusNode();
    _valueFocusNode = FocusNode();
    _type = widget.initialType;
    _boolValue = widget.initialValue == true;
    _mediaValue = personalDatabaseMediaValueFromObject(widget.initialValue);
  }

  @override
  void lateInitState() {
    Future<void>.delayed(_sheetFocusDelay, () {
      if (!mounted) {
        return;
      }
      _initialFocusNode()?.requestFocus();
    });
  }

  @override
  void dispose() {
    _valueController.removeListener(_handleValueControllerChanged);
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
          ] else if (widget.readOnlyKeyText != null) ...[
            _ReadOnlyMetadataField(
              label: 'personTodo.database.sheet.key'.tr(),
              value: widget.readOnlyKeyText!,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.showTypeInput) ...[
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
                  _replaceValueText(
                    _defaultValueTextByType(type),
                    clearMentions: true,
                  );
                  if (type == PersonalDatabaseValueType.boolean) {
                    _boolValue = false;
                  }
                  if (type == PersonalDatabaseValueType.media) {
                    _mediaValue = emptyPersonalDatabaseMediaValue;
                  }
                  _errorText = null;
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
          ] else if (widget.readOnlyTypeText != null) ...[
            _ReadOnlyMetadataField(
              label: 'personTodo.database.sheet.type'.tr(),
              value: widget.readOnlyTypeText!,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.showValueInput) ...[
            _buildValueInput(context),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: context.tt.bodySmall?.copyWith(color: context.cs.error),
              ),
            ],
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

    if (_type == PersonalDatabaseValueType.media) {
      return _buildMediaValueInput(context);
    }

    final isJsonInput = _type.isContainer;
    return PersonalDatabaseMentionTextField(
      controller: _valueController,
      focusNode: _valueFocusNode,
      minLines: isJsonInput ? 4 : 1,
      maxLines: isJsonInput ? 8 : 1,
      onChanged: (_) => _clearError(),
      suggestions: _type == PersonalDatabaseValueType.string
          ? widget.mentionSuggestions
          : const [],
      onSuggestionSelected: _handleMentionSelected,
      keyboardType: _type == PersonalDatabaseValueType.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.multiline,
      labelText: 'personTodo.database.sheet.value'.tr(),
      style: context.tt.bodyLarge,
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

  Widget _buildMediaValueInput(BuildContext context) {
    final valueLabel = _mediaValue.hasFile
        ? _mediaValue.fileName
        : 'personTodo.database.sheet.mediaEmpty'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: _isImportingMedia ? null : _chooseExistingMedia,
                child: Text(
                  'personTodo.database.sheet.chooseExistingMedia'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _isImportingMedia ? null : _chooseMediaInDevice,
                child: Text(
                  'personTodo.database.sheet.chooseMediaInDevice'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            valueLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.tt.bodyMedium?.copyWith(
              color: _mediaValue.hasFile
                  ? context.cs.onSurface
                  : context.cs.onSurfaceVariant,
              fontWeight: _mediaValue.hasFile ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseExistingMedia() async {
    AppHaptics.selection();
    final selectedValue = await showSelectMediaLibraryPage(context: context);
    if (!mounted || selectedValue == null) {
      return;
    }

    setState(() {
      _mediaValue = selectedValue;
      _errorText = null;
    });
  }

  Future<void> _chooseMediaInDevice() async {
    if (_isImportingMedia) {
      return;
    }

    AppHaptics.selection();
    final pickerMode = await _chooseDeviceMediaPickerMode();
    if (!mounted || pickerMode == null) {
      return;
    }

    setState(() {
      _isImportingMedia = true;
    });

    try {
      final importedAssets = await ref
          .read(mediaLibraryActionsProvider)
          .importMediaFiles(mode: pickerMode);
      if (!mounted || importedAssets.isEmpty) {
        return;
      }

      final importedAsset = importedAssets.first;
      setState(() {
        _mediaValue = PersonalDatabaseMediaValue(
          mediaAssetId: importedAsset.id,
          fileName: importedAsset.displayName,
          kind: importedAsset.kind.dbKey,
        );
        _errorText = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'personTodo.database.sheet.mediaImportError'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImportingMedia = false;
        });
      }
    }
  }

  Future<MediaAssetPickerMode?> _chooseDeviceMediaPickerMode() {
    return showModalBottomSheet<MediaAssetPickerMode>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'personTodo.database.sheet.mediaPickerTitle'.tr(),
                    style: sheetContext.tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('mediaLibrary.kind.image'.tr()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(sheetContext).pop(MediaAssetPickerMode.image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text('mediaLibrary.kind.video'.tr()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(sheetContext).pop(MediaAssetPickerMode.video);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.audio_file_outlined),
                  title: Text('mediaLibrary.kind.audio'.tr()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(
                      sheetContext,
                    ).pop(MediaAssetPickerMode.singleAudio);
                  },
                ),
              ],
            ),
          ),
        );
      },
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

    final parsedValue = widget.showValueInput ? _parseValue() : _defaultValue();
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
        return widget.mentionCodec.fromDraft(
          text: _valueController.text,
          mentions: _stringMentions
              .map(
                (mention) => PersonalDatabaseDraftMention(
                  start: mention.start,
                  end: mention.end,
                  mention: mention.mention,
                ),
              )
              .toList(growable: false),
        );
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
      case PersonalDatabaseValueType.media:
        return _mediaValue;
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
    if (!widget.showValueInput) {
      return null;
    }
    if (_type == PersonalDatabaseValueType.boolean ||
        _type == PersonalDatabaseValueType.media ||
        _type == PersonalDatabaseValueType.nullType) {
      return null;
    }
    return _valueFocusNode;
  }

  PersonalDatabaseMentionDraft _initialStringDraft() {
    if (widget.initialType != PersonalDatabaseValueType.string) {
      return const PersonalDatabaseMentionDraft(text: '');
    }

    final rawValue = widget.initialValue;
    if (rawValue == null) {
      return const PersonalDatabaseMentionDraft(text: '');
    }

    final suggestionsById = {
      for (final suggestion in widget.mentionSuggestions)
        suggestion.id: suggestion,
    };
    final segments = widget.mentionCodec.parseSegments('$rawValue');
    if (segments.isEmpty) {
      return const PersonalDatabaseMentionDraft(text: '');
    }

    final buffer = StringBuffer();
    final mentions = <PersonalDatabaseDraftMention>[];
    var offset = 0;

    for (final segment in segments) {
      if (segment case PersonalDatabaseMentionPersonSegment(:final mention)) {
        final latestSuggestion = suggestionsById[mention.personId];
        final displayMention = PersonalDatabasePersonMention(
          personId: mention.personId,
          displayName: latestSuggestion?.name ?? mention.displayName,
        );
        final displayText = displayMention.displayLabel;
        buffer.write(displayText);
        mentions.add(
          PersonalDatabaseDraftMention(
            start: offset,
            end: offset + displayText.length,
            mention: displayMention,
          ),
        );
        offset += displayText.length;
        continue;
      }

      buffer.write(segment.displayText);
      offset += segment.displayText.length;
    }

    return PersonalDatabaseMentionDraft(
      text: buffer.toString(),
      mentions: mentions,
    );
  }

  void _handleValueControllerChanged() {
    final nextText = _valueController.text;
    if (_suppressMentionTracking) {
      _lastValueText = nextText;
      return;
    }

    if (_type == PersonalDatabaseValueType.string) {
      _stringMentions = _updateStringMentions(
        previousText: _lastValueText,
        nextText: nextText,
        mentions: _stringMentions,
      );
    } else if (_stringMentions.isNotEmpty) {
      _stringMentions = const [];
    }

    _lastValueText = nextText;
  }

  void _replaceValueText(String nextText, {required bool clearMentions}) {
    _suppressMentionTracking = true;
    _valueController.value = _valueController.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
    _suppressMentionTracking = false;
    _lastValueText = nextText;
    if (clearMentions) {
      _stringMentions = [];
    }
  }

  void _handleMentionSelected(PersonalDatabaseMentionSuggestion suggestion) {
    final selectionEnd = _valueController.selection.baseOffset;
    final mentionLabel = '@${suggestion.name}';
    final mentionStart = selectionEnd - mentionLabel.length;
    if (mentionStart < 0 ||
        selectionEnd > _valueController.text.length ||
        _type != PersonalDatabaseValueType.string) {
      widget.onMentionSelected?.call(suggestion);
      return;
    }

    final nextMention = _DraftMentionRange(
      start: mentionStart,
      end: selectionEnd,
      mention: PersonalDatabasePersonMention(
        personId: suggestion.id,
        displayName: suggestion.name,
      ),
    );

    _stringMentions = [
      for (final mention in _stringMentions)
        if (mention.end <= nextMention.start ||
            mention.start >= nextMention.end)
          mention,
      nextMention,
    ]..sort((left, right) => left.start.compareTo(right.start));

    widget.onMentionSelected?.call(suggestion);
  }

  Object? _defaultValue() {
    switch (_type) {
      case PersonalDatabaseValueType.string:
        return '';
      case PersonalDatabaseValueType.number:
        return 0;
      case PersonalDatabaseValueType.boolean:
        return false;
      case PersonalDatabaseValueType.media:
        return emptyPersonalDatabaseMediaValue;
      case PersonalDatabaseValueType.nullType:
        return null;
      case PersonalDatabaseValueType.list:
        return const <Object?>[];
      case PersonalDatabaseValueType.object:
        return const <String, Object?>{};
    }
  }
}

class _ReadOnlyMetadataField extends StatelessWidget {
  const _ReadOnlyMetadataField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.tt.labelMedium?.copyWith(
              color: context.cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

List<_DraftMentionRange> _updateStringMentions({
  required String previousText,
  required String nextText,
  required List<_DraftMentionRange> mentions,
}) {
  if (mentions.isEmpty || previousText == nextText) {
    return mentions;
  }

  final maxPrefixLength = previousText.length < nextText.length
      ? previousText.length
      : nextText.length;
  var prefixLength = 0;
  while (prefixLength < maxPrefixLength &&
      previousText.codeUnitAt(prefixLength) ==
          nextText.codeUnitAt(prefixLength)) {
    prefixLength += 1;
  }

  var previousSuffixIndex = previousText.length;
  var nextSuffixIndex = nextText.length;
  while (previousSuffixIndex > prefixLength &&
      nextSuffixIndex > prefixLength &&
      previousText.codeUnitAt(previousSuffixIndex - 1) ==
          nextText.codeUnitAt(nextSuffixIndex - 1)) {
    previousSuffixIndex -= 1;
    nextSuffixIndex -= 1;
  }

  final changedEndInPrevious = previousSuffixIndex;
  final delta = nextText.length - previousText.length;
  final updated = <_DraftMentionRange>[];

  for (final mention in mentions) {
    if (mention.end <= prefixLength) {
      updated.add(mention);
      continue;
    }
    if (mention.start >= changedEndInPrevious) {
      updated.add(
        mention.copyWith(
          start: mention.start + delta,
          end: mention.end + delta,
        ),
      );
      continue;
    }
  }

  return updated;
}

class _DraftMentionRange {
  const _DraftMentionRange({
    required this.start,
    required this.end,
    required this.mention,
  });

  final int start;
  final int end;
  final PersonalDatabasePersonMention mention;

  _DraftMentionRange copyWith({
    int? start,
    int? end,
    PersonalDatabasePersonMention? mention,
  }) {
    return _DraftMentionRange(
      start: start ?? this.start,
      end: end ?? this.end,
      mention: mention ?? this.mention,
    );
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
    PersonalDatabaseValueType.media => personalDatabaseMediaValueFromObject(
      value,
    ).fileName,
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
    PersonalDatabaseValueType.media => '',
    PersonalDatabaseValueType.nullType => 'null',
    PersonalDatabaseValueType.list => '[\n  \n]',
    PersonalDatabaseValueType.object => '{\n  \n}',
  };
}
