import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/personal_database_mention.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/widgets/person_personal_database_tab.dart';
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
      'menu': {'more': '更多操作', 'renamePerson': '編輯人物', 'deletePerson': '刪除人物'},
      'database': {
        'title': '個人資料庫',
        'emptyTitle': '還沒有屬性',
        'emptyBody': '從屬性庫選擇或建立屬性，開始記錄這個人的資料與情境資訊。',
        'loadError': '讀取個人資料庫失敗。',
        'type': {
          'string': '字串',
          'number': '數字',
          'boolean': '布林',
          'object': '物件',
          'list': '陣列',
          'null': '空值',
        },
        'action': {'edit': '編輯', 'delete': '刪除', 'addChild': '新增子項目'},
        'sheet': {
          'editTitle': '編輯屬性',
          'update': '更新',
          'key': 'Key',
          'value': 'Value',
          'type': 'Type',
        },
        'cannotDeleteDialog': {
          'title': '無法移除',
          'body': '屬性「{key}」還有未隱藏的子屬性，請先隱藏所有子屬性後再移除。這裡的移除只會對這個人隱藏，不會真的刪掉屬性定義。',
          'confirm': '知道了',
        },
      },
      'propertyChooser': {
        'title': '選擇屬性',
        'subtitle': '從屬性庫挑選一個要加入這個人的項目，或建立新的屬性。',
        'searchHint': '搜尋屬性',
        'libraryLabel': '屬性庫',
        'apply': '加入 {count} 個屬性',
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
    await tester.pump(const Duration(milliseconds: 300));

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

  testWidgets('can assign multiple properties from chooser', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database
        .into(database.personalDatabaseFields)
        .insert(
          PersonalDatabaseFieldsCompanion.insert(
            id: 'field-a',
            key: '暱稱',
            valueType: 'string',
            isPublic: const Value(true),
            ownerPersonId: const Value(null),
          ),
        );
    await database
        .into(database.personalDatabaseFields)
        .insert(
          PersonalDatabaseFieldsCompanion.insert(
            id: 'field-b',
            key: '年齡',
            valueType: 'number',
            isPublic: const Value(true),
            ownerPersonId: const Value(null),
          ),
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
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('資料庫'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('暱稱'));
    await tester.pump();
    await tester.tap(find.text('年齡'));
    await tester.pump();
    await tester.tap(find.text('加入 2 個屬性'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final assignments =
        await (database.select(database.personalDatabasePersonFields)
              ..where((table) => table.personId.equals('owner'))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final fieldIds = assignments.map((row) => row.fieldId).toList();
    final fieldRows = await (database.select(
      database.personalDatabaseFields,
    )..where((table) => table.id.isIn(fieldIds))).get();
    final keyById = {for (final field in fieldRows) field.id: field.key};

    expect(fieldIds, unorderedEquals(['field-a', 'field-b']));
    expect(fieldIds.map((fieldId) => keyById[fieldId]).toSet(), {'暱稱', '年齡'});

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('chooser shows legacy object subproperties after backfill', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personalDatabaseDao.createField(
      id: 'field-profile',
      actorPersonId: 'owner',
      key: '資料',
      type: PersonalDatabaseValueType.object,
      isPublic: true,
      jsonValue: '{"暱稱":"Cap"}',
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
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('資料庫'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('選擇屬性'), findsOneWidget);
    expect(find.text('資料'), findsOneWidget);
    expect(find.text('暱稱'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('can open directly on personal database tab', (tester) async {
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
                home: const PersonTodoPage(
                  personId: 'owner',
                  initialTab: PersonTodoInitialTab.database,
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
      findsOneWidget,
    );
    expect(find.text('個人資料庫'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'cannot delete object property while visible subproperties still exist',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-profile',
        personId: 'owner',
        key: '資料',
        type: PersonalDatabaseValueType.object,
        jsonValue: '{}',
      );
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-nickname',
        personId: 'owner',
        key: '暱稱',
        type: PersonalDatabaseValueType.string,
        jsonValue: '"Cap"',
        parentFieldId: 'field-profile',
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
                  home: const Scaffold(
                    body: PersonPersonalDatabaseTab(personId: 'owner'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();

      expect(find.text('無法移除'), findsOneWidget);
      expect(
        find.text('屬性「資料」還有未隱藏的子屬性，請先隱藏所有子屬性後再移除。這裡的移除只會對這個人隱藏，不會真的刪掉屬性定義。'),
        findsOneWidget,
      );

      final assignments = await (database.select(
        database.personalDatabasePersonFields,
      )..where((table) => table.personId.equals('owner'))).get();
      expect(assignments.map((row) => row.fieldId).toSet(), {
        'field-profile',
        'field-nickname',
      });

      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('editing personal database property only updates value', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-nickname',
      personId: 'owner',
      key: '暱稱',
      type: PersonalDatabaseValueType.string,
      jsonValue: '"Old value"',
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
                home: const Scaffold(
                  body: PersonPersonalDatabaseTab(personId: 'owner'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();

    expect(find.text('Key'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('暱稱'), findsWidgets);
    expect(find.text('字串'), findsOneWidget);
    expect(find.byType(DropdownMenu<PersonalDatabaseValueType>), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'New value');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    final ownerFields = await database.personalDatabaseDao
        .getFieldTreeForPerson('owner');
    expect(ownerFields.single.key, '暱稱');
    expect(ownerFields.single.type, PersonalDatabaseValueType.string);
    expect(ownerFields.single.value, 'New value');

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'editing list child uses child value type instead of root list type',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );
      await database.personalDatabaseDao.createFieldAndAssignToPerson(
        id: 'field-tags',
        personId: 'owner',
        key: '標籤',
        type: PersonalDatabaseValueType.list,
        jsonValue: '["Old item"]',
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
                  home: const Scaffold(
                    body: PersonPersonalDatabaseTab(personId: 'owner'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('[1]'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('編輯'));
      await tester.pumpAndSettle();

      expect(
        find.byType(DropdownMenu<PersonalDatabaseValueType>),
        findsOneWidget,
      );
      expect(find.text('字串'), findsWidgets);

      await tester.enterText(find.byType(TextField).last, 'New item');
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      final ownerFields = await database.personalDatabaseDao
          .getFieldTreeForPerson('owner');
      expect(ownerFields.single.value, ['New item']);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('self mention does not push another person route', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const codec = PersonalDatabaseMentionCodec();

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-self',
      personId: 'owner',
      key: '關係',
      type: PersonalDatabaseValueType.string,
      jsonValue:
          '"Hello ${codec.encodeMention(const PersonalDatabasePersonMention(personId: 'owner', displayName: 'Owner'))}"',
    );

    final router = GoRouter(
      initialLocation: '/people/owner',
      routes: [
        GoRoute(
          path: '/people/:personId',
          builder: (context, state) => Scaffold(
            body: PersonPersonalDatabaseTab(
              personId: state.pathParameters['personId']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

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

    await tester.tap(find.text('@Owner'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/people/owner',
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('missing mention target does not push another person route', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const codec = PersonalDatabaseMentionCodec();

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-missing',
      personId: 'owner',
      key: '關係',
      type: PersonalDatabaseValueType.string,
      jsonValue:
          '"Hello ${codec.encodeMention(const PersonalDatabasePersonMention(personId: 'missing-person', displayName: 'Ghost'))}"',
    );

    final router = GoRouter(
      initialLocation: '/people/owner',
      routes: [
        GoRoute(
          path: '/people/:personId',
          builder: (context, state) => Scaffold(
            body: PersonPersonalDatabaseTab(
              personId: state.pathParameters['personId']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

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

    await tester.tap(find.text('@Ghost'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/people/owner',
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
