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
    this.isAssignedToCurrentPerson = false,
  });

  factory ChoosePropertyItem.fromFieldNode(
    PersonalDatabaseFieldNode field, {
    bool isAssignedToCurrentPerson = false,
  }) {
    return ChoosePropertyItem(
      id: field.id,
      title: field.key,
      subtitle: field.type.localizationKey.tr(),
      valueType: field.type,
      rawValue: field.value,
      valuePreview: _valuePreview(field.value),
      isAssignedToCurrentPerson: isAssignedToCurrentPerson,
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final PersonalDatabaseValueType valueType;
  final Object? rawValue;
  final String valuePreview;
  final bool isAssignedToCurrentPerson;

  ChoosePropertyItem copyWith({
    String? title,
    String? subtitle,
    PersonalDatabaseValueType? valueType,
    Object? rawValue,
    String? valuePreview,
    bool? isAssignedToCurrentPerson,
  }) {
    return ChoosePropertyItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      valueType: valueType ?? this.valueType,
      rawValue: rawValue ?? this.rawValue,
      valuePreview: valuePreview ?? this.valuePreview,
      isAssignedToCurrentPerson:
          isAssignedToCurrentPerson ?? this.isAssignedToCurrentPerson,
    );
  }
}

sealed class ChoosePropertyResult {
  const ChoosePropertyResult();
}

final class ChoosePropertySelected extends ChoosePropertyResult {
  const ChoosePropertySelected(this.item);

  final ChoosePropertyItem item;
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

  final TextEditingController _searchController = TextEditingController();
  late List<ChoosePropertyItem> _properties;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _properties = List<ChoosePropertyItem>.from(widget.properties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProperties = _filteredProperties();

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
            if (filteredProperties.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreateNew: _createNew),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.separated(
                  itemCount: filteredProperties.length + 1,
                  itemBuilder: (context, index) {
                    final position = _tilePositionFor(
                      index: index,
                      length: filteredProperties.length + 1,
                    );

                    if (index == filteredProperties.length) {
                      return _CreateNewTile(
                        onTap: _createNew,
                        borderRadius: _tileBorderRadiusFor(position),
                      );
                    }

                    final item = filteredProperties[index];
                    return _PropertyTile(
                      item: item,
                      borderRadius: _tileBorderRadiusFor(position),
                      onTap: item.isAssignedToCurrentPerson
                          ? null
                          : () => _select(item),
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
    );
  }

  List<ChoosePropertyItem> _filteredProperties() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _properties;
    }

    return _properties
        .where((item) {
          return item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.valuePreview.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _select(ChoosePropertyItem item) {
    AppHaptics.primaryAction();
    Navigator.of(context).pop(ChoosePropertySelected(item));
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
        _properties = _properties
            .map(
              (candidate) => candidate.id == item.id ? updatedItem : candidate,
            )
            .toList(growable: false);
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
        _properties = _properties
            .where((candidate) => candidate.id != item.id)
            .toList(growable: false);
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
    required this.borderRadius,
    required this.onTap,
    this.onLongPressStart,
  });

  final ChoosePropertyItem item;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onLongPressStart;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
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
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.labelLarge?.copyWith(
                        color: context.cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      key: ValueKey('choose-property-icon-${item.id}'),
                      item.isAssignedToCurrentPerson
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: item.isAssignedToCurrentPerson ? 22 : 18,
                      color: item.isAssignedToCurrentPerson
                          ? context.cs.primary
                          : context.cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
