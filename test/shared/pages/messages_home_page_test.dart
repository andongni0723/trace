import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/pages/messages_home_page.dart';

class _MessagesHomeTestAssetLoader extends AssetLoader {
  const _MessagesHomeTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'appShell': {
      'drawer': {'openMenu': '開啟選單'},
    },
    'appSettings': {'comingSoon': '即將推出'},
    'messages': {
      'searchHint': '搜尋訊息',
      'tabs': {'all': '全部', 'unread': '未讀', 'groups': '群組'},
      'selection': {
        'count': '已選取 {count} 項',
        'close': '結束選取',
        'group': '建立群組',
        'selectPerson': '選取 {name}',
        'deselectPerson': '取消選取 {name}',
      },
      'people': {
        'cardPreview': '點一下查看這個人的待辦清單。',
        'empty': '還沒有朋友，點右下角新增第一位。',
        'noSearchResult': '找不到符合搜尋的人。',
        'loadError': '讀取朋友資料失敗。',
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

final _testPeople = [
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
];

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: MessagesHomePage(enableStartupUpdateCheck: false),
        ),
      ),
      GoRoute(
        path: '/people/:personId',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('person:${state.pathParameters['personId']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('settings'))),
      ),
    ],
  );
}

Future<GoRouter> _pumpMessagesHome(WidgetTester tester) async {
  final router = _buildRouter();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        peopleProvider.overrideWith((ref) => Stream.value(_testPeople)),
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
        assetLoader: const _MessagesHomeTestAssetLoader(),
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

  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap tile body still navigates to person detail', (tester) async {
    await _pumpMessagesHome(tester);

    await tester.tap(find.byKey(const Key('conversation-card-body-maya')));
    await tester.pumpAndSettle();

    expect(find.text('person:maya'), findsOneWidget);
  });

  testWidgets('long press tile enters selection mode and updates header', (
    tester,
  ) async {
    await _pumpMessagesHome(tester);

    await tester.longPress(
      find.byKey(const Key('conversation-card-body-maya')),
    );
    await tester.pumpAndSettle();

    expect(find.text('已選取 1 項'), findsOneWidget);
    expect(
      find.byKey(const Key('messages-home-selection-back')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('messages-home-selection-group')),
      findsOneWidget,
    );
  });

  testWidgets('tap avatar fast selects in normal mode', (tester) async {
    await _pumpMessagesHome(tester);

    await tester.tap(find.byKey(const Key('conversation-card-avatar-maya')));
    await tester.pumpAndSettle();

    expect(find.text('已選取 1 項'), findsOneWidget);
    expect(
      find.byKey(const Key('conversation-card-checkmark-maya')),
      findsOneWidget,
    );
  });

  testWidgets('tapping selected tile again exits selection mode at zero', (
    tester,
  ) async {
    await _pumpMessagesHome(tester);

    await tester.longPress(
      find.byKey(const Key('conversation-card-body-maya')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conversation-card-body-maya')));
    await tester.pumpAndSettle();

    expect(find.text('已選取 1 項'), findsNothing);
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.byKey(const Key('messages-home-selection-back')), findsNothing);
    expect(
      find.byKey(const Key('conversation-card-checkmark-maya')),
      findsNothing,
    );
  });

  testWidgets('selected tile uses selected background color', (tester) async {
    await _pumpMessagesHome(tester);

    await tester.tap(find.byKey(const Key('conversation-card-avatar-maya')));
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.byKey(const Key('conversation-card-maya')),
    );
    final decoration = container.decoration! as BoxDecoration;
    final context = tester.element(
      find.byKey(const Key('conversation-card-maya')),
    );

    expect(decoration.color, Theme.of(context).colorScheme.secondaryContainer);
  });

  testWidgets('group button shows coming soon snackbar', (tester) async {
    await _pumpMessagesHome(tester);

    await tester.longPress(
      find.byKey(const Key('conversation-card-body-maya')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('messages-home-selection-group')));
    await tester.pump();

    expect(find.text('即將推出'), findsOneWidget);
  });

  testWidgets('system back exits selection mode before leaving page', (
    tester,
  ) async {
    final router = await _pumpMessagesHome(tester);

    await tester.longPress(
      find.byKey(const Key('conversation-card-body-maya')),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/');
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('已選取 1 項'), findsNothing);
  });
}
