import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trace/core/routing/router.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/database/providers/database_provider.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/pages/messages_home_page.dart';

class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'app': {'title': 'Snap Ledger'},
    'appShell': {
      'navigation': {'list': '清單', 'database': '資料庫'},
    },
    'messages': {
      'todoTitle': '代辦事項',
      'newMessage': '新增訊息',
      'searchHint': '搜尋訊息',
      'people': {
        'cardPreview': '點一下查看這個人的待辦清單。',
        'empty': '還沒有朋友，點右下角新增第一位。',
        'loadError': '讀取朋友資料失敗。',
      },
      'tabs': {'all': '全部', 'unread': '未讀', 'groups': '群組'},
      'sample': {
        'mayaPreview': '線框稿已完成，我也補上更新後的 onboarding 流程。',
        'productTeamPreview': 'Sprint review 改到下午 3:30，請先確認議程。',
        'alexPreview': 'API 規格看起來沒問題，我午餐後會把修補版送出。',
        'familyPreview': '這週五去阿嬤家吃晚餐，別遲到。',
        'designPreview': '新的字級系統很不錯，我們應該再把空狀態簡化。',
      },
    },
    'database': {
      'title': '資料庫',
      'subtitle': '快速查看目前本機資料庫中的人物與待辦統計。',
      'loadError': '讀取資料庫摘要失敗。',
      'metrics': {
        'people': '人物數',
        'todos': '待辦總數',
        'openTodos': '未完成待辦',
        'completedTodos': '已完成待辦',
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

  testWidgets('messages home page renders key sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleProvider.overrideWith(
            (ref) => Stream.value([
              PeopleData(
                id: 'maya',
                name: 'Maya Chen',
                colorValue: 0xFF5B6CF0,
                avatarPath: null,
                createdAt: DateTime(2026, 3, 25),
                updatedAt: DateTime(2026, 3, 25),
              ),
              PeopleData(
                id: 'alex',
                name: 'Alex Johnson',
                colorValue: 0xFFE67E22,
                avatarPath: null,
                createdAt: DateTime(2026, 3, 25),
                updatedAt: DateTime(2026, 3, 25),
              ),
            ]),
          ),
          personPreviewTodoProvider.overrideWith((ref, personId) {
            return Stream.value(
              Todo(
                id: 'todo-$personId',
                personId: personId,
                title: personId == 'maya'
                    ? 'Review onboarding copy'
                    : 'Confirm API edge cases',
                note: null,
                starred: true,
                dueAt: null,
                done: false,
                createdAt: DateTime(2026, 3, 25),
                updatedAt: DateTime(2026, 3, 25),
              ),
            );
          }),
          personOpenTodoCountProvider.overrideWith((ref, personId) {
            return Stream.value(personId == 'maya' ? 3 : 1);
          }),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const TestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: const MessagesHomePage(enableStartupUpdateCheck: false),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('代辦事項'), findsOneWidget);
    expect(find.text('搜尋訊息'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('未讀'), findsOneWidget);
    expect(find.text('群組'), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('Review onboarding copy'), findsOneWidget);
    expect(find.text('Confirm API edge cases'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('最近對話'), findsNothing);
    expect(find.text('置頂更新'), findsNothing);
    expect(find.text('09:42'), findsNothing);
    expect(find.text('已讀'), findsNothing);
  });

  testWidgets('app shell exposes navigation to the database branch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleProvider.overrideWith(
            (ref) => Stream.value(const <PeopleData>[]),
          ),
          allTodosProvider.overrideWith((ref) => Stream.value(const <Todo>[])),
          personPreviewTodoProvider.overrideWith((ref, personId) {
            return Stream.value(null);
          }),
          personOpenTodoCountProvider.overrideWith((ref, personId) {
            return Stream.value(0);
          }),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const TestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                routerConfig: router,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('清單'), findsOneWidget);
    expect(find.text('資料庫'), findsOneWidget);

    await tester.tap(find.text('資料庫'));
    await tester.pumpAndSettle();

    expect(find.text('人物數'), findsOneWidget);
    expect(find.text('待辦總數'), findsOneWidget);
  });
}
