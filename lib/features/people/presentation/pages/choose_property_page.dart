import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/data/models/personal_database_field_node.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';

class ChoosePropertyPage extends StatefulWidget {
  const ChoosePropertyPage({
    required this.properties,
    this.onRenameProperty,
    this.onDeleteProperty,
    super.key,
  });

  final List<ChoosePropertyItem> properties;
  final Future<ChoosePropertyItem?> Function(
    ChoosePropertyItem item,
    String newTitle,
  )?
  onRenameProperty;
  final Future<void> Function(ChoosePropertyItem item)? onDeleteProperty;

  @override
  State<ChoosePropertyPage> createState() => _ChoosePropertyPageState();
}

class ChoosePropertyItem {
  const ChoosePropertyItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.valueType,
    required this.rawValue,
    required this.valuePreview,
    this.parentId,
    this.children = const [],
    this.isAssignedToCurrentPerson = false,
  });

  factory ChoosePropertyItem.fromFieldNode(
    PersonalDatabaseFieldNode field, {
    Set<String> assignedFieldIds = const <String>{},
  }) {
    return ChoosePropertyItem(
      id: field.id,
      title: field.key,
      subtitle: field.type.localizationKey.tr(),
      valueType: field.type,
      rawValue: field.value,
      valuePreview: _valuePreview(field.value),
      parentId: field.parentFieldId,
      children: field.children
          .map(
            (child) => ChoosePropertyItem.fromFieldNode(
              child,
              assignedFieldIds: assignedFieldIds,
            ),
          )
          .toList(growable: false),
      isAssignedToCurrentPerson: assignedFieldIds.contains(field.id),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final PersonalDatabaseValueType valueType;
  final Object? rawValue;
  final String valuePreview;
  final String? parentId;
  final List<ChoosePropertyItem> children;
  final bool isAssignedToCurrentPerson;

  bool get hasChildren => children.isNotEmpty;
  bool get isContainer => hasChildren || valueType.isContainer;

  ChoosePropertyItem copyWith({
    String? title,
    String? subtitle,
    PersonalDatabaseValueType? valueType,
    Object? rawValue,
    String? valuePreview,
    String? parentId,
    List<ChoosePropertyItem>? children,
    bool? isAssignedToCurrentPerson,
  }) {
    return ChoosePropertyItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      valueType: valueType ?? this.valueType,
      rawValue: rawValue ?? this.rawValue,
      valuePreview: valuePreview ?? this.valuePreview,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      isAssignedToCurrentPerson:
          isAssignedToCurrentPerson ?? this.isAssignedToCurrentPerson,
    );
  }
}

sealed class ChoosePropertyResult {
  const ChoosePropertyResult();
}

final class ChoosePropertySelected extends ChoosePropertyResult {
  const ChoosePropertySelected(this.items);

  final List<ChoosePropertyItem> items;
}

final class ChoosePropertyCreateNew extends ChoosePropertyResult {
  const ChoosePropertyCreateNew();
}

Future<ChoosePropertyResult?> showChoosePropertyPage({
  required BuildContext context,
  required List<ChoosePropertyItem> properties,
  Future<ChoosePropertyItem?> Function(
    ChoosePropertyItem item,
    String newTitle,
  )?
  onRenameProperty,
  Future<void> Function(ChoosePropertyItem item)? onDeleteProperty,
}) {
  return Navigator.of(context).push<ChoosePropertyResult>(
    MaterialPageRoute(
      builder: (_) => ChoosePropertyPage(
        properties: properties,
        onRenameProperty: onRenameProperty,
        onDeleteProperty: onDeleteProperty,
      ),
    ),
  );
}

class _ChoosePropertyPageState extends State<ChoosePropertyPage> {
  static const _tileOuterRadius = 28.0;
  static const _tileInnerRadius = 4.0;
  static const _tileSpacing = 4.0;
  static const _indentPerDepth = 24.0;

  final TextEditingController _searchController = TextEditingController();
  late List<ChoosePropertyItem> _properties;
  final Set<String> _selectedPropertyIds = <String>{};
  late Map<String, ChoosePropertyItem> _propertyById;
  late Map<String, String?> _parentIdById;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _properties = List<ChoosePropertyItem>.from(widget.properties);
    _refreshPropertyIndexes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = _visibleEntries();

    return Scaffold(
      backgroundColor: context.cs.surface,
      appBar: AppBar(title: Text('personTodo.propertyChooser.title'.tr())),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      query: _query,
                      onQueryChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      controller: _searchController,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'personTodo.propertyChooser.libraryLabel'.tr(),
                      style: context.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (visibleEntries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreateNew: _createNew),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.separated(
                  itemCount: visibleEntries.length + 1,
                  itemBuilder: (context, index) {
                    final position = _tilePositionFor(
                      index: index,
                      length: visibleEntries.length + 1,
                    );

                    if (index == visibleEntries.length) {
                      return _CreateNewTile(
                        onTap: _createNew,
                        borderRadius: _tileBorderRadiusFor(position),
                      );
                    }

                    final entry = visibleEntries[index];
                    final item = entry.item;
                    return _PropertyTile(
                      item: item,
                      depth: entry.depth,
                      selectionState: _selectionStateFor(item),
                      borderRadius: _tileBorderRadiusFor(position),
                      onTap: _canToggle(item)
                          ? () => _toggleSelection(item)
                          : null,
                      onLongPressStart:
                          widget.onRenameProperty != null ||
                              widget.onDeleteProperty != null
                          ? (position) => _openPropertyMenu(
                              item: item,
                              position: position,
                            )
                          : null,
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: _tileSpacing),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton(
          onPressed: _selectedItems().isEmpty ? null : _submitSelection,
          child: Text(
            'personTodo.propertyChooser.apply'.tr(
              namedArgs: {'count': _selectedItems().length.toString()},
            ),
          ),
        ),
      ),
    );
  }

  List<_VisiblePropertyEntry> _visibleEntries() {
    final query = _query.trim().toLowerCase();

    List<_VisiblePropertyEntry> visit(
      List<ChoosePropertyItem> items, {
      required int depth,
    }) {
      final results = <_VisiblePropertyEntry>[];

      for (final item in items) {
        final matchesQuery =
            query.isEmpty ||
            _matchesQuery(item, query) ||
            _hasMatchingDescendant(item, query);
        if (!matchesQuery) {
          continue;
        }

        results.add(_VisiblePropertyEntry(item: item, depth: depth));

        final shouldExpand = item.hasChildren;
        if (!shouldExpand) {
          continue;
        }

        results.addAll(visit(item.children, depth: depth + 1));
      }

      return results;
    }

    return visit(_properties, depth: 0);
  }

  bool _matchesQuery(ChoosePropertyItem item, String query) {
    return item.title.toLowerCase().contains(query) ||
        item.subtitle.toLowerCase().contains(query) ||
        item.valuePreview.toLowerCase().contains(query);
  }

  bool _hasMatchingDescendant(ChoosePropertyItem item, String query) {
    for (final child in item.children) {
      if (_matchesQuery(child, query) || _hasMatchingDescendant(child, query)) {
        return true;
      }
    }
    return false;
  }

  bool _canToggle(ChoosePropertyItem item) {
    if (!item.isAssignedToCurrentPerson) {
      return true;
    }
    return _descendantIdsOf(
      item,
    ).any((id) => !_propertyById[id]!.isAssignedToCurrentPerson);
  }

  void _toggleSelection(ChoosePropertyItem item) {
    if (!_canToggle(item)) {
      return;
    }

    final subtreeIds = _selectableSubtreeIds(item);
    final shouldClear = subtreeIds.every(_selectedPropertyIds.contains);

    AppHaptics.selection();
    setState(() {
      if (shouldClear) {
        _selectedPropertyIds.removeAll(subtreeIds);
      } else {
        _selectedPropertyIds.addAll(subtreeIds);
      }
    });
  }

  void _submitSelection() {
    final selectedItems = _selectedItems();
    if (selectedItems.isEmpty) {
      return;
    }

    AppHaptics.primaryAction();
    Navigator.of(context).pop(ChoosePropertySelected(selectedItems));
  }

  List<ChoosePropertyItem> _selectedItems() {
    final selectedIds = _effectiveSelectedPropertyIds();
    if (selectedIds.isEmpty) {
      return const [];
    }

    final orderedItems = <ChoosePropertyItem>[];
    void visit(List<ChoosePropertyItem> items) {
      for (final item in items) {
        if (selectedIds.contains(item.id) && !item.isAssignedToCurrentPerson) {
          orderedItems.add(item);
        }
        if (item.children.isNotEmpty) {
          visit(item.children);
        }
      }
    }

    visit(_properties);
    return orderedItems;
  }

  Set<String> _effectiveSelectedPropertyIds() {
    final effectiveIds = <String>{..._selectedPropertyIds};
    for (final id in _selectedPropertyIds) {
      var parentId = _parentIdById[id];
      while (parentId != null) {
        final parent = _propertyById[parentId];
        if (parent == null) {
          break;
        }
        if (!parent.isAssignedToCurrentPerson) {
          effectiveIds.add(parentId);
        }
        parentId = _parentIdById[parentId];
      }
    }
    return effectiveIds;
  }

  Set<String> _selectableSubtreeIds(ChoosePropertyItem item) {
    final ids = <String>{};
    void visit(ChoosePropertyItem node) {
      final shouldIncludeCurrentNode = !node.hasChildren || node.id != item.id;
      if (shouldIncludeCurrentNode && !node.isAssignedToCurrentPerson) {
        ids.add(node.id);
      }
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(item);
    return ids;
  }

  Iterable<String> _descendantIdsOf(ChoosePropertyItem item) sync* {
    for (final child in item.children) {
      yield child.id;
      yield* _descendantIdsOf(child);
    }
  }

  _PropertySelectionState _selectionStateFor(ChoosePropertyItem item) {
    final subtreeIds = <String>{item.id, ..._descendantIdsOf(item)};
    final effectiveSelectedIds = _effectiveSelectedPropertyIds();
    final checkedCount = subtreeIds.where((id) {
      final property = _propertyById[id];
      if (property == null) {
        return false;
      }
      return property.isAssignedToCurrentPerson ||
          effectiveSelectedIds.contains(id);
    }).length;

    if (checkedCount == 0) {
      return _PropertySelectionState.unselected;
    }

    if (checkedCount == subtreeIds.length) {
      return _PropertySelectionState.selected;
    }

    return item.hasChildren
        ? _PropertySelectionState.indeterminate
        : _PropertySelectionState.selected;
  }

  Map<String, ChoosePropertyItem> _buildPropertyMap(
    List<ChoosePropertyItem> items,
  ) {
    final map = <String, ChoosePropertyItem>{};

    void visit(List<ChoosePropertyItem> entries) {
      for (final item in entries) {
        map[item.id] = item;
        if (item.children.isNotEmpty) {
          visit(item.children);
        }
      }
    }

    visit(items);
    return map;
  }

  void _refreshPropertyIndexes() {
    _propertyById = _buildPropertyMap(_properties);
    _parentIdById = {
      for (final entry in _propertyById.entries)
        entry.key: entry.value.parentId,
    };
  }

  void _replaceProperties(List<ChoosePropertyItem> nextProperties) {
    _properties = nextProperties;
    _refreshPropertyIndexes();
  }

  List<ChoosePropertyItem> _replacePropertyById(
    List<ChoosePropertyItem> items, {
    required String targetId,
    required ChoosePropertyItem replacement,
  }) {
    return items
        .map((item) {
          if (item.id == targetId) {
            return replacement;
          }
          if (item.children.isEmpty) {
            return item;
          }
          return item.copyWith(
            children: _replacePropertyById(
              item.children,
              targetId: targetId,
              replacement: replacement,
            ),
          );
        })
        .toList(growable: false);
  }

  List<ChoosePropertyItem> _removePropertyById(
    List<ChoosePropertyItem> items, {
    required String targetId,
  }) {
    return items
        .where((item) => item.id != targetId)
        .map((item) {
          if (item.children.isEmpty) {
            return item;
          }
          return item.copyWith(
            children: _removePropertyById(item.children, targetId: targetId),
          );
        })
        .toList(growable: false);
  }

  void _createNew() {
    AppHaptics.primaryAction();
    Navigator.of(context).pop(const ChoosePropertyCreateNew());
  }

  Future<void> _openPropertyMenu({
    required ChoosePropertyItem item,
    required Offset position,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selectedAction = await showMenu<_PropertyMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        if (widget.onRenameProperty != null)
          PopupMenuItem(
            value: _PropertyMenuAction.rename,
            child: Text('personTodo.propertyChooser.menu.editKeyName'.tr()),
          ),
        if (widget.onDeleteProperty != null)
          PopupMenuItem(
            value: _PropertyMenuAction.delete,
            child: Text('personTodo.propertyChooser.menu.deleteProperty'.tr()),
          ),
      ],
    );

    if (!mounted || selectedAction == null) {
      return;
    }

    switch (selectedAction) {
      case _PropertyMenuAction.rename:
        await _renameProperty(item);
      case _PropertyMenuAction.delete:
        await _deleteProperty(item);
    }
  }

  Future<void> _renameProperty(ChoosePropertyItem item) async {
    final newTitle = await _showRenameDialog(item);
    if (!mounted || newTitle == null) {
      return;
    }

    try {
      final updatedItem = await widget.onRenameProperty?.call(item, newTitle);
      if (!mounted || updatedItem == null) {
        return;
      }

      setState(() {
        _replaceProperties(
          _replacePropertyById(
            _properties,
            targetId: item.id,
            replacement: updatedItem,
          ),
        );
      });
      AppHaptics.confirm();
    } catch (_) {
      _showActionError();
    }
  }

  Future<void> _deleteProperty(ChoosePropertyItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('personTodo.propertyChooser.deleteDialog.title'.tr()),
          content: Text(
            'personTodo.propertyChooser.deleteDialog.body'.tr(
              namedArgs: {'key': item.title},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'personTodo.propertyChooser.deleteDialog.cancel'.tr(),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'personTodo.propertyChooser.deleteDialog.delete'.tr(),
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
      await widget.onDeleteProperty?.call(item);
      if (!mounted) {
        return;
      }

      setState(() {
        final removedIds = <String>{item.id, ..._descendantIdsOf(item)};
        _replaceProperties(_removePropertyById(_properties, targetId: item.id));
        _selectedPropertyIds.removeWhere(removedIds.contains);
      });
      AppHaptics.confirm();
    } catch (_) {
      _showActionError();
    }
  }

  Future<String?> _showRenameDialog(ChoosePropertyItem item) async {
    final controller = TextEditingController(text: item.title);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('personTodo.propertyChooser.renameDialog.title'.tr()),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'personTodo.propertyChooser.renameDialog.label'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'personTodo.propertyChooser.renameDialog.cancel'.tr(),
              ),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(trimmed);
              },
              child: Text('personTodo.propertyChooser.renameDialog.save'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showActionError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('personTodo.database.actionError'.tr())),
    );
  }

  _TilePosition _tilePositionFor({required int index, required int length}) {
    if (length == 1) {
      return _TilePosition.single;
    }
    if (index == 0) {
      return _TilePosition.first;
    }
    if (index == length - 1) {
      return _TilePosition.last;
    }
    return _TilePosition.middle;
  }

  BorderRadius _tileBorderRadiusFor(_TilePosition position) {
    switch (position) {
      case _TilePosition.single:
        return BorderRadius.circular(_tileOuterRadius);
      case _TilePosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(_tileOuterRadius),
          topRight: Radius.circular(_tileOuterRadius),
          bottomLeft: Radius.circular(_tileInnerRadius),
          bottomRight: Radius.circular(_tileInnerRadius),
        );
      case _TilePosition.middle:
        return BorderRadius.circular(_tileInnerRadius);
      case _TilePosition.last:
        return const BorderRadius.only(
          topLeft: Radius.circular(_tileInnerRadius),
          topRight: Radius.circular(_tileInnerRadius),
          bottomLeft: Radius.circular(_tileOuterRadius),
          bottomRight: Radius.circular(_tileOuterRadius),
        );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: 'personTodo.propertyChooser.searchHint'.tr(),
      leading: const Icon(Icons.search_rounded),
      trailing: [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () {
              controller.clear();
              onQueryChanged('');
            },
            icon: const Icon(Icons.close_rounded),
          ),
      ],
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(
        context.cs.surfaceContainerHighest,
      ),
      onChanged: onQueryChanged,
    );
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.item,
    required this.depth,
    required this.selectionState,
    required this.borderRadius,
    required this.onTap,
    this.onLongPressStart,
  });

  final ChoosePropertyItem item;
  final int depth;
  final _PropertySelectionState selectionState;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final checkboxValue = switch (selectionState) {
      _PropertySelectionState.unselected => false,
      _PropertySelectionState.selected => true,
      _PropertySelectionState.indeterminate => null,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: onLongPressStart == null
          ? null
          : (details) => onLongPressStart!(details.globalPosition),
      child: Material(
        key: ValueKey('choose-property-tile-${item.id}'),
        color: context.cs.surfaceContainerLow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16 + (_ChoosePropertyPageState._indentPerDepth * depth),
              18,
              16,
              18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _PropertyTypeTag(
                        label: item.subtitle,
                        tagKey: ValueKey('choose-property-type-tag-${item.id}'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  key: ValueKey('choose-property-checkbox-${item.id}'),
                  value: checkboxValue,
                  tristate: item.hasChildren,
                  onChanged: onTap == null ? null : (_) => onTap?.call(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisiblePropertyEntry {
  const _VisiblePropertyEntry({required this.item, required this.depth});

  final ChoosePropertyItem item;
  final int depth;
}

enum _PropertySelectionState { unselected, selected, indeterminate }

class _PropertyTypeTag extends StatelessWidget {
  const _PropertyTypeTag({required this.label, required this.tagKey});

  final String label;
  final Key tagKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tagKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.tt.labelMedium?.copyWith(
          color: context.cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _PropertyMenuAction { rename, delete }

enum _TilePosition { single, first, middle, last }

class _CreateNewTile extends StatelessWidget {
  const _CreateNewTile({required this.onTap, required this.borderRadius});

  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('choose-property-create-tile'),
      color: context.cs.surfaceContainerLow,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: context.cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'personTodo.propertyChooser.createNew'.tr(),
                  style: context.tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: context.cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateNew});

  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'personTodo.propertyChooser.emptyTitle'.tr(),
              style: context.tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'personTodo.propertyChooser.emptyBody'.tr(),
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add_rounded),
              label: Text('personTodo.propertyChooser.createNew'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

String _valuePreview(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return value.isEmpty ? '""' : value;
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
