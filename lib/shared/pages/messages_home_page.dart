import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/providers/messages_home_selection_mode_provider.dart';
import 'package:trace/shared/dialogs/update_version_dialog.dart';
import 'package:trace/shared/widgets/person_avatar.dart';

const double _wideHorizontalPadding = 32;
const double _compactHorizontalPadding = 20;
const double _topSectionBottomPadding = 16;
const double _topBarToTabsSpacing = 20;
const double _listBottomPadding = 96;
const double _tileSpacing = 4;
const double _tileOuterRadius = 28;
const double _tileInnerRadius = 4;
const double _tileContentHorizontalPadding = 16;
const double _tileContentVerticalPadding = 14;
const double _tileAvatarSpacing = 12;
const double _tileTitleToPreviewSpacing = 6;
const double _avatarRadius = 28;
const double _countBadgeMinSize = 32;
const double _countBadgeHorizontalPadding = 10;
const Duration _selectionAnimationDuration = Duration(milliseconds: 220);

class MessagesHomePage extends ConsumerStatefulWidget {
  const MessagesHomePage({this.enableStartupUpdateCheck = true, super.key});

  final bool enableStartupUpdateCheck;

  @override
  ConsumerState<MessagesHomePage> createState() => _MessagesHomePageState();
}

class _MessagesHomePageState extends ConsumerState<MessagesHomePage>
    with LateInitMixin<MessagesHomePage> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late final MessagesHomeSelectionModeNotifier _selectionModeNotifier;
  String _searchQuery = '';
  bool _hasStartedUpdateCheck = false;
  Set<String> _selectedPersonIds = <String>{};

  bool get _isSelectionMode => _selectedPersonIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectionModeNotifier = ref.read(
      messagesHomeSelectionModeProvider.notifier,
    );
  }

  @override
  void lateInitState() {
    _checkForStartupUpdate();
  }

  @override
  void dispose() {
    _selectionModeNotifier.setSelectionMode(false);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkForStartupUpdate() async {
    if (!mounted ||
        !widget.enableStartupUpdateCheck ||
        _hasStartedUpdateCheck) {
      return;
    }

    _hasStartedUpdateCheck = true;
    await showUpdateVersionDialog(context, showStatusFeedback: false);
  }

  List<String> _localizedTabs(BuildContext context) => [
    'messages.tabs.all'.tr(),
    'messages.tabs.groups'.tr(),
  ];

  List<PeopleData> _filterPeople(List<PeopleData> people) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return people;
    }

    return people
        .where((person) => person.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  _TilePosition _tilePositionFor(int index, int length) {
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

  void _setSelectionModeForShell(bool isSelectionMode) {
    _selectionModeNotifier.setSelectionMode(isSelectionMode);
  }

  void _applySelection(Set<String> selectedIds) {
    if (setEquals(_selectedPersonIds, selectedIds)) {
      return;
    }

    setState(() {
      _selectedPersonIds = selectedIds;
    });
    _setSelectionModeForShell(selectedIds.isNotEmpty);
  }

  void _clearSelection() {
    if (_selectedPersonIds.isEmpty) {
      return;
    }

    AppHaptics.selection();
    _applySelection(<String>{});
  }

  void _selectFromGesture(String personId) {
    if (_selectedPersonIds.contains(personId)) {
      return;
    }

    final nextSelection = Set<String>.from(_selectedPersonIds)..add(personId);
    _applySelection(nextSelection);
  }

  void _handleAvatarTap(String personId) {
    if (_isSelectionMode) {
      _toggleSelection(personId);
      return;
    }

    AppHaptics.confirm();
    _selectFromGesture(personId);
  }

  void _handleTileTap(PeopleData person) {
    if (_isSelectionMode) {
      _toggleSelection(person.id);
      return;
    }

    AppHaptics.primaryAction();
    context.push('/people/${person.id}');
  }

  void _handleTileLongPress(String personId) {
    if (_isSelectionMode) {
      _toggleSelection(personId);
      return;
    }

    AppHaptics.confirm();
    _selectFromGesture(personId);
  }

  void _toggleSelection(String personId) {
    final nextSelection = Set<String>.from(_selectedPersonIds);
    if (!nextSelection.add(personId)) {
      nextSelection.remove(personId);
    }

    AppHaptics.selection();
    _applySelection(nextSelection);
  }

  void _pruneSelection(List<PeopleData> people) {
    if (_selectedPersonIds.isEmpty) {
      return;
    }

    final availableIds = people.map((person) => person.id).toSet();
    final nextSelection = _selectedPersonIds
        .where(availableIds.contains)
        .toSet();
    if (setEquals(_selectedPersonIds, nextSelection)) {
      return;
    }

    _applySelection(nextSelection);
  }

  void _showComingSoonSnackBar(BuildContext context) {
    AppHaptics.selection();
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('appSettings.comingSoon'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<PeopleData>>>(peopleProvider, (previous, next) {
      next.whenData(_pruneSelection);
    });

    final peopleAsync = ref.watch(peopleProvider);
    final screenSize = MediaQuery.sizeOf(context);
    final horizontalPadding = screenSize.width >= 700
        ? _wideHorizontalPadding
        : _compactHorizontalPadding;
    final tabs = _localizedTabs(context);

    return PopScope<void>(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _clearSelection();
        }
      },
      child: Material(
        color: context.cs.surface,
        child: SafeArea(
          child: _buildScrollView(
            context: context,
            horizontalPadding: horizontalPadding,
            tabs: tabs,
            peopleAsync: peopleAsync,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollView({
    required BuildContext context,
    required double horizontalPadding,
    required List<String> tabs,
    required AsyncValue<List<PeopleData>> peopleAsync,
  }) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            _topSectionBottomPadding,
            horizontalPadding,
            _topSectionBottomPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildTopSection(context: context, tabs: tabs),
          ),
        ),
        _buildConversationList(
          context: context,
          horizontalPadding: horizontalPadding,
          peopleAsync: peopleAsync,
        ),
      ],
    );
  }

  Widget _buildTopSection({
    required BuildContext context,
    required List<String> tabs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          isSelectionMode: _isSelectionMode,
          selectedCount: _selectedPersonIds.length,
          onClearSelection: _clearSelection,
          onTapGroup: () => _showComingSoonSnackBar(context),
          searchBar: _buildSearchBar(context),
        ),
        const SizedBox(height: _topBarToTabsSpacing),
        _buildFilterChips(tabs),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SearchBar(
      controller: _searchController,
      hintText: 'messages.searchHint'.tr(),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      leading: IconButton(
        onPressed: () {
          AppHaptics.selection();
          Scaffold.maybeOf(context)?.openDrawer();
        },
        tooltip: 'appShell.drawer.openMenu'.tr(),
        icon: const Icon(Icons.menu_rounded),
      ),
      trailing: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            onPressed: () {
              AppHaptics.selection();
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.close_rounded),
          ),
      ],
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(
        context.cs.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildFilterChips(List<String> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == _selectedTabIndex;

          return Padding(
            padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 12),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              onSelected: (_) {
                AppHaptics.selection();
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConversationList({
    required BuildContext context,
    required double horizontalPadding,
    required AsyncValue<List<PeopleData>> peopleAsync,
  }) {
    return peopleAsync.when(
      data: (people) {
        final filteredPeople = _filterPeople(people);

        if (people.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'messages.people.empty'.tr(),
                style: context.tt.bodyLarge?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (filteredPeople.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'messages.people.noSearchResult'.tr(),
                style: context.tt.bodyLarge?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            _listBottomPadding,
          ),
          sliver: SliverList.separated(
            itemCount: filteredPeople.length,
            itemBuilder: (context, index) {
              return _ConversationCard(
                person: filteredPeople[index],
                position: _tilePositionFor(index, filteredPeople.length),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedPersonIds.contains(
                  filteredPeople[index].id,
                ),
                onTapBody: () => _handleTileTap(filteredPeople[index]),
                onTapAvatar: () => _handleAvatarTap(filteredPeople[index].id),
                onLongPressBody: () =>
                    _handleTileLongPress(filteredPeople[index].id),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: _tileSpacing),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'messages.people.loadError'.tr(),
            style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onTapGroup,
    required this.searchBar,
  });

  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onTapGroup;
  final Widget searchBar;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _selectionAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: isSelectionMode
          ? Row(
              key: const ValueKey('messages-home-selection-header'),
              children: [
                IconButton(
                  key: const Key('messages-home-selection-back'),
                  onPressed: onClearSelection,
                  tooltip: 'messages.selection.close'.tr(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    'messages.selection.count'.tr(
                      namedArgs: {'count': '$selectedCount'},
                    ),
                    style: context.tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('messages-home-selection-group'),
                  onPressed: onTapGroup,
                  tooltip: 'messages.selection.group'.tr(),
                  icon: const Icon(Icons.group_outlined),
                ),
              ],
            )
          : Row(
              key: const ValueKey('messages-home-default-header'),
              children: [Expanded(child: searchBar)],
            ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  const _ConversationCard({
    required this.person,
    required this.position,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTapBody,
    required this.onTapAvatar,
    required this.onLongPressBody,
  });

  final PeopleData person;
  final _TilePosition position;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTapBody;
  final VoidCallback onTapAvatar;
  final VoidCallback onLongPressBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewTodoAsync = ref.watch(personPreviewTodoProvider(person.id));
    final openTodoCountAsync = ref.watch(
      personOpenTodoCountProvider(person.id),
    );
    final borderRadius = _tileBorderRadiusFor(position);
    final tileColor = isSelected
        ? context.cs.secondaryContainer
        : context.cs.surfaceContainerLow;
    final titleColor = isSelected
        ? context.cs.onSecondaryContainer
        : context.cs.onSurface;
    final previewColor = isSelected
        ? context.cs.onSecondaryContainer.withValues(alpha: 0.82)
        : context.cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        key: Key('conversation-card-${person.id}'),
        duration: _selectionAnimationDuration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: tileColor, borderRadius: borderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _tileContentHorizontalPadding,
                _tileContentVerticalPadding,
                _tileAvatarSpacing,
                _tileContentVerticalPadding,
              ),
              child: InkResponse(
                key: Key('conversation-card-avatar-${person.id}'),
                onTap: onTapAvatar,
                radius: _avatarRadius + 8,
                customBorder: const CircleBorder(),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: isSelected
                      ? 'messages.selection.deselectPerson'.tr(
                          namedArgs: {'name': person.name},
                        )
                      : 'messages.selection.selectPerson'.tr(
                          namedArgs: {'name': person.name},
                        ),
                  child: _SelectablePersonAvatar(
                    person: person,
                    isSelected: isSelected,
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                key: Key('conversation-card-body-${person.id}'),
                onTap: onTapBody,
                onLongPress: onLongPressBody,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    _tileContentVerticalPadding,
                    _tileContentHorizontalPadding,
                    _tileContentVerticalPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.tt.titleMedium?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: _tileTitleToPreviewSpacing),
                            Text(
                              previewTodoAsync.maybeWhen(
                                data: (todo) =>
                                    todo?.title ??
                                    'messages.people.cardPreview'.tr(),
                                orElse: () =>
                                    'messages.people.cardPreview'.tr(),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.tt.bodyMedium?.copyWith(
                                color: previewColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (openTodoCountAsync.maybeWhen(
                        data: (count) => count > 0,
                        orElse: () => false,
                      )) ...[
                        const SizedBox(width: 12),
                        _OpenTodoCountBadge(
                          count: openTodoCountAsync.maybeWhen(
                            data: (count) => count,
                            orElse: () => 0,
                          ),
                          isSelected: isSelected,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenTodoCountBadge extends StatelessWidget {
  const _OpenTodoCountBadge({required this.count, required this.isSelected});

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? context.cs.secondary
        : count > 0
        ? context.cs.primaryContainer
        : context.cs.surfaceContainerHighest;
    final foregroundColor = isSelected
        ? context.cs.onSecondary
        : count > 0
        ? context.cs.onPrimaryContainer
        : context.cs.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(
        minWidth: _countBadgeMinSize,
        minHeight: _countBadgeMinSize,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _countBadgeHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: context.tt.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectablePersonAvatar extends StatefulWidget {
  const _SelectablePersonAvatar({
    required this.person,
    required this.isSelected,
  });

  final PeopleData person;
  final bool isSelected;

  @override
  State<_SelectablePersonAvatar> createState() =>
      _SelectablePersonAvatarState();
}

class _SelectablePersonAvatarState extends State<_SelectablePersonAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _selectionAnimationDuration,
    value: widget.isSelected ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _SelectablePersonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected == widget.isSelected) {
      return;
    }

    if (widget.isSelected) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final shouldShowCheckmark = progress >= 0.5;
        final rotation = progress * math.pi;
        final correctedRotation = shouldShowCheckmark
            ? rotation - math.pi
            : rotation;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(correctedRotation),
          child: shouldShowCheckmark
              ? Container(
                  key: Key('conversation-card-checkmark-${widget.person.id}'),
                  width: _avatarRadius * 2,
                  height: _avatarRadius * 2,
                  decoration: BoxDecoration(
                    color: context.cs.secondary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    color: context.cs.onSecondary,
                    size: 28,
                  ),
                )
              : PersonAvatar(
                  name: widget.person.name,
                  colorValue: widget.person.colorValue,
                  avatarPath: widget.person.avatarPath,
                  size: _avatarRadius * 2,
                ),
        );
      },
    );
  }
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

enum _TilePosition { single, first, middle, last }
