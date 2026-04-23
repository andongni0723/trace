import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../data/models/personal_database_value_type.dart';

enum PersonalDatabaseEditorAction {
  addChild,
  addFromTemplate,
  editTemplate,
  edit,
  delete,
}

class PersonalDatabaseEditorRowData {
  const PersonalDatabaseEditorRowData({
    required this.nodeId,
    required this.fieldId,
    required this.rootFieldId,
    required this.path,
    required this.keyLabel,
    required this.valuePreview,
    required this.rawValue,
    required this.valueType,
    required this.depth,
    required this.isExpanded,
    required this.isContainer,
    required this.isDefinitionBacked,
    required this.parentIsList,
    this.isValueEnabled = true,
    this.canAddFromTemplate = false,
    this.canEditTemplate = false,
    this.valueSegments = const [],
  });

  final String nodeId;
  final String fieldId;
  final String rootFieldId;
  final List<Object> path;
  final String keyLabel;
  final String valuePreview;
  final Object? rawValue;
  final PersonalDatabaseValueType valueType;
  final int depth;
  final bool isExpanded;
  final bool isContainer;
  final bool isDefinitionBacked;
  final bool parentIsList;
  final bool isValueEnabled;
  final bool canAddFromTemplate;
  final bool canEditTemplate;
  final List<PersonalDatabaseEditorValueSegment> valueSegments;
}

class PersonalDatabaseEditorValueSegment {
  const PersonalDatabaseEditorValueSegment({required this.text, this.personId});

  final String text;
  final String? personId;

  bool get isMention => personId != null;
}

class PersonalDatabaseEditor extends StatelessWidget {
  const PersonalDatabaseEditor({
    required this.rows,
    required this.padding,
    required this.onPressedValue,
    required this.onPressedAction,
    required this.onPressedMention,
    super.key,
  });

  final List<PersonalDatabaseEditorRowData> rows;
  final EdgeInsets padding;
  final ValueChanged<PersonalDatabaseEditorRowData> onPressedValue;
  final void Function(
    PersonalDatabaseEditorRowData row,
    PersonalDatabaseEditorAction action,
  )
  onPressedAction;
  final ValueChanged<String> onPressedMention;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        Text(
          'personTodo.database.title'.tr(),
          style: context.tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty) const _EmptyState() else ..._buildRows(context),
      ],
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    return [
      for (var index = 0; index < rows.length; index++) ...[
        _PersonalDatabaseEditorRow(
          row: rows[index],
          position: _positionForIndex(index),
          onPressedValue: () => onPressedValue(rows[index]),
          onPressedAction: (action) => onPressedAction(rows[index], action),
          onPressedMention: onPressedMention,
        ),
        if (index != rows.length - 1) const SizedBox(height: 4),
      ],
    ];
  }

  _PersonalDatabaseEditorRowPosition _positionForIndex(int index) {
    if (rows.length == 1) {
      return _PersonalDatabaseEditorRowPosition.single;
    }
    if (index == 0) {
      return _PersonalDatabaseEditorRowPosition.first;
    }
    if (index == rows.length - 1) {
      return _PersonalDatabaseEditorRowPosition.last;
    }
    return _PersonalDatabaseEditorRowPosition.middle;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'personTodo.database.emptyTitle'.tr(),
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'personTodo.database.emptyBody'.tr(),
            style: context.tt.bodyMedium?.copyWith(
              color: context.cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalDatabasePropertyRow<T> extends StatelessWidget {
  const PersonalDatabasePropertyRow({
    required this.leading,
    required this.value,
    required this.borderRadius,
    this.depth = 0,
    this.leadingFlex = 4,
    this.valueFlex = 5,
    this.isContainer = false,
    this.isExpanded = false,
    this.onPressedValue,
    this.onSelectedMenu,
    this.itemBuilder,
    super.key,
  });

  final Widget leading;
  final Widget value;
  final BorderRadius borderRadius;
  final int depth;
  final int leadingFlex;
  final int valueFlex;
  final bool isContainer;
  final bool isExpanded;
  final VoidCallback? onPressedValue;
  final PopupMenuItemSelected<T>? onSelectedMenu;
  final PopupMenuItemBuilder<T>? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final paddingLeft = 12.0 + (depth * 16.0);

    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: borderRadius,
      child: Padding(
        padding: EdgeInsets.fromLTRB(paddingLeft, 6, 6, 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(flex: leadingFlex, child: leading),
              const SizedBox(width: 12),
              Expanded(
                flex: valueFlex,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: onPressedValue,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: value),
                        if (isContainer) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: context.cs.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (itemBuilder != null)
                PopupMenuButton<T>(
                  onSelected: onSelectedMenu,
                  itemBuilder: itemBuilder!,
                  icon: const Icon(Icons.more_vert_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalDatabaseEditorRow extends StatelessWidget {
  const _PersonalDatabaseEditorRow({
    required this.row,
    required this.position,
    required this.onPressedValue,
    required this.onPressedAction,
    required this.onPressedMention,
  });

  final PersonalDatabaseEditorRowData row;
  final _PersonalDatabaseEditorRowPosition position;
  final VoidCallback onPressedValue;
  final ValueChanged<PersonalDatabaseEditorAction> onPressedAction;
  final ValueChanged<String> onPressedMention;

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (position) {
      _PersonalDatabaseEditorRowPosition.single => BorderRadius.circular(24),
      _PersonalDatabaseEditorRowPosition.first => const BorderRadius.vertical(
        top: Radius.circular(24),
        bottom: Radius.circular(4),
      ),
      _PersonalDatabaseEditorRowPosition.middle => BorderRadius.circular(4),
      _PersonalDatabaseEditorRowPosition.last => const BorderRadius.vertical(
        top: Radius.circular(4),
        bottom: Radius.circular(24),
      ),
    };

    return PersonalDatabasePropertyRow<PersonalDatabaseEditorAction>(
      borderRadius: borderRadius,
      depth: row.depth,
      isContainer: row.isContainer,
      isExpanded: row.isExpanded,
      onPressedValue: row.isValueEnabled ? onPressedValue : null,
      onSelectedMenu: onPressedAction,
      itemBuilder: (_) {
        final addChildLabel = row.valueType == PersonalDatabaseValueType.list
            ? 'personTodo.database.action.addElement'.tr()
            : 'personTodo.database.action.addChild'.tr();
        return [
          if (row.canAddFromTemplate)
            PopupMenuItem(
              value: PersonalDatabaseEditorAction.addFromTemplate,
              child: Text('personTodo.database.action.addFromTemplate'.tr()),
            ),
          if (row.isContainer)
            PopupMenuItem(
              value: PersonalDatabaseEditorAction.addChild,
              child: Text(addChildLabel),
            ),
          if (row.canEditTemplate)
            PopupMenuItem(
              value: PersonalDatabaseEditorAction.editTemplate,
              child: Text('personTodo.database.action.editTemplate'.tr()),
            ),
          PopupMenuItem(
            value: PersonalDatabaseEditorAction.edit,
            child: Text('personTodo.database.action.edit'.tr()),
          ),
          PopupMenuItem(
            value: PersonalDatabaseEditorAction.delete,
            child: Text('personTodo.database.action.delete'.tr()),
          ),
        ];
      },
      leading: Text(
        row.keyLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.tt.titleSmall?.copyWith(
          fontWeight: row.depth == 0 ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      value: _PersonalDatabaseEditorValueText(
        row: row,
        onPressedMention: onPressedMention,
      ),
    );
  }
}

class _PersonalDatabaseEditorValueText extends StatelessWidget {
  const _PersonalDatabaseEditorValueText({
    required this.row,
    required this.onPressedMention,
  });

  final PersonalDatabaseEditorRowData row;
  final ValueChanged<String> onPressedMention;

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.tt.bodyMedium?.copyWith(
      color: context.cs.onSurfaceVariant,
    );
    if (row.valueSegments.isEmpty) {
      return Text(
        row.valuePreview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          for (final segment in row.valueSegments)
            if (segment.isMention)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                baseline: TextBaseline.alphabetic,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    AppHaptics.primaryAction();
                    onPressedMention(segment.personId!);
                  },
                  child: Text(
                    segment.text,
                    style: baseStyle?.copyWith(
                      color: context.cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              TextSpan(text: segment.text),
        ],
        style: baseStyle,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

enum _PersonalDatabaseEditorRowPosition { single, first, middle, last }
