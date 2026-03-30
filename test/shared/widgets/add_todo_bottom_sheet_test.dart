import 'package:easy_localization/easy_localization.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/todo_with_people.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/widgets/add_todo_bottom_sheet.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'addTodo': {
        'titleHint': '新增待辦事項',
        'noteHint': '新增備註',
        'save': '儲存',
        'update': '更新',
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editing keeps existing note when note field is hidden', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'person-1',
      name: 'Maya',
      colorValue: 0xFF5B6CF0,
    );
    final todo = Todo(
      id: 'todo-1',
      personId: 'person-1',
      title: 'Call Maya',
      note: 'Existing note',
      starred: false,
      dueAt: null,
      done: false,
      createdAt: DateTime(2026, 3, 25),
      updatedAt: DateTime(2026, 3, 25),
    );
    await database.todosDao.createTodo(
      id: todo.id,
      personId: todo.personId,
      title: todo.title,
      note: todo.note,
      starred: todo.starred,
      dueAt: todo.dueAt,
      done: todo.done,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          peopleProvider.overrideWith(
            (ref) => Stream.value(const <PeopleData>[]),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW')],
          path: 'unused',
          assetLoader: const _TestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: Scaffold(
                  body: AddTodoBottomSheet(
                    personId: 'person-1',
                    initialTodo: TodoWithPeople(
                      todo: todo,
                      relatedPeople: const [],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notes_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    final updatedTodo = await database.todosDao.getTodoById('todo-1');
    expect(updatedTodo, isNotNull);
    expect(updatedTodo!.note, 'Existing note');
  });
}
