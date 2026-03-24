import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:people_todolist/core/database/database.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';
import 'package:people_todolist/features/people/data/models/todo_with_people.dart';
import 'package:people_todolist/features/people/providers/person_detail_provider.dart';
import 'package:people_todolist/shared/widgets/add_todo_bottom_sheet.dart';
import 'package:people_todolist/shared/widgets/person_note_card.dart';
import 'package:people_todolist/shared/widgets/person_todo_item.dart';

class PersonTodoPage extends ConsumerStatefulWidget {
  const PersonTodoPage({
    required this.personId,
    super.key,
  });

  final String personId;

  @override
  ConsumerState<PersonTodoPage> createState() => _PersonTodoPageState();
}

class _PersonTodoPageState extends ConsumerState<PersonTodoPage> {
  bool _isNoteExpanded = true;

  Future<void> _openAddTodoBottomSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => AddTodoBottomSheet(personId: widget.personId),
    );
  }

  Future<void> _openEditTodoBottomSheet(TodoWithPeople todo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => AddTodoBottomSheet(
        personId: widget.personId,
        initialTodo: todo,
      ),
    );
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
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(person.name),
            actions: [
              IconButton(
                onPressed: () {
                  context.push('/settings');
                },
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddTodoBottomSheet,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                PersonNoteCard(
                  isExpanded: _isNoteExpanded,
                  note: _personNote(person),
                  onToggle: () {
                    setState(() {
                      _isNoteExpanded = !_isNoteExpanded;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'personTodo.todoTitle'.tr(),
                  style: context.tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                todosAsync.when(
                  data: (todos) => _TodoListSection(
                    todos: todos,
                    onPressedTodo: _openEditTodoBottomSheet,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'personTodo.todoLoadError'.tr(),
                      style: context.tt.bodyMedium?.copyWith(
                        color: context.cs.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'personTodo.personLoadError'.tr(),
            style: context.tt.bodyLarge?.copyWith(
              color: context.cs.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoListSection extends ConsumerWidget {
  const _TodoListSection({
    required this.todos,
    required this.onPressedTodo,
  });

  final List<TodoWithPeople> todos;
  final ValueChanged<TodoWithPeople> onPressedTodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (todos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'personTodo.todoEmpty'.tr(),
          style: context.tt.bodyMedium?.copyWith(
            color: context.cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      spacing: 8,
      children: todos.map((todo) {
        return PersonTodoItem(
          todoBundle: todo,
          onToggleDone: () {
            ref.read(personTodoActionsProvider).toggleTodoDone(
                  todoId: todo.todo.id,
                  done: !todo.todo.done,
                );
          },
          onToggleStar: () {
            ref.read(personTodoActionsProvider).toggleTodoStarred(
                  todoId: todo.todo.id,
                  starred: !todo.todo.starred,
                );
          },
          onPressed: () => onPressedTodo(todo),
        );
      }).toList(growable: false),
    );
  }
}

String _personNote(PeopleData person) {
  return 'personTodo.noteFallback'.tr(
    namedArgs: {
      'name': person.name,
      'date': DateFormat.yMMMd().format(person.updatedAt),
    },
  );
}
