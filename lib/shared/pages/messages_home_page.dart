import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/dialogs/update_version_dialog.dart';
import 'package:trace/shared/widgets/person_avatar.dart';

const double _wideHorizontalPadding = 32;
const double _compactHorizontalPadding = 20;
const double _topSectionBottomPadding = 16;
const double _headerToSearchSpacing = 30;
const double _searchToTabsSpacing = 30;
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
  String _searchQuery = '';
  bool _hasStartedUpdateCheck = false;

  @override
  void lateInitState() {
    _checkForStartupUpdate();
  }

  @override
  void dispose() {
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
    'messages.tabs.unread'.tr(),
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

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final screenSize = MediaQuery.sizeOf(context);
    final horizontalPadding = screenSize.width >= 700
        ? _wideHorizontalPadding
        : _compactHorizontalPadding;
    final tabs = _localizedTabs(context);

    return Material(
      color: context.cs.surface,
      child: SafeArea(
        child: _buildScrollView(
          context: context,
          horizontalPadding: horizontalPadding,
          tabs: tabs,
          peopleAsync: peopleAsync,
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
        const _HeaderCard(),
        const SizedBox(height: _headerToSearchSpacing),
        _buildSearchBar(context),
        const SizedBox(height: _searchToTabsSpacing),
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
      leading: const Icon(Icons.search_rounded),
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
          )
        else
          const Icon(Icons.tune_rounded),
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

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'messages.todoTitle'.tr(),
            style: context.tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            AppHaptics.primaryAction();
            context.push('/settings');
          },
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  const _ConversationCard({required this.person, required this.position});

  final PeopleData person;
  final _TilePosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewTodoAsync = ref.watch(personPreviewTodoProvider(person.id));
    final openTodoCountAsync = ref.watch(
      personOpenTodoCountProvider(person.id),
    );

    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: _tileBorderRadiusFor(position),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.primaryAction();
          context.push('/people/${person.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _tileContentHorizontalPadding,
            vertical: _tileContentVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PersonAvatar(
                name: person.name,
                colorValue: person.colorValue,
                avatarPath: person.avatarPath,
                size: _avatarRadius * 2,
              ),
              const SizedBox(width: _tileAvatarSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: _tileTitleToPreviewSpacing),
                    Text(
                      previewTodoAsync.maybeWhen(
                        data: (todo) =>
                            todo?.title ?? 'messages.people.cardPreview'.tr(),
                        orElse: () => 'messages.people.cardPreview'.tr(),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodyMedium?.copyWith(
                        color: context.cs.onSurfaceVariant,
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenTodoCountBadge extends StatelessWidget {
  const _OpenTodoCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: _countBadgeMinSize,
        minHeight: _countBadgeMinSize,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _countBadgeHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: count > 0
            ? context.cs.primaryContainer
            : context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: context.tt.labelLarge?.copyWith(
          color: count > 0
              ? context.cs.onPrimaryContainer
              : context.cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
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
