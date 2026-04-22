import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/core/routing/router.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/people_provider.dart';

class _AppShellManageDatabasePropertiesAssetLoader extends AssetLoader {
  const _AppShellManageDatabasePropertiesAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'appShell': {
      'drawer': {
        'openMenu': '開啟側邊選單',
        'mainPage': '主頁',
        'manageDatabaseProperties': '管理資料庫屬性',
        'mediaLibrary': '媒體資料管理',
        'settings': '設定',
        'feedback': '意見回饋',
      },
    },
    'databasePropertyManager': {
      'title': '管理資料庫屬性',
      'searchHint': '搜尋資料庫屬性',
      'libraryLabel': '全部屬性',
      'fab': {'tooltip': '建立根屬性'},
      'emptyTitle': '還沒有資料庫屬性',
      'emptyBody': '建立屬性後，就能在這裡重新整理整個 property tree。',
    },
    'mediaLibrary': {
      'title': '媒體資料管理',
      'searchHint': '搜尋媒體檔名',
      'fab': {'tooltip': '新增媒體檔案'},
      'emptyTitle': '尚未有媒體資料',
      'emptyBody': '點右上角按鈕新增音訊、影片或圖片。',
      'emptySearchTitle': '找不到符合的媒體',
      'emptySearchBody': '試著換個檔名或媒體類型再搜尋。',
    },
    'common': {'cancel': '取消'},
    'messages': {
      'searchHint': '搜尋訊息',
      'tabs': {'all': '全部', 'unread': '未讀', 'groups': '群組'},
      'people': {
        'empty': '還沒有朋友，點右下角新增第一位。',
        'noSearchResult': '找不到符合搜尋的人。',
        'loadError': '讀取朋友資料失敗。',
        'cardPreview': '點一下查看這個人的待辦清單。',
      },
      'selection': {
        'count': '已選取 {count} 項',
        'close': '結束選取',
        'group': '建立群組',
        'selectPerson': '選取 {name}',
        'deselectPerson': '取消選取 {name}',
      },
    },
    'appSettings': {
      'checkUpdate': {'openLinkError': '無法開啟連結。'},
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drawer can navigate to manage database properties page', (
    tester,
  ) async {
    router.go('/');
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          peopleProvider.overrideWith((ref) => Stream.value(const [])),
          personOpenTodoCountProvider.overrideWith((ref, personId) {
            return Stream.value(0);
          }),
          personPreviewTodoProvider.overrideWith((ref, personId) {
            return Stream.value(null);
          }),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _AppShellManageDatabasePropertiesAssetLoader(),
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

    await tester.tap(find.byTooltip('開啟側邊選單'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('管理資料庫屬性'));
    await tester.pumpAndSettle();

    expect(find.text('管理資料庫屬性'), findsWidgets);
    expect(find.byType(SearchBar), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('drawer can navigate to media library page', (tester) async {
    router.go('/');
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          peopleProvider.overrideWith((ref) => Stream.value(const [])),
          personOpenTodoCountProvider.overrideWith((ref, personId) {
            return Stream.value(0);
          }),
          personPreviewTodoProvider.overrideWith((ref, personId) {
            return Stream.value(null);
          }),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _AppShellManageDatabasePropertiesAssetLoader(),
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

    await tester.tap(find.byTooltip('開啟側邊選單'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('媒體資料管理'));
    await tester.pumpAndSettle();

    expect(find.text('媒體資料管理'), findsWidgets);
    expect(find.byType(SearchBar), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
