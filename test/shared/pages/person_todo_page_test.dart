import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/media_library/data/models/media_asset_kind.dart';
import 'package:trace/features/media_library/data/services/media_asset_opener.dart';
import 'package:trace/features/media_library/providers/media_library_providers.dart';
import 'package:trace/features/people/data/models/personal_database_mention.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/widgets/person_personal_database_tab.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/shared/pages/person_todo.dart';

class _PersonTodoTestAssetLoader extends AssetLoader {
  const _PersonTodoTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'tabs': {'todoList': '待辦清單', 'note': '備註', 'database': '資料庫'},
      'note': {
        'hint': '寫下和這個人相關的筆記...',
        'personChip': '@ 人',
        'mediaChip': '媒體檔',
        'peoplePickerTitle': '選擇人物',
      },
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
          'media': '媒體',
          'object': '物件',
          'list': '陣列',
          'null': '空值',
        },
        'action': {
          'edit': '編輯',
          'delete': '刪除',
          'addChild': '新增子項目',
          'addElement': '新增元素',
          'addFromTemplate': '從既有模板新增元素',
          'editTemplate': '編輯模板',
        },
        'sheet': {
          'addChildTitle': '新增子項目',
          'create': '建立',
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
    'databasePropertyManager': {
      'arrayElement': {'unspecified': '未指定'},
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

class _RecordingMediaAssetOpener extends MediaAssetOpener {
  String? openedPath;
  String? openedMimeType;

  @override
  Future<bool> openMediaFile({required String filePath, String? mimeType}) {
    openedPath = filePath;
    openedMimeType = mimeType;
    return Future.value(true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    await tester.pumpAndSettle();

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
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'person-database-add-fab-owner',
      ),
      findsOneWidget,
    );
    expect(find.text('資料庫'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note tab saves plain text note for person', (tester) async {
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

    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();

    final noteField = tester.widget<TextField>(find.byType(TextField));
    expect(noteField.decoration?.border, InputBorder.none);
    expect(noteField.decoration?.enabledBorder, InputBorder.none);
    expect(noteField.decoration?.focusedBorder, InputBorder.none);
    expect(
      find.byWidgetPredicate((widget) => widget is FloatingActionButton),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), '記得下次聊咖啡豆');
    await tester.pump(const Duration(milliseconds: 600));

    final note = await database.personNotesDao.getNoteForPerson('owner');
    expect(note, isNotNull);
    expect(note!.content, '記得下次聊咖啡豆');

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note tab loads existing note from database', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personNotesDao.upsertNote(
      personId: 'owner',
      content: '已存在的備註',
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

    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();

    final noteField = tester.widget<TextField>(find.byType(TextField));
    expect(noteField.controller?.text, '已存在的備註');

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note token behaves as an atomic editable chip', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    const token = '![Alice](person:friend)';
    const content = 'Before $token after';

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.peopleDao.createPerson(
      id: 'friend',
      name: 'Alice',
      colorValue: 0xFF222222,
    );
    await database.personNotesDao.upsertNote(
      personId: 'owner',
      content: content,
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

    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();

    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    const tokenPlaceholder = '\uFFFC';
    const displayContent = 'Before $tokenPlaceholder after';
    final tokenStart = controller.text.indexOf(tokenPlaceholder);
    final tokenEnd = tokenStart + tokenPlaceholder.length;
    expect(controller.text, displayContent);
    expect(find.text('Alice'), findsOneWidget);

    final plainTextOffset = displayContent.indexOf('after') + 2;
    controller.value = controller.value.copyWith(
      selection: TextSelection.collapsed(offset: plainTextOffset),
      composing: TextRange.empty,
    );
    controller.value = controller.value.copyWith(
      text: displayContent.replaceRange(plainTextOffset, plainTextOffset, 'Z'),
      selection: TextSelection.collapsed(offset: plainTextOffset + 1),
      composing: TextRange.empty,
    );
    expect(controller.text, 'Before $tokenPlaceholder afZter');

    await tester.pump(const Duration(milliseconds: 600));
    final editedNote = await database.personNotesDao.getNoteForPerson('owner');
    expect(editedNote?.content, 'Before $token afZter');

    controller.value = controller.value.copyWith(
      selection: TextSelection.collapsed(offset: tokenEnd),
      composing: TextRange.empty,
    );
    controller.value = controller.value.copyWith(
      text: controller.text.replaceRange(tokenEnd - 1, tokenEnd, ''),
      selection: TextSelection.collapsed(offset: tokenEnd - 1),
      composing: TextRange.empty,
    );
    expect(controller.text, 'Before  afZter');
    expect(controller.text, isNot(contains('![')));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note person token opens the tagged person page', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.peopleDao.createPerson(
      id: 'friend',
      name: 'Friend',
      colorValue: 0xFF222222,
    );
    await database.personNotesDao.upsertNote(
      personId: 'owner',
      content: 'Intro\n![Friend](person:friend) after',
    );

    final router = GoRouter(
      initialLocation: '/people/owner?tab=note',
      routes: [
        GoRoute(
          path: '/people/:personId',
          builder: (context, state) {
            final initialTab = switch (state.uri.queryParameters['tab']) {
              'note' => PersonTodoInitialTab.note,
              'database' => PersonTodoInitialTab.database,
              _ => PersonTodoInitialTab.todoList,
            };
            return PersonTodoPage(
              personId: state.pathParameters['personId']!,
              initialTab: initialTab,
            );
          },
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/people/owner?tab=note',
    );
    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();
    expect(find.text('Friend'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Friend')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byWidgetPredicate(
        (widget) => widget is PersonTodoPage && widget.personId == 'friend',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note person token only opens when tapping the token', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.peopleDao.createPerson(
      id: 'friend',
      name: 'Friend',
      colorValue: 0xFF222222,
    );
    await database.personNotesDao.upsertNote(
      personId: 'owner',
      content: '![Friend](person:friend) after',
    );

    final router = GoRouter(
      initialLocation: '/people/owner?tab=note',
      routes: [
        GoRoute(
          path: '/people/:personId',
          builder: (context, state) {
            final initialTab = switch (state.uri.queryParameters['tab']) {
              'note' => PersonTodoInitialTab.note,
              'database' => PersonTodoInitialTab.database,
              _ => PersonTodoInitialTab.todoList,
            };
            return PersonTodoPage(
              personId: state.pathParameters['personId']!,
              initialTab: initialTab,
            );
          },
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
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();
    expect(find.text('Friend'), findsOneWidget);

    final noteFieldRect = tester.getRect(find.byType(TextField));
    await tester.tapAt(
      Offset(noteFieldRect.right - 24, noteFieldRect.top + 28),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/people/owner?tab=note',
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('note media token opens the tagged media file', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final mediaFile = File('/private/tmp/trace_note_media_test_photo.jpg');
    addTearDown(() {
      if (mediaFile.existsSync()) {
        mediaFile.deleteSync();
      }
    });
    mediaFile.writeAsBytesSync(const [1, 2, 3]);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.mediaAssetsDao.insertMediaAsset(
      id: 'asset-1',
      displayName: 'Photo',
      originalFileName: 'photo.jpg',
      kind: MediaAssetKind.image,
      sizeBytes: 3,
      filePath: mediaFile.path,
      mimeType: 'image/jpeg',
    );
    await database.personNotesDao.upsertNote(
      personId: 'owner',
      content: 'Before ![Photo](media:asset-1) after',
    );

    final mediaOpener = _RecordingMediaAssetOpener();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          mediaAssetOpenerProvider.overrideWithValue(mediaOpener),
        ],
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
                  initialTab: PersonTodoInitialTab.note,
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('備註'));
    await tester.pumpAndSettle();

    expect(find.text('Photo'), findsOneWidget);

    final noteFieldTopLeft = tester.getTopLeft(find.byType(TextField));
    await tester.tapAt(noteFieldTopLeft + const Offset(155, 28));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(mediaOpener.openedPath, mediaFile.path);
    expect(mediaOpener.openedMimeType, 'image/jpeg');

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

      await tester.tap(find.textContaining('[1]'));
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

  testWidgets('list row with string element type only adds string elements', (
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
      id: 'field-tags',
      personId: 'owner',
      key: '標籤',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[]',
      arrayElementType: PersonalDatabaseValueType.string,
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
    await tester.tap(find.text('新增元素'));
    await tester.pumpAndSettle();

    expect(find.text('Type'), findsOneWidget);
    expect(find.text('字串'), findsOneWidget);
    expect(find.byType(DropdownMenu<PersonalDatabaseValueType>), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'VIP');
    await tester.tap(find.text('建立'));
    await tester.pumpAndSettle();

    final ownerFields = await database.personalDatabaseDao
        .getFieldTreeForPerson('owner');
    expect(ownerFields.single.value, ['VIP']);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('list row with object element type defaults to object elements', (
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
      id: 'field-pets',
      personId: 'owner',
      key: '寵物',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[]',
      arrayElementType: PersonalDatabaseValueType.object,
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
    await tester.tap(find.text('新增元素'));
    await tester.pumpAndSettle();

    expect(find.text('物件'), findsOneWidget);
    expect(find.byType(DropdownMenu<PersonalDatabaseValueType>), findsNothing);

    await tester.tap(find.text('建立'));
    await tester.pumpAndSettle();

    final ownerFields = await database.personalDatabaseDao
        .getFieldTreeForPerson('owner');
    expect(ownerFields.single.value, [<String, Object?>{}]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('list row without element type keeps type picker when adding', (
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
      id: 'field-tags',
      personId: 'owner',
      key: '標籤',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[]',
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
    await tester.tap(find.text('新增元素'));
    await tester.pumpAndSettle();

    expect(
      find.byType(DropdownMenu<PersonalDatabaseValueType>),
      findsOneWidget,
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('list row can add object element from saved template', (
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
      id: 'field-pets',
      personId: 'owner',
      key: '寵物',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[]',
      arrayElementType: PersonalDatabaseValueType.object,
      arrayElementTemplateJsonValue: '{"名字":"Cap"}',
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
    await tester.tap(find.text('從既有模板新增元素'));
    await tester.pumpAndSettle();

    final ownerFields = await database.personalDatabaseDao
        .getFieldTreeForPerson('owner');
    expect(ownerFields.single.value, [
      {'名字': 'Cap'},
    ]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('nested list row can add object element from saved template', (
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
      id: 'field-family',
      personId: 'owner',
      key: '家族',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[{"孩子":[]}]',
      arrayElementType: PersonalDatabaseValueType.object,
      arrayElementTemplateJsonValue:
          '{"孩子":[],"__traceArrayElementTemplates":{"孩子":{"elementType":"object","template":{"名字":"小孩"}}}}',
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

    await tester.tap(find.textContaining('[1]'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('{1}'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded).at(2));
    await tester.pumpAndSettle();
    expect(find.text('從既有模板新增元素'), findsOneWidget);
    expect(find.text('編輯模板'), findsOneWidget);

    await tester.tap(find.text('從既有模板新增元素'));
    await tester.pumpAndSettle();

    final ownerFields = await database.personalDatabaseDao
        .getFieldTreeForPerson('owner');
    expect(ownerFields.single.value, [
      {
        '孩子': [
          {'名字': '小孩'},
        ],
      },
    ]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('nested list row exposes edit template without saved template', (
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
      id: 'field-family',
      personId: 'owner',
      key: '家族',
      type: PersonalDatabaseValueType.list,
      jsonValue: '[{"孩子":[]}]',
      arrayElementType: PersonalDatabaseValueType.object,
      arrayElementTemplateJsonValue: '{"孩子":[]}',
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

    await tester.tap(find.textContaining('[1]'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('{1}'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded).at(2));
    await tester.pumpAndSettle();

    expect(find.text('編輯模板'), findsOneWidget);
    expect(find.text('從既有模板新增元素'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

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

  testWidgets(
    'expanded initial property setting shows subproperties immediately',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {
        'app_settings.initial_property_display_mode': 'expanded',
      });

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

      expect(find.text('暱稱'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
