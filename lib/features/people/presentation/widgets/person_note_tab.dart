import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../media_library/presentation/pages/select_media_library_page.dart';
import '../../../media_library/providers/media_library_providers.dart';
import '../../data/daos/person_notes_dao.dart';
import '../../data/models/person_note_token.dart';
import '../../data/services/person_note_token_codec.dart';
import '../../providers/people_database_providers.dart';
import '../../providers/people_provider.dart';
import '../../providers/person_detail_provider.dart';
import '../../../../shared/widgets/person_avatar.dart';

class PersonNoteTab extends ConsumerStatefulWidget {
  const PersonNoteTab({required this.personId, super.key});

  final String personId;

  @override
  ConsumerState<PersonNoteTab> createState() => _PersonNoteTabState();
}

class _PersonNoteTabState extends ConsumerState<PersonNoteTab>
    with WidgetsBindingObserver {
  static const _saveDelay = Duration(milliseconds: 450);

  final _codec = const PersonNoteTokenCodec();
  late final _PersonNoteTextEditingController _controller;
  late final FocusNode _focusNode;
  late PersonNotesDao _personNotesDao;
  Timer? _saveTimer;
  String? _lastSyncedContent;
  bool _isApplyingRemoteContent = false;
  bool _hasLoadedRemoteContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _controller = _PersonNoteTextEditingController(
      codec: _codec,
      onTokenPressed: _handleTokenPressed,
    );
    _focusNode.addListener(_handleFocusChanged);
    _controller.addListener(_handleNoteChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _personNotesDao = ref.read(personNotesDaoProvider);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleNoteChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(personNoteProvider(widget.personId));
    final peopleAsync = ref.watch(peopleProvider);
    final mediaAsync = ref.watch(_personNoteMediaAssetsProvider);

    final people = peopleAsync.asData?.value ?? const <PeopleData>[];
    final mediaAssets = mediaAsync.asData?.value ?? const <MediaAsset>[];
    _controller.setTokenLookups(
      peopleById: {for (final person in people) person.id: person},
      mediaById: {for (final asset in mediaAssets) asset.id: asset},
    );

    final note = noteAsync.asData?.value;
    if (noteAsync.hasValue) {
      _syncRemoteContent(note?.content ?? '');
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'personTodo.note.hint'.tr(),
              alignLabelWithHint: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _PersonNoteActionBar(
                onPickPerson: () => _insertPersonToken(people),
                onPickMedia: _insertMediaToken,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _syncRemoteContent(String content) {
    if (!_hasLoadedRemoteContent) {
      if (_controller.rawText.isNotEmpty && _controller.rawText != content) {
        _lastSyncedContent = content;
        _hasLoadedRemoteContent = true;
        return;
      }
    } else {
      if (_lastSyncedContent == content ||
          _controller.rawText != _lastSyncedContent) {
        return;
      }
    }

    _isApplyingRemoteContent = true;
    _controller.setRawText(content);
    _isApplyingRemoteContent = false;
    _lastSyncedContent = content;
    _hasLoadedRemoteContent = true;
  }

  void _handleNoteChanged() {
    if (_isApplyingRemoteContent) {
      return;
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _saveNow);
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _saveNow();
    }
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    final content = _controller.rawText;
    if (_lastSyncedContent == content) {
      return;
    }

    await _personNotesDao.upsertNote(
      personId: widget.personId,
      content: content,
    );
    _lastSyncedContent = content;
  }

  Future<void> _insertPersonToken(List<PeopleData> people) async {
    AppHaptics.primaryAction();
    final selectedPerson = await showModalBottomSheet<PeopleData>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _PersonNotePeoplePickerSheet(people: people),
    );

    if (!mounted || selectedPerson == null) {
      return;
    }

    _insertToken(
      PersonNoteToken.person(id: selectedPerson.id, label: selectedPerson.name),
    );
  }

  Future<void> _insertMediaToken() async {
    AppHaptics.primaryAction();
    final selectedMedia = await showSelectMediaLibraryPage(context: context);

    if (!mounted || selectedMedia == null) {
      return;
    }

    _insertToken(
      PersonNoteToken.media(
        id: selectedMedia.mediaAssetId,
        label: selectedMedia.fileName,
      ),
    );
  }

  void _insertToken(PersonNoteToken token) {
    _controller.insertToken(token);
    _focusNode.requestFocus();
  }

  Future<void> _handleTokenPressed(PersonNoteToken token) async {
    switch (token) {
      case PersonNotePersonToken(:final id):
        await _openPersonToken(id);
      case PersonNoteMediaToken(:final id):
        await _openMediaToken(id);
    }
  }

  Future<void> _openPersonToken(String personId) async {
    if (personId == widget.personId) {
      return;
    }

    AppHaptics.primaryAction();
    if (!mounted) {
      return;
    }

    context.push('/people/${Uri.encodeComponent(personId)}');
  }

  Future<void> _openMediaToken(String mediaAssetId) async {
    if (mediaAssetId.trim().isEmpty) {
      _showMediaOpenError();
      return;
    }

    AppHaptics.primaryAction();
    try {
      final asset = await ref
          .read(mediaAssetsDaoProvider)
          .getMediaAssetById(mediaAssetId);
      final filePath = asset?.filePath.trim();
      if (filePath == null || filePath.isEmpty) {
        _showMediaOpenError();
        return;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
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

  void _showMediaOpenError() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('personTodo.database.mediaOpenError'.tr())),
    );
  }
}

final _personNoteMediaAssetsProvider =
    StreamProvider.autoDispose<List<MediaAsset>>((ref) {
      return ref.watch(mediaAssetsDaoProvider).watchMediaAssets();
    });

class _PersonNoteActionBar extends StatelessWidget {
  const _PersonNoteActionBar({
    required this.onPickPerson,
    required this.onPickMedia,
  });

  final VoidCallback onPickPerson;
  final VoidCallback onPickMedia;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surface,
      elevation: 3,
      shadowColor: context.cs.shadow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.alternate_email_rounded, size: 18),
                  label: Text('personTodo.note.personChip'.tr()),
                  onPressed: onPickPerson,
                ),
                ActionChip(
                  avatar: const Icon(Icons.perm_media_outlined, size: 18),
                  label: Text('personTodo.note.mediaChip'.tr()),
                  onPressed: onPickMedia,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonNotePeoplePickerSheet extends StatelessWidget {
  const _PersonNotePeoplePickerSheet({required this.people});

  final List<PeopleData> people;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'personTodo.note.peoplePickerTitle'.tr(),
                style: context.tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: PersonAvatar(
                      name: person.name,
                      colorValue: person.colorValue,
                      avatarPath: person.avatarPath,
                      size: 36,
                    ),
                    title: Text(person.name),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.of(context).pop(person);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonNoteTextEditingController extends TextEditingController {
  _PersonNoteTextEditingController({
    required PersonNoteTokenCodec codec,
    required Future<void> Function(PersonNoteToken token) onTokenPressed,
  }) : _codec = codec,
       _onTokenPressed = onTokenPressed {
    _lastStableValue = value;
    addListener(_normalizeTokenEditing);
  }

  static const _tokenPlaceholder = '\uFFFC';

  final PersonNoteTokenCodec _codec;
  final Future<void> Function(PersonNoteToken token) _onTokenPressed;
  Map<String, PeopleData> _peopleById = const {};
  Map<String, MediaAsset> _mediaById = const {};
  List<_PersonNoteDisplayTokenRange> _tokenRanges = const [];
  late TextEditingValue _lastStableValue;
  bool _isNormalizingTokenEdit = false;

  @override
  void dispose() {
    removeListener(_normalizeTokenEditing);
    super.dispose();
  }

  void setTokenLookups({
    required Map<String, PeopleData> peopleById,
    required Map<String, MediaAsset> mediaById,
  }) {
    _peopleById = peopleById;
    _mediaById = mediaById;
  }

  String get rawText {
    if (_tokenRanges.isEmpty) {
      return text.replaceAll(_tokenPlaceholder, '');
    }

    final rangesByStart = {
      for (final tokenRange in _tokenRanges) tokenRange.start: tokenRange,
    };
    final buffer = StringBuffer();
    var cursor = 0;
    while (cursor < text.length) {
      final tokenRange = rangesByStart[cursor];
      if (tokenRange != null &&
          tokenRange.end <= text.length &&
          text.substring(tokenRange.start, tokenRange.end) ==
              _tokenPlaceholder) {
        buffer.write(_codec.encodeToken(tokenRange.token));
        cursor = tokenRange.end;
        continue;
      }

      final character = text.substring(cursor, cursor + 1);
      if (character != _tokenPlaceholder) {
        buffer.write(character);
      }
      cursor += 1;
    }
    return buffer.toString();
  }

  void setRawText(String rawText) {
    final display = _displayValueFromRaw(rawText);
    _isNormalizingTokenEdit = true;
    _tokenRanges = display.tokenRanges;
    value = value.copyWith(
      text: display.text,
      selection: TextSelection.collapsed(offset: display.text.length),
      composing: TextRange.empty,
    );
    _lastStableValue = value;
    _isNormalizingTokenEdit = false;
  }

  void insertToken(PersonNoteToken token) {
    final selection = this.selection;
    final textLength = text.length;
    final start = selection.isValid
        ? selection.start.clamp(0, textLength).toInt()
        : textLength;
    final end = selection.isValid
        ? selection.end.clamp(0, textLength).toInt()
        : textLength;
    final normalizedStart = start <= end ? start : end;
    final normalizedEnd = start <= end ? end : start;
    final updated = _codec.insertToken(
      text: text,
      replacementStart: normalizedStart,
      replacementEnd: normalizedEnd,
      token: token,
    );
    final encodedToken = _codec.encodeToken(token);
    final tokenStart = updated.text.indexOf(encodedToken, normalizedStart);
    final displayText = updated.text.replaceRange(
      tokenStart,
      tokenStart + encodedToken.length,
      _tokenPlaceholder,
    );
    final displayCaretOffset =
        updated.caretOffset - encodedToken.length + _tokenPlaceholder.length;
    final displayTokenStart = tokenStart;
    final displayTokenEnd = displayTokenStart + _tokenPlaceholder.length;
    final updatedRanges =
        _rangesAfterReplacing(
          start: normalizedStart,
          end: normalizedEnd,
          replacementLength: displayCaretOffset - normalizedStart,
        )..add(
          _PersonNoteDisplayTokenRange(
            start: displayTokenStart,
            end: displayTokenEnd,
            token: token,
          ),
        );
    updatedRanges.sort((left, right) => left.start.compareTo(right.start));

    _isNormalizingTokenEdit = true;
    _tokenRanges = updatedRanges;
    value = value.copyWith(
      text: displayText,
      selection: TextSelection.collapsed(offset: displayCaretOffset),
      composing: TextRange.empty,
    );
    _lastStableValue = value;
    _isNormalizingTokenEdit = false;
  }

  void _normalizeTokenEditing() {
    if (_isNormalizingTokenEdit) {
      return;
    }

    final currentValue = value;
    _syncTokenRangesWithPlainTextEdit(
      previous: _lastStableValue,
      current: currentValue,
    );
    _lastStableValue = currentValue;
  }

  void _syncTokenRangesWithPlainTextEdit({
    required TextEditingValue previous,
    required TextEditingValue current,
  }) {
    if (previous.text == current.text || _tokenRanges.isEmpty) {
      return;
    }

    final diff = _TextEditDiff.between(previous.text, current.text);
    if (diff == null) {
      return;
    }

    _tokenRanges = _rangesAfterReplacing(
      start: diff.previousStart,
      end: diff.previousEnd,
      replacementLength: diff.insertedText.length,
    );
  }

  List<_PersonNoteDisplayTokenRange> _rangesAfterReplacing({
    required int start,
    required int end,
    required int replacementLength,
    List<_PersonNoteDisplayTokenRange>? sourceRanges,
  }) {
    final ranges = sourceRanges ?? _tokenRanges;
    final removedLength = end - start;
    final delta = replacementLength - removedLength;
    final updatedRanges = <_PersonNoteDisplayTokenRange>[];

    for (final tokenRange in ranges) {
      if (tokenRange.end <= start) {
        updatedRanges.add(tokenRange);
        continue;
      }
      if (tokenRange.start >= end) {
        updatedRanges.add(tokenRange.shift(delta));
      }
    }

    return updatedRanges;
  }

  _PersonNoteDisplayValue _displayValueFromRaw(String rawText) {
    final buffer = StringBuffer();
    final ranges = <_PersonNoteDisplayTokenRange>[];
    var cursor = 0;

    for (final rawRange in _codec.parseTokenRanges(rawText)) {
      buffer.write(rawText.substring(cursor, rawRange.start));
      final tokenStart = buffer.length;
      buffer.write(_tokenPlaceholder);
      ranges.add(
        _PersonNoteDisplayTokenRange(
          start: tokenStart,
          end: tokenStart + _tokenPlaceholder.length,
          token: rawRange.token,
        ),
      );
      cursor = rawRange.end;
    }

    buffer.write(rawText.substring(cursor));
    return _PersonNoteDisplayValue(
      text: buffer.toString(),
      tokenRanges: ranges,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    final rangesByStart = {
      for (final tokenRange in _tokenRanges) tokenRange.start: tokenRange,
    };

    while (cursor < text.length) {
      final tokenRange = rangesByStart[cursor];
      if (tokenRange != null &&
          tokenRange.end <= text.length &&
          text.substring(tokenRange.start, tokenRange.end) ==
              _tokenPlaceholder) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _PersonNoteInlineTokenChip(
              onPressed: () => _onTokenPressed(tokenRange.token),
              icon: switch (tokenRange.token) {
                PersonNotePersonToken() => Icons.person_rounded,
                PersonNoteMediaToken() => Icons.perm_media_outlined,
              },
              label: _labelForToken(tokenRange.token),
            ),
          ),
        );
        cursor = tokenRange.end;
        continue;
      }

      children.add(TextSpan(text: text.substring(cursor, cursor + 1)));
      cursor += 1;
    }

    return TextSpan(style: style, children: children);
  }

  String _labelForToken(PersonNoteToken token) {
    return switch (token) {
      PersonNotePersonToken(:final id, :final label) =>
        _peopleById[id]?.name ?? label,
      PersonNoteMediaToken(:final id, :final label) =>
        _mediaById[id]?.displayName ?? label,
    };
  }
}

class _PersonNoteDisplayValue {
  const _PersonNoteDisplayValue({
    required this.text,
    required this.tokenRanges,
  });

  final String text;
  final List<_PersonNoteDisplayTokenRange> tokenRanges;
}

class _PersonNoteDisplayTokenRange {
  const _PersonNoteDisplayTokenRange({
    required this.start,
    required this.end,
    required this.token,
  });

  final int start;
  final int end;
  final PersonNoteToken token;

  _PersonNoteDisplayTokenRange shift(int delta) {
    if (delta == 0) {
      return this;
    }
    return _PersonNoteDisplayTokenRange(
      start: start + delta,
      end: end + delta,
      token: token,
    );
  }
}

class _TextEditDiff {
  const _TextEditDiff({
    required this.previousStart,
    required this.previousEnd,
    required this.insertedText,
  });

  final int previousStart;
  final int previousEnd;
  final String insertedText;

  bool get isInsertion =>
      previousStart == previousEnd && insertedText.isNotEmpty;

  static _TextEditDiff? between(String previousText, String currentText) {
    if (previousText == currentText) {
      return null;
    }

    var prefixLength = 0;
    final shortestLength = previousText.length < currentText.length
        ? previousText.length
        : currentText.length;
    while (prefixLength < shortestLength &&
        previousText.codeUnitAt(prefixLength) ==
            currentText.codeUnitAt(prefixLength)) {
      prefixLength += 1;
    }

    var suffixLength = 0;
    while (suffixLength < previousText.length - prefixLength &&
        suffixLength < currentText.length - prefixLength &&
        previousText.codeUnitAt(previousText.length - 1 - suffixLength) ==
            currentText.codeUnitAt(currentText.length - 1 - suffixLength)) {
      suffixLength += 1;
    }

    final previousEnd = previousText.length - suffixLength;
    final currentEnd = currentText.length - suffixLength;
    return _TextEditDiff(
      previousStart: prefixLength,
      previousEnd: previousEnd,
      insertedText: currentText.substring(prefixLength, currentEnd),
    );
  }
}

class _PersonNoteInlineTokenChip extends StatelessWidget {
  const _PersonNoteInlineTokenChip({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.cs.primary,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: context.cs.onPrimary),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.labelMedium?.copyWith(
                      color: context.cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
