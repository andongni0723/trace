import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/useful_extension.dart';
import '../../../../shared/widgets/bottom_sheet_keyboard_inset.dart';
import '../../data/models/personal_database_field_node.dart';
import '../../data/models/personal_database_management_error.dart';
import '../../data/models/personal_database_value_type.dart';
import '../../providers/personal_database_property_management_provider.dart';
import '../widgets/personal_database_field_sheet.dart';

class ManageDatabasePropertiesPage extends ConsumerStatefulWidget {
  const ManageDatabasePropertiesPage({super.key});

  @override
  ConsumerState<ManageDatabasePropertiesPage> createState() =>
      _ManageDatabasePropertiesPageState();
}

class _ManageDatabasePropertiesPageState
    extends ConsumerState<ManageDatabasePropertiesPage> {
  static const _dragHandleKeyPrefix = 'manage-database-property-drag-';
  static const _rowKeyPrefix = 'manage-database-property-row-';
  static const _tileOuterRadius = 28.0;
  static const _tileInnerRadius = 4.0;
  static const _tileSpacing = 4.0;
  static const _collapseAnimationDuration = Duration(milliseconds: 220);

  bool _isLoading = true;
  String? _errorText;
  String _searchQuery = '';
  List<PersonalDatabaseFieldNode> _library = const [];
  List<_ManagedPropertyRow> _visibleRows = const [];
  final Set<String> _collapsedFieldIds = <String>{};

  @override
  void initState() {
    super.initState();
    _reloadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('databasePropertyManager.title'.tr())),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('manage-database-properties-fab'),
        heroTag: 'manage-database-properties-add-fab',
        tooltip: 'databasePropertyManager.fab.tooltip'.tr(),
        onPressed: _isLoading ? null : _createRootProperty,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SearchBar(
              elevation: const WidgetStatePropertyAll<double>(0),
              leading: const Icon(Icons.search_rounded),
              hintText: 'databasePropertyManager.searchHint'.tr(),
              onChanged: _handleSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'databasePropertyManager.libraryLabel'.tr(),
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
          ),
        ),
      );
    }

    if (_visibleRows.isEmpty) {
      final isSearchEmpty = _searchQuery.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            isSearchEmpty
                ? 'databasePropertyManager.emptySearchBody'.tr()
                : 'databasePropertyManager.emptyBody'.tr(),
            textAlign: TextAlign.center,
            style: context.tt.bodyLarge?.copyWith(color: context.cs.outline),
          ),
        ),
      );
    }

    final visibleFieldIds = _visibleRows
        .where((row) => row.isVisible)
        .map((row) => row.field.id)
        .toList(growable: false);
    final visibleIndexByFieldId = {
      for (var index = 0; index < visibleFieldIds.length; index++)
        visibleFieldIds[index]: index,
    };

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
      itemCount: _visibleRows.length,
      onReorder: _searchQuery.trim().isEmpty ? _handleReorder : (_, __) {},
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final elevation = lerpDouble(0, 8, animation.value)!;
            return Material(
              elevation: elevation,
              color: context.cs.surface,
              borderRadius: BorderRadius.circular(24),
              child: child,
            );
          },
        );
      },
      itemBuilder: (context, index) {
        final row = _visibleRows[index];
        final visibleIndex = visibleIndexByFieldId[row.field.id];
        final bottomSpacing =
            row.isVisible &&
                visibleIndex != null &&
                visibleIndex != visibleFieldIds.length - 1
            ? _tileSpacing
            : 0.0;
        return KeyedSubtree(
          key: ValueKey('$_rowKeyPrefix${row.field.id}'),
          child: _AnimatedPropertyRow(
            isVisible: row.isVisible,
            bottomSpacing: bottomSpacing,
            child: _PropertyTile(
              row: row,
              index: index,
              dragHandleKey: ValueKey('$_dragHandleKeyPrefix${row.field.id}'),
              borderRadius: row.isVisible && visibleIndex != null
                  ? _tileBorderRadiusFor(
                      _tilePositionFor(
                        index: visibleIndex,
                        length: visibleFieldIds.length,
                      ),
                    )
                  : BorderRadius.circular(_tileInnerRadius),
              onTap: () => _showPropertyActions(row.field),
              onToggleCollapsed: () => _toggleCollapsed(row.field),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reloadLibrary() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final library = await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .getPropertyLibrary();
      if (!mounted) {
        return;
      }
      setState(() {
        _library = library;
        _visibleRows = _flattenVisibleRows(library, _searchQuery.trim());
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorText = 'databasePropertyManager.loadError'.tr();
      });
    }
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _visibleRows = _flattenVisibleRows(_library, query.trim());
    });
  }

  List<_ManagedPropertyRow> _flattenVisibleRows(
    List<PersonalDatabaseFieldNode> fields,
    String query,
  ) {
    final rows = <_ManagedPropertyRow>[];

    bool subtreeMatches(PersonalDatabaseFieldNode node) {
      final normalizedQuery = query.toLowerCase();
      if (normalizedQuery.isEmpty) {
        return true;
      }

      final matchesKey = node.key.toLowerCase().contains(normalizedQuery);
      if (matchesKey) {
        return true;
      }

      return node.children.any(subtreeMatches);
    }

    void visit(
      List<PersonalDatabaseFieldNode> nodes,
      int depth, {
      required bool ancestorCollapsed,
    }) {
      for (final node in nodes) {
        if (!subtreeMatches(node)) {
          continue;
        }

        final isVisible = query.isNotEmpty || !ancestorCollapsed;
        final isCollapsed = _collapsedFieldIds.contains(node.id);

        rows.add(
          _ManagedPropertyRow(
            field: node,
            depth: depth,
            parentFieldId: node.parentFieldId,
            isCollapsed: isCollapsed,
            isVisible: isVisible,
          ),
        );

        if (node.children.isNotEmpty) {
          visit(
            node.children,
            depth + 1,
            ancestorCollapsed:
                ancestorCollapsed || (query.isEmpty && isCollapsed),
          );
        }
      }
    }

    visit(fields, 0, ancestorCollapsed: false);
    return rows;
  }

  Future<void> _createRootProperty() async {
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'databasePropertyManager.createRootTitle'.tr(),
      submitLabel: 'databasePropertyManager.createRootSubmit'.tr(),
      showKeyInput: true,
      showValueInput: false,
    );
    if (result == null || result.key == null) {
      return;
    }

    AppHaptics.primaryAction();

    try {
      await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .createPropertyDefinition(key: result.key!, type: result.type);
      await _reloadLibrary();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('databasePropertyManager.loadError'.tr());
    }
  }

  Future<void> _createSubproperty(PersonalDatabaseFieldNode parent) async {
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'databasePropertyManager.createSubTitle'.tr(),
      submitLabel: 'databasePropertyManager.createSubSubmit'.tr(),
      showKeyInput: true,
      showValueInput: false,
    );
    if (result == null || result.key == null) {
      return;
    }

    AppHaptics.primaryAction();

    try {
      await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .createPropertyDefinition(
            key: result.key!,
            type: result.type,
            parentFieldId: parent.id,
          );
      await _reloadLibrary();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('databasePropertyManager.loadError'.tr());
    }
  }

  Future<void> _showPropertyActions(PersonalDatabaseFieldNode field) async {
    AppHaptics.selection();

    final actions = ref.read(personalDatabasePropertyManagementActionsProvider);
    final canRetype = !field.isObject || field.children.isEmpty;
    final canDelete = await actions.canDeletePropertyDefinition(field.id);

    if (!mounted) {
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
                if (field.isObject)
                  ListTile(
                    key: const ValueKey('manage-database-property-add-child'),
                    leading: const Icon(Icons.add_circle_outline_rounded),
                    title: Text(
                      'databasePropertyManager.action.addSubproperty'.tr(),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onTap: () async {
                      AppHaptics.selection();
                      Navigator.of(sheetContext).pop();
                      await _createSubproperty(field);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text('databasePropertyManager.action.rename'.tr()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: () async {
                    AppHaptics.selection();
                    Navigator.of(sheetContext).pop();
                    await _showRenameSheet(field);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.category_outlined,
                    color: canRetype ? null : context.cs.onSurfaceVariant,
                  ),
                  title: Text('databasePropertyManager.action.retype'.tr()),
                  subtitle: canRetype
                      ? Text('databasePropertyManager.action.retypeHint'.tr())
                      : Text(
                          'databasePropertyManager.action.retypeDisabled'.tr(),
                        ),
                  enabled: canRetype,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: canRetype
                      ? () async {
                          AppHaptics.selection();
                          Navigator.of(sheetContext).pop();
                          await _showRetypeSheet(field);
                        }
                      : null,
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: canDelete ? context.cs.error : context.cs.outline,
                  ),
                  title: Text(
                    'databasePropertyManager.action.delete'.tr(),
                    style: TextStyle(
                      color: canDelete ? context.cs.error : context.cs.outline,
                    ),
                  ),
                  subtitle: canDelete
                      ? null
                      : Text(
                          'databasePropertyManager.error.deleteBlockedBody'
                              .tr(),
                        ),
                  enabled: canDelete,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: canDelete
                      ? () async {
                          AppHaptics.selection();
                          Navigator.of(sheetContext).pop();
                          await _confirmDelete(field);
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameSheet(PersonalDatabaseFieldNode field) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _RenamePropertySheet(initialKey: field.key),
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }

    try {
      await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .renamePropertyDefinition(fieldId: field.id, key: result.trim());
      await _reloadLibrary();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('databasePropertyManager.loadError'.tr());
    }
  }

  Future<void> _showRetypeSheet(PersonalDatabaseFieldNode field) async {
    final selectedType = await showModalBottomSheet<PersonalDatabaseValueType>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _RetypePropertySheet(initialType: field.type),
    );

    if (selectedType == null || selectedType == field.type) {
      return;
    }

    final actions = ref.read(personalDatabasePropertyManagementActionsProvider);
    final canRetype = await actions.canRetypePropertyDefinition(
      fieldId: field.id,
      nextType: selectedType,
    );
    if (!canRetype) {
      await _showBlockedDialog(
        title: 'databasePropertyManager.error.retypeBlockedTitle'.tr(),
        body: 'databasePropertyManager.error.retypeBlockedBody'.tr(),
      );
      return;
    }

    try {
      await actions.retypePropertyDefinition(
        fieldId: field.id,
        nextType: selectedType,
      );
      await _reloadLibrary();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('databasePropertyManager.loadError'.tr());
    }
  }

  Future<void> _confirmDelete(PersonalDatabaseFieldNode field) async {
    final canDelete = await ref
        .read(personalDatabasePropertyManagementActionsProvider)
        .canDeletePropertyDefinition(field.id);
    if (!canDelete) {
      await _showBlockedDialog(
        title: 'databasePropertyManager.error.deleteBlockedTitle'.tr(),
        body: 'databasePropertyManager.error.deleteBlockedBody'.tr(),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('databasePropertyManager.deleteDialog.title'.tr()),
          content: Text(
            'databasePropertyManager.deleteDialog.body'.tr(
              namedArgs: {'key': field.key},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('databasePropertyManager.renameDialog.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('databasePropertyManager.deleteDialog.delete'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .deletePropertyDefinition(field.id);
      await _reloadLibrary();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar(
        'databasePropertyManager.error.deleteBlockedBody'.tr(),
      );
    }
  }

  Future<void> _showBlockedDialog({
    required String title,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('databasePropertyManager.error.confirm'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final reordered = List<_ManagedPropertyRow>.of(_visibleRows);
    final movedRow = reordered.removeAt(oldIndex);
    if (!_isValidSameLevelInsertion(
      rows: reordered,
      insertionIndex: newIndex,
      movedRow: movedRow,
    )) {
      await _showBlockedDialog(
        title: 'databasePropertyManager.error.moveBlockedTitle'.tr(),
        body: 'databasePropertyManager.error.moveScopeConflictBody'.tr(),
      );
      return;
    }

    reordered.insert(newIndex, movedRow);

    setState(() {
      _visibleRows = reordered;
    });

    try {
      final newSortOrder = _inferNewSortOrder(
        rows: reordered,
        movedIndex: newIndex,
        parentFieldId: movedRow.parentFieldId,
      );

      await ref
          .read(personalDatabasePropertyManagementActionsProvider)
          .movePropertyDefinition(
            fieldId: movedRow.field.id,
            newParentFieldId: movedRow.parentFieldId,
            newSortOrder: newSortOrder,
          );
      await _reloadLibrary();
    } on PersonalDatabaseManagementException catch (error) {
      if (!mounted) {
        return;
      }
      await _reloadLibrary();
      await _showBlockedDialog(
        title: 'databasePropertyManager.error.moveBlockedTitle'.tr(),
        body: switch (error.code) {
          PersonalDatabaseManagementErrorCode.moveTargetMustBeObject =>
            'databasePropertyManager.error.moveTargetMustBeObjectBody'.tr(),
          PersonalDatabaseManagementErrorCode.moveTargetCannotBeDescendant =>
            'databasePropertyManager.error.moveTargetCannotBeDescendantBody'
                .tr(),
          PersonalDatabaseManagementErrorCode.moveScopeConflict =>
            'databasePropertyManager.error.moveScopeConflictBody'.tr(),
          _ => 'databasePropertyManager.loadError'.tr(),
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _reloadLibrary();
      _showErrorSnackBar('databasePropertyManager.loadError'.tr());
    }
  }

  bool _isValidSameLevelInsertion({
    required List<_ManagedPropertyRow> rows,
    required int insertionIndex,
    required _ManagedPropertyRow movedRow,
  }) {
    if (rows.isEmpty) {
      return true;
    }

    if (insertionIndex < rows.length &&
        rows[insertionIndex].depth > movedRow.depth) {
      return false;
    }

    final previousSibling = _findSiblingBefore(
      rows: rows,
      insertionIndex: insertionIndex,
      depth: movedRow.depth,
    );
    final nextSibling = _findSiblingAfter(
      rows: rows,
      insertionIndex: insertionIndex,
      depth: movedRow.depth,
    );

    return previousSibling?.parentFieldId == movedRow.parentFieldId ||
        nextSibling?.parentFieldId == movedRow.parentFieldId;
  }

  _ManagedPropertyRow? _findSiblingBefore({
    required List<_ManagedPropertyRow> rows,
    required int insertionIndex,
    required int depth,
  }) {
    for (var index = insertionIndex - 1; index >= 0; index--) {
      final row = rows[index];
      if (row.depth > depth) {
        continue;
      }
      return row.depth == depth ? row : null;
    }
    return null;
  }

  _ManagedPropertyRow? _findSiblingAfter({
    required List<_ManagedPropertyRow> rows,
    required int insertionIndex,
    required int depth,
  }) {
    for (var index = insertionIndex; index < rows.length; index++) {
      final row = rows[index];
      if (row.depth > depth) {
        continue;
      }
      return row.depth == depth ? row : null;
    }
    return null;
  }

  int _inferNewSortOrder({
    required List<_ManagedPropertyRow> rows,
    required int movedIndex,
    required String? parentFieldId,
  }) {
    var sortOrder = 0;
    for (var index = 0; index < movedIndex; index++) {
      if (rows[index].parentFieldId == parentFieldId) {
        sortOrder += 1;
      }
    }
    return sortOrder;
  }

  void _toggleCollapsed(PersonalDatabaseFieldNode field) {
    if (!field.isObject) {
      return;
    }

    AppHaptics.selection();
    setState(() {
      if (_collapsedFieldIds.contains(field.id)) {
        _collapsedFieldIds.remove(field.id);
      } else {
        _collapsedFieldIds.add(field.id);
      }
      _visibleRows = _flattenVisibleRows(_library, _searchQuery.trim());
    });
  }
}

class _ManagedPropertyRow {
  const _ManagedPropertyRow({
    required this.field,
    required this.depth,
    required this.parentFieldId,
    required this.isCollapsed,
    required this.isVisible,
  });

  final PersonalDatabaseFieldNode field;
  final int depth;
  final String? parentFieldId;
  final bool isCollapsed;
  final bool isVisible;
}

class _AnimatedPropertyRow extends StatefulWidget {
  const _AnimatedPropertyRow({
    required this.isVisible,
    required this.bottomSpacing,
    required this.child,
  });

  final bool isVisible;
  final double bottomSpacing;
  final Widget child;

  @override
  State<_AnimatedPropertyRow> createState() => _AnimatedPropertyRowState();
}

class _AnimatedPropertyRowState extends State<_AnimatedPropertyRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _ManageDatabasePropertiesPageState._collapseAnimationDuration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  late bool _shouldRenderChild = widget.isVisible;

  @override
  void initState() {
    super.initState();
    _controller.value = widget.isVisible ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedPropertyRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible == oldWidget.isVisible) {
      return;
    }

    if (widget.isVisible) {
      if (!_shouldRenderChild) {
        setState(() {
          _shouldRenderChild = true;
        });
      }
      _controller.forward();
      return;
    }

    _controller.reverse().whenCompleteOrCancel(() {
      if (!mounted || widget.isVisible || _controller.value > 0) {
        return;
      }
      setState(() {
        _shouldRenderChild = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRenderChild && !widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return IgnorePointer(
          ignoring: value < 0.01,
          child: Opacity(
            opacity: value,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: value,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: widget.bottomSpacing * value,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.row,
    required this.index,
    required this.dragHandleKey,
    required this.borderRadius,
    required this.onTap,
    required this.onToggleCollapsed,
  });

  final _ManagedPropertyRow row;
  final int index;
  final Key dragHandleKey;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: 12 + (row.depth * 18).toDouble(),
            end: 12,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  key: dragHandleKey,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              _TypeTag(type: row.field.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.field.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (row.field.isObject)
                IconButton(
                  key: ValueKey(
                    'manage-database-property-expand-${row.field.id}',
                  ),
                  onPressed: onToggleCollapsed,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  icon: AnimatedRotation(
                    turns: row.isCollapsed ? 0 : 0.25,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: colorScheme.outline,
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
      return BorderRadius.circular(
        _ManageDatabasePropertiesPageState._tileOuterRadius,
      );
    case _TilePosition.first:
      return const BorderRadius.only(
        topLeft: Radius.circular(
          _ManageDatabasePropertiesPageState._tileOuterRadius,
        ),
        topRight: Radius.circular(
          _ManageDatabasePropertiesPageState._tileOuterRadius,
        ),
        bottomLeft: Radius.circular(
          _ManageDatabasePropertiesPageState._tileInnerRadius,
        ),
        bottomRight: Radius.circular(
          _ManageDatabasePropertiesPageState._tileInnerRadius,
        ),
      );
    case _TilePosition.middle:
      return BorderRadius.circular(
        _ManageDatabasePropertiesPageState._tileInnerRadius,
      );
    case _TilePosition.last:
      return const BorderRadius.only(
        topLeft: Radius.circular(
          _ManageDatabasePropertiesPageState._tileInnerRadius,
        ),
        topRight: Radius.circular(
          _ManageDatabasePropertiesPageState._tileInnerRadius,
        ),
        bottomLeft: Radius.circular(
          _ManageDatabasePropertiesPageState._tileOuterRadius,
        ),
        bottomRight: Radius.circular(
          _ManageDatabasePropertiesPageState._tileOuterRadius,
        ),
      );
  }
}

enum _TilePosition { single, first, middle, last }

class _RenamePropertySheet extends StatefulWidget {
  const _RenamePropertySheet({required this.initialKey});

  final String initialKey;

  @override
  State<_RenamePropertySheet> createState() => _RenamePropertySheetState();
}

class _RenamePropertySheetState extends State<_RenamePropertySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            'databasePropertyManager.renameDialog.title'.tr(),
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'databasePropertyManager.renameDialog.label'.tr(),
              filled: true,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: Text('databasePropertyManager.renameDialog.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(trimmed);
  }
}

class _RetypePropertySheet extends StatefulWidget {
  const _RetypePropertySheet({required this.initialType});

  final PersonalDatabaseValueType initialType;

  @override
  State<_RetypePropertySheet> createState() => _RetypePropertySheetState();
}

class _RetypePropertySheetState extends State<_RetypePropertySheet> {
  late PersonalDatabaseValueType _selectedType;

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
            'databasePropertyManager.retypeDialog.title'.tr(),
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownMenu<PersonalDatabaseValueType>(
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
              if (type == null) {
                return;
              }
              setState(() {
                _selectedType = type;
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
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selectedType),
            child: Text('databasePropertyManager.retypeDialog.save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  const _TypeTag({required this.type});

  final PersonalDatabaseValueType type;

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
          type.localizationKey.tr(),
          style: context.tt.labelMedium?.copyWith(
            color: context.cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
