import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/app.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/data/models/todo_with_people.dart';
import 'package:trace/features/people/data/models/personal_database_mention_suggestion.dart';
import 'package:trace/features/people/presentation/pages/choose_property_page.dart';
import 'package:trace/features/people/presentation/widgets/person_personal_database_tab.dart';
import 'package:trace/features/people/providers/person_detail_provider.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/personal_database_provider.dart';
import 'package:trace/shared/widgets/add_todo_bottom_sheet.dart';
import 'package:trace/shared/widgets/bottom_sheet_keyboard_inset.dart';
import 'package:trace/shared/widgets/person_avatar.dart';
import 'package:trace/shared/widgets/person_todo_item.dart';
import 'package:trace/features/people/presentation/widgets/personal_database_field_sheet.dart';

enum _PersonMenuAction { rename, delete }

enum PersonTodoInitialTab { todoList, database }

class PersonTodoPage extends ConsumerStatefulWidget {
  const PersonTodoPage({
    required this.personId,
    this.initialTab = PersonTodoInitialTab.todoList,
    super.key,
  });

  final String personId;
  final PersonTodoInitialTab initialTab;

  @override
  ConsumerState<PersonTodoPage> createState() => _PersonTodoPageState();
}

class _PersonTodoPageState extends ConsumerState<PersonTodoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _tabIndexFor(widget.initialTab),
    )..addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant PersonTodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _tabIndexFor(widget.initialTab);
    if (oldWidget.initialTab != widget.initialTab &&
        _tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int _tabIndexFor(PersonTodoInitialTab tab) {
    return switch (tab) {
      PersonTodoInitialTab.todoList => 0,
      PersonTodoInitialTab.database => 1,
    };
  }

  Future<void> _openAddTodoBottomSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => AddTodoBottomSheet(personId: widget.personId),
    );
  }

  Future<void> _openEditTodoBottomSheet(TodoWithPeople todo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) =>
          AddTodoBottomSheet(personId: widget.personId, initialTodo: todo),
    );
  }

  Future<void> _handleMenuAction(
    _PersonMenuAction action,
    PeopleData person,
  ) async {
    AppHaptics.selection();

    switch (action) {
      case _PersonMenuAction.rename:
        await _showRenamePersonSheet(person);
      case _PersonMenuAction.delete:
        await _showDeletePersonSheet(person);
    }
  }

  Future<void> _showRenamePersonSheet(PeopleData person) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _RenamePersonSheet(person: person),
    );
  }

  Future<void> _showDeletePersonSheet(PeopleData person) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => _DeletePersonSheet(person: person),
    );
  }

  Widget _buildAnimatedTodoFab() {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      child: FloatingActionButton(
        heroTag: 'person-todo-add-fab-${widget.personId}',
        onPressed: () {
          AppHaptics.primaryAction();
          _openAddTodoBottomSheet();
        },
        child: const Icon(Icons.add),
      ),
      builder: (context, child) {
        final progress = _tabController.animation!.value.clamp(0.0, 1.0);
        final visibility = 1.0 - progress;
        final scale = 0.88 + (visibility * 0.12);

        return IgnorePointer(
          ignoring: visibility < 0.5,
          child: Opacity(
            opacity: visibility,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }

  Widget _buildDatabaseFab() {
    return FloatingActionButton(
      heroTag: 'person-database-add-fab-${widget.personId}',
      onPressed: _handleAddProperty,
      child: const Icon(Icons.add_rounded),
    );
  }

  Future<void> _handleAddProperty() async {
    AppHaptics.primaryAction();
    await ref
        .read(personalDatabaseActionsProvider)
        .ensureObjectSubtreeDefinitions(personId: widget.personId);
    final dao = ref.read(personalDatabaseDaoProvider);
    final library = await dao.getFieldLibraryForPerson(widget.personId);
    final assignedFieldIds = await dao.getAssignedFieldIdsForPerson(
      widget.personId,
    );
    if (!mounted) {
      return;
    }

    final choice = await showChoosePropertyPage(
      context: context,
      properties: library
          .map(
            (field) => ChoosePropertyItem.fromFieldNode(
              field,
              assignedFieldIds: assignedFieldIds,
            ),
          )
          .toList(growable: false),
      onRenameProperty: (item, newTitle) async {
        await ref
            .read(personalDatabaseActionsProvider)
            .updatePropertyDefinition(
              fieldId: item.id,
              key: newTitle,
              type: item.valueType,
            );
        return item.copyWith(title: newTitle);
      },
      onDeleteProperty: (item) {
        return ref
            .read(personalDatabaseActionsProvider)
            .deletePropertyDefinition(item.id);
      },
    );

    if (!mounted || choice == null) {
      return;
    }

    try {
      switch (choice) {
        case ChoosePropertySelected(:final items):
          final actions = ref.read(personalDatabaseActionsProvider);
          for (final item in items) {
            if (item.isAssignedToCurrentPerson) {
              continue;
            }
            await actions.assignFieldToPerson(
              personId: widget.personId,
              fieldId: item.id,
            );
          }
        case ChoosePropertyCreateNew():
          await _createNewProperty();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('personTodo.database.actionError'.tr())),
      );
    }
  }

  Future<void> _createNewProperty() async {
    final mentionSuggestions = _mentionSuggestions();
    final result = await showPersonalDatabaseFieldSheet(
      context: context,
      title: 'personTodo.propertyChooser.createNewTitle'.tr(),
      submitLabel: 'personTodo.database.sheet.create'.tr(),
      showKeyInput: true,
      mentionSuggestions: mentionSuggestions,
      mentionCodec: ref.read(personalDatabaseMentionCodecProvider),
    );

    if (!mounted || result == null || result.key == null) {
      return;
    }

    await ref
        .read(personalDatabaseActionsProvider)
        .createPropertyAndAssignToPerson(
          personId: widget.personId,
          key: result.key!,
          type: result.type,
          value: result.value,
        );
  }

  List<PersonalDatabaseMentionSuggestion> _mentionSuggestions() {
    final people =
        ref.read(peopleProvider).asData?.value ?? const <PeopleData>[];
    return [
      for (final person in people)
        PersonalDatabaseMentionSuggestion(
          id: person.id,
          name: person.name,
          colorValue: person.colorValue,
          avatarPath: person.avatarPath,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final personAsync = ref.watch(personProvider(widget.personId));
    final todosAsync = ref.watch(personTodosProvider(widget.personId));

    return personAsync.when(
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'personTodo.personMissing'.tr(),
                style: context.tt.bodyLarge,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                AppHaptics.primaryAction();
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                PersonAvatar(
                  name: person.name,
                  colorValue: person.colorValue,
                  avatarPath: person.avatarPath,
                  size: 36,
                  borderWidth: 1,
                  borderColor: context.cs.outlineVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<_PersonMenuAction>(
                tooltip: 'personTodo.menu.more'.tr(),
                onSelected: (action) {
                  Future<void>.microtask(() {
                    if (!mounted) {
                      return;
                    }
                    _handleMenuAction(action, person);
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _PersonMenuAction.rename,
                    child: Row(
                      spacing: 12,
                      children: [
                        const Icon(Icons.drive_file_rename_outline_rounded),
                        Text('personTodo.menu.renamePerson'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _PersonMenuAction.delete,
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: context.cs.error,
                        ),
                        Text(
                          'personTodo.menu.deletePerson'.tr(),
                          style: TextStyle(color: context.cs.error),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'personTodo.tabs.todoList'.tr()),
                Tab(text: 'personTodo.tabs.database'.tr()),
              ],
            ),
          ),
          floatingActionButton: _tabController.index == 0
              ? _buildAnimatedTodoFab()
              : _buildDatabaseFab(),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                todosAsync.when(
                  data: (todos) => _TodoListSection(
                    todos: todos,
                    onPressedTodo: _openEditTodoBottomSheet,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'personTodo.todoLoadError'.tr(),
                        style: context.tt.bodyMedium?.copyWith(
                          color: context.cs.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                PersonPersonalDatabaseTab(
                  personId: widget.personId,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'personTodo.personLoadError'.tr(),
            style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
          ),
        ),
      ),
    );
  }
}

class _RenamePersonSheet extends ConsumerStatefulWidget {
  const _RenamePersonSheet({required this.person});

  final PeopleData person;

  @override
  ConsumerState<_RenamePersonSheet> createState() => _RenamePersonSheetState();
}

class _RenamePersonSheetState extends ConsumerState<_RenamePersonSheet>
    with LateInitMixin<_RenamePersonSheet> {
  static const _sheetFocusDelay = Duration(milliseconds: 220);

  late final TextEditingController _controller;
  late final FocusNode _nameFocusNode;
  String? _selectedAvatarPath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.person.name);
    _nameFocusNode = FocusNode();
    _selectedAvatarPath = widget.person.avatarPath;
  }

  @override
  void lateInitState() {
    Future<void>.delayed(_sheetFocusDelay, () {
      if (!mounted) {
        return;
      }
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmedName = _controller.text.trim();
    if (trimmedName.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _renamePerson(trimmedName);
      if (mounted) {
        AppHaptics.confirm();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = _controller.text.trim();
    return BottomSheetKeyboardInset(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'personTodo.menu.renamePerson'.tr(),
              style: context.tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildAvatarSection(context),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              focusNode: _nameFocusNode,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {});
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'personTodo.renameDialog.nameLabel'.tr(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('personTodo.dialog.cancel'.tr()),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: trimmedName.isEmpty || _isSubmitting
                      ? null
                      : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('personTodo.dialog.save'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final trimmedName = _controller.text.trim().isEmpty
        ? widget.person.name
        : _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'personTodo.avatar.title'.tr(),
          style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PersonAvatar(
              name: trimmedName,
              colorValue: widget.person.colorValue,
              avatarPath: _selectedAvatarPath,
              size: 72,
              borderWidth: 1,
              borderColor: context.cs.outlineVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _pickAvatarImage,
                        icon: Icon(
                          _selectedAvatarPath == null
                              ? Icons.add_photo_alternate_outlined
                              : Icons.edit_outlined,
                        ),
                        label: Text(
                          _selectedAvatarPath == null
                              ? 'personTodo.avatar.select'.tr()
                              : 'personTodo.avatar.change'.tr(),
                        ),
                      ),
                      if (_selectedAvatarPath != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.selection();
                            setState(() {
                              _selectedAvatarPath = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text('personTodo.avatar.remove'.tr()),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAvatarImage() async {
    AppHaptics.primaryAction();
    try {
      final pickedPath = await ref
          .read(personAvatarPickerProvider)
          .pickAndCropAvatar(toolbarTitle: 'personTodo.avatar.cropTitle'.tr());
      if (pickedPath == null || !mounted) {
        return;
      }

      setState(() {
        _selectedAvatarPath = pickedPath;
      });
    } catch (e, s) {
      if (!mounted) {
        return;
      }

      debugPrint('[_pickAvatarImage Error]: $e');
      debugPrintStack(stackTrace: s);
      App.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('personTodo.avatar.processError'.tr())),
      );
    }
  }

  Future<void> _renamePerson(String trimmedName) async {
    await ref
        .read(personDetailActionsProvider)
        .updatePersonProfile(
          person: widget.person,
          name: trimmedName,
          avatarPath: _selectedAvatarPath,
        );
  }
}

class _DeletePersonSheet extends ConsumerStatefulWidget {
  const _DeletePersonSheet({required this.person});

  final PeopleData person;

  @override
  ConsumerState<_DeletePersonSheet> createState() => _DeletePersonSheetState();
}

class _DeletePersonSheetState extends ConsumerState<_DeletePersonSheet> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(personDetailActionsProvider)
          .deletePerson(widget.person.id);
      if (mounted) {
        Navigator.of(context).pop();
        AppHaptics.confirm();
        GoRouter.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'personTodo.menu.deletePerson'.tr(),
              style: context.tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'personTodo.deleteDialog.message'.tr(
                namedArgs: {'name': widget.person.name},
              ),
              style: context.tt.bodyLarge?.copyWith(
                color: context.cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('personTodo.dialog.cancel'.tr()),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.cs.error,
                    foregroundColor: context.cs.onError,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text('personTodo.menu.deletePerson'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoListSection extends ConsumerWidget {
  const _TodoListSection({required this.todos, required this.onPressedTodo});

  final List<TodoWithPeople> todos;
  final ValueChanged<TodoWithPeople> onPressedTodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TodoListBody(todos: todos, onPressedTodo: onPressedTodo);
  }
}

class _TodoListBody extends ConsumerStatefulWidget {
  const _TodoListBody({required this.todos, required this.onPressedTodo});

  final List<TodoWithPeople> todos;
  final ValueChanged<TodoWithPeople> onPressedTodo;

  @override
  ConsumerState<_TodoListBody> createState() => _TodoListBodyState();
}

class _TodoListBodyState extends ConsumerState<_TodoListBody> {
  bool _isCompletedExpanded = false;
  int _previousCompletedCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCompletedCount = widget.todos
        .where((todo) => todo.todo.done)
        .length;
  }

  @override
  void didUpdateWidget(covariant _TodoListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final completedCount = widget.todos.where((todo) => todo.todo.done).length;
    if (completedCount > _previousCompletedCount) {
      _isCompletedExpanded = true;
    }
    _previousCompletedCount = completedCount;
  }

  @override
  Widget build(BuildContext context) {
    final activeTodos = widget.todos.where((todo) => !todo.todo.done).toList();
    final completedTodos = widget.todos
        .where((todo) => todo.todo.done)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        ..._buildTodoItems(activeTodos),
        if (activeTodos.isEmpty && completedTodos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'personTodo.todoEmpty'.tr(),
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (completedTodos.isNotEmpty) ...[
          if (activeTodos.isNotEmpty) const SizedBox(height: 20),
          _CompletedSectionHeader(
            isExpanded: _isCompletedExpanded,
            count: completedTodos.length,
            onPressed: () {
              AppHaptics.selection();
              setState(() {
                _isCompletedExpanded = !_isCompletedExpanded;
              });
            },
          ),
          if (_isCompletedExpanded) ...[
            const SizedBox(height: 8),
            ..._buildTodoItems(completedTodos),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildTodoItems(List<TodoWithPeople> todos) {
    return [
      for (var index = 0; index < todos.length; index++) ...[
        _TodoListItem(todo: todos[index], onPressedTodo: widget.onPressedTodo),
        if (index != todos.length - 1) const SizedBox(height: 8),
      ],
    ];
  }
}

class _TodoListItem extends ConsumerWidget {
  const _TodoListItem({required this.todo, required this.onPressedTodo});

  final TodoWithPeople todo;
  final ValueChanged<TodoWithPeople> onPressedTodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PersonTodoItem(
      todoBundle: todo,
      onToggleDone: () {
        ref
            .read(personTodoActionsProvider)
            .toggleTodoDone(todoId: todo.todo.id, done: !todo.todo.done);
      },
      onToggleStar: () {
        ref
            .read(personTodoActionsProvider)
            .toggleTodoStarred(
              todoId: todo.todo.id,
              starred: !todo.todo.starred,
            );
      },
      onPressed: () => onPressedTodo(todo),
    );
  }
}

class _CompletedSectionHeader extends StatelessWidget {
  const _CompletedSectionHeader({
    required this.isExpanded,
    required this.count,
    required this.onPressed,
  });

  final bool isExpanded;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Text(
              'personTodo.completed.title'.tr(),
              style: context.tt.titleSmall?.copyWith(
                color: context.cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: context.tt.labelLarge?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.expand_more_rounded,
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
