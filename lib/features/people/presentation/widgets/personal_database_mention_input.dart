import 'package:flutter/material.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/data/models/personal_database_mention_suggestion.dart';
import 'package:trace/shared/widgets/person_avatar.dart';

typedef PersonalDatabaseMentionSuggestionSelected =
    void Function(PersonalDatabaseMentionSuggestion suggestion);

class PersonalDatabaseMentionTextField extends StatefulWidget {
  const PersonalDatabaseMentionTextField({
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.onChanged,
    required this.suggestions,
    this.onSuggestionSelected,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.decoration,
    this.style,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final ValueChanged<String> onChanged;
  final List<PersonalDatabaseMentionSuggestion> suggestions;
  final PersonalDatabaseMentionSuggestionSelected? onSuggestionSelected;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final TextStyle? style;

  @override
  State<PersonalDatabaseMentionTextField> createState() =>
      _PersonalDatabaseMentionTextFieldState();
}

class _PersonalDatabaseMentionTextFieldState
    extends State<PersonalDatabaseMentionTextField> {
  _ActiveMention? _activeMention;
  bool _suppressListener = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    widget.focusNode.addListener(_handleFocusChanged);
    _recalculateMentionState();
  }

  @override
  void didUpdateWidget(covariant PersonalDatabaseMentionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.suggestions != widget.suggestions) {
      _recalculateMentionState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = _visibleSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _shouldShowSuggestions
              ? Padding(
                  key: const ValueKey('personal-database-mention-panel'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MentionSuggestionPanel(
                    suggestions: visibleSuggestions,
                    onSelected: _handleSuggestionSelected,
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('personal-database-mention-empty'),
                ),
        ),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          style: widget.style,
          decoration:
              widget.decoration ??
              InputDecoration(
                labelText: widget.labelText,
                filled: true,
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
        ),
      ],
    );
  }

  bool get _shouldShowSuggestions =>
      widget.focusNode.hasFocus &&
      _activeMention != null &&
      _visibleSuggestions().isNotEmpty;

  void _handleTextChanged() {
    if (_suppressListener) {
      return;
    }
    widget.onChanged(widget.controller.text);
    _recalculateMentionState();
  }

  void _handleFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _activeMention = null;
      });
      return;
    }
    _recalculateMentionState();
  }

  void _recalculateMentionState() {
    final selection = widget.controller.selection;
    if (!widget.focusNode.hasFocus ||
        !selection.isValid ||
        !selection.isCollapsed) {
      if (_activeMention != null) {
        setState(() {
          _activeMention = null;
        });
      }
      return;
    }

    final cursorOffset = selection.baseOffset;
    if (cursorOffset < 0 || cursorOffset > widget.controller.text.length) {
      if (_activeMention != null) {
        setState(() {
          _activeMention = null;
        });
      }
      return;
    }

    final textBeforeCursor = widget.controller.text.substring(0, cursorOffset);
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) {
      _clearMentionState();
      return;
    }

    final query = textBeforeCursor.substring(atIndex + 1);
    if (query.contains(RegExp(r'\s'))) {
      _clearMentionState();
      return;
    }

    if (atIndex > 0) {
      final boundaryCharacter = textBeforeCursor[atIndex - 1];
      if (!_isMentionBoundary(boundaryCharacter)) {
        _clearMentionState();
        return;
      }
    }

    final nextMention = _ActiveMention(
      start: atIndex,
      end: cursorOffset,
      query: query,
    );

    if (_activeMention == nextMention) {
      return;
    }

    setState(() {
      _activeMention = nextMention;
    });
  }

  void _clearMentionState() {
    if (_activeMention == null) {
      return;
    }
    setState(() {
      _activeMention = null;
    });
  }

  List<PersonalDatabaseMentionSuggestion> _visibleSuggestions() {
    final activeMention = _activeMention;
    if (activeMention == null) {
      return const [];
    }

    final query = activeMention.query.trim().toLowerCase();
    final suggestions = widget.suggestions
        .where((suggestion) {
          if (query.isEmpty) {
            return true;
          }
          return suggestion.name.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return suggestions;
  }

  void _handleSuggestionSelected(PersonalDatabaseMentionSuggestion suggestion) {
    final activeMention = _activeMention;
    if (activeMention == null) {
      return;
    }

    AppHaptics.selection();
    final replacement = '@${suggestion.name}';
    final currentText = widget.controller.text;
    final updatedText = currentText.replaceRange(
      activeMention.start,
      activeMention.end,
      replacement,
    );
    final newSelection = TextSelection.collapsed(
      offset: activeMention.start + replacement.length,
    );

    _suppressListener = true;
    widget.controller.value = widget.controller.value.copyWith(
      text: updatedText,
      selection: newSelection,
      composing: TextRange.empty,
    );
    _suppressListener = false;

    widget.onChanged(updatedText);
    widget.onSuggestionSelected?.call(suggestion);
    setState(() {
      _activeMention = null;
    });
  }
}

class _MentionSuggestionPanel extends StatelessWidget {
  const _MentionSuggestionPanel({
    required this.suggestions,
    required this.onSelected,
  });

  final List<PersonalDatabaseMentionSuggestion> suggestions;
  final PersonalDatabaseMentionSuggestionSelected onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surfaceContainerHigh,
      elevation: 1,
      shadowColor: context.cs.shadow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _MentionSuggestionTile(
              suggestion: suggestion,
              onTap: () => onSelected(suggestion),
            );
          },
        ),
      ),
    );
  }
}

class _MentionSuggestionTile extends StatelessWidget {
  const _MentionSuggestionTile({required this.suggestion, required this.onTap});

  final PersonalDatabaseMentionSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              PersonAvatar(
                name: suggestion.name,
                colorValue: suggestion.colorValue,
                avatarPath: suggestion.avatarPath,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveMention {
  const _ActiveMention({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;

  @override
  bool operator ==(Object other) {
    return other is _ActiveMention &&
        other.start == start &&
        other.end == end &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(start, end, query);
}

bool _isMentionBoundary(String character) {
  if (character.trim().isEmpty) {
    return true;
  }

  return switch (character) {
    '(' ||
    '[' ||
    '{' ||
    ' ' ||
    '\n' ||
    '\t' ||
    ',' ||
    '.' ||
    '-' ||
    '>' => true,
    _ => false,
  };
}
