import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/shared/pages/person_todo.dart';

class _PersonTodoTestAssetLoader extends AssetLoader {
  const _PersonTodoTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'tabs': {'todoList': '待辦清單', 'database': '資料庫'},
      'todoEmpty': '目前還沒有待辦事項。',
      'todoLoadError': '讀取待辦清單失敗。',
      'personMissing': '找不到人物。',
      'menu': {
        'more': '更多操作',
        'renamePerson': '重新命名人物',
        'deletePerson': '刪除人物',
      },
      'database': {
        'title': '個人資料庫',
        'emptyTitle': '還沒有屬性',
        'emptyBody': '從屬性庫選擇或建立屬性，開始記錄這個人的資料與情境資訊。',
        'loadError': '讀取個人資料庫失敗。',
      },
      'propertyChooser': {
        'title': '選擇屬性',
        'subtitle': '從屬性庫挑選一個要加入這個人的項目，或建立新的屬性。',
        'searchHint': '搜尋屬性',
        'libraryLabel': '屬性庫',
        'createNew': '＋ 建立新屬性',
        'createNewTitle': '建立新屬性',
        'emptyTitle': '尚未有屬性',
        'emptyBody': '先建立第一個屬性，之後就能重複加入不同人物。',
        'added': '已加入此人',
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

  testWidgets('personal database FAB opens choose property page', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _PersonTodoTestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: const PersonTodoPage(personId: 'owner'),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('資料庫'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('選擇屬性'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
