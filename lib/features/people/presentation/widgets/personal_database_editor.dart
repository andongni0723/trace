import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/useful_extension.dart';
import '../../data/models/personal_database_value_type.dart';

enum PersonalDatabaseEditorAction { addChild, edit, delete }

class PersonalDatabaseEditorRowData {
  const PersonalDatabaseEditorRowData({
    required this.nodeId,
    required this.rootFieldId,
    required this.path,
    required this.keyLabel,
    required this.valuePreview,
    required this.rawValue,
    required this.valueType,
    required this.depth,
    required this.isExpanded,
    required this.isContainer,
    required this.parentIsList,
  });

  final String nodeId;
  final String rootFieldId;
  final List<Object> path;
  final String keyLabel;
  final String valuePreview;
  final Object? rawValue;
  final PersonalDatabaseValueType valueType;
  final int depth;
  final bool isExpanded;
  final bool isContainer;
  final bool parentIsList;
}

class PersonalDatabaseEditor extends StatelessWidget {
  const PersonalDatabaseEditor({
    required this.rows,
    required this.padding,
    required this.onPressedValue,
    required this.onPressedAction,
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

class _PersonalDatabaseEditorRow extends StatelessWidget {
  const _PersonalDatabaseEditorRow({
    required this.row,
    required this.position,
    required this.onPressedValue,
    required this.onPressedAction,
  });

  final PersonalDatabaseEditorRowData row;
  final _PersonalDatabaseEditorRowPosition position;
  final VoidCallback onPressedValue;
  final ValueChanged<PersonalDatabaseEditorAction> onPressedAction;

  @override
  Widget build(BuildContext context) {
    final paddingLeft = 12.0 + (row.depth * 16.0);
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

    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: borderRadius,
      child: Padding(
        padding: EdgeInsets.fromLTRB(paddingLeft, 6, 6, 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  row.keyLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: row.depth == 0
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
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
                        Expanded(
                          child: Text(
                            row.valuePreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.tt.bodyMedium?.copyWith(
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (row.isContainer) ...[
                          const SizedBox(width: 8),
                          Icon(
                            row.isExpanded
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
              PopupMenuButton<PersonalDatabaseEditorAction>(
                onSelected: onPressedAction,
                itemBuilder: (_) {
                  return [
                    if (row.isContainer)
                      PopupMenuItem(
                        value: PersonalDatabaseEditorAction.addChild,
                        child: Text('personTodo.database.action.addChild'.tr()),
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
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PersonalDatabaseEditorRowPosition { single, first, middle, last }
