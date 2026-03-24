import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people_todolist/core/database/database.dart';
import 'package:people_todolist/features/people/data/models/todo_with_people.dart';
import 'package:people_todolist/features/people/providers/person_detail_provider.dart';
import 'package:people_todolist/features/people/providers/people_provider.dart';
import 'package:people_todolist/shared/widgets/add_todo_bottom_sheet.dart';

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

class _FakePersonTodoActions extends PersonTodoActions {
  _FakePersonTodoActions() : super(ref: ProviderContainer().read, uuid: const Uuid());

  String? updatedNote;

  @override
  Future<void> updateTodo({
    required String todoId,
    required String title,
    String? note,
    DateTime? dueAt,
    required bool starred,
    List<String> participantPersonIds = const [],
  }) async {
    updatedNote = note;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editing keeps existing note when note field is hidden', (
    WidgetTester tester,
  ) async {
    final fakeActions = _FakePersonTodoActions();
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleProvider.overrideWith((ref) => Stream.value(const <PeopleData>[])),
          personTodoActionsProvider.overrideWithValue(fakeActions),
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

    expect(fakeActions.updatedNote, 'Existing note');
  });
}
