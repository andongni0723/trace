import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/todo_with_people.dart';
import 'package:trace/shared/widgets/person_todo_item.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'time': {
      'todayAt': '今天 {time}',
      'tomorrowAt': '明天 {time}',
      'yesterdayAt': '昨天 {time}',
      'inMinutes': '{count}分鐘後',
      'inHours': '{count}小時後',
      'minutesAgo': '{count}分鐘前',
      'hoursAgo': '{count}小時前',
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({required Todo todo, required DateTime currentTime}) {
    return ProviderScope(
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
                body: PersonTodoItem(
                  todoBundle: TodoWithPeople(
                    todo: todo,
                    relatedPeople: const [],
                  ),
                  currentTime: currentTime,
                  onToggleDone: () {},
                  onToggleStar: () {},
                  onPressed: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('shows relative future due date for nearby time', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 3, 25, 12);
    final todo = Todo(
      id: 'todo-1',
      personId: 'person-1',
      title: 'Call Maya',
      note: null,
      starred: false,
      dueAt: now.add(const Duration(hours: 2)),
      done: false,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(buildSubject(todo: todo, currentTime: now));
    await tester.pumpAndSettle();

    expect(find.text('2小時後'), findsOneWidget);
  });

  testWidgets('shows overdue due date in error color', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 3, 25, 12);
    final todo = Todo(
      id: 'todo-2',
      personId: 'person-1',
      title: 'Send draft',
      note: null,
      starred: false,
      dueAt: now.subtract(const Duration(minutes: 30)),
      done: false,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(buildSubject(todo: todo, currentTime: now));
    await tester.pumpAndSettle();

    expect(find.text('30分鐘前'), findsOneWidget);

    final context = tester.element(find.byType(PersonTodoItem));
    final expectedColor = Theme.of(context).colorScheme.error;
    final icon = tester.widget<Icon>(find.byIcon(Icons.schedule_rounded));
    final text = tester.widget<Text>(find.text('30分鐘前'));

    expect(icon.color, expectedColor);
    expect(text.style?.color, expectedColor);
  });
}
