import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/pages/manage_database_properties_page.dart';
import 'package:trace/features/people/providers/people_database_providers.dart'
    as people_db;

class _ManageDatabasePropertiesTestAssetLoader extends AssetLoader {
  const _ManageDatabasePropertiesTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'database': {
        'type': {
          'string': '字串',
          'number': '數字',
          'boolean': '布林',
          'null': 'Null',
          'list': '清單',
          'object': '物件',
        },
        'sheet': {
          'key': '屬性名稱',
          'type': '型別',
          'value': '值',
          'invalidList': '清單格式不正確',
          'invalidObject': '物件格式不正確',
        },
      },
    },
    'databasePropertyManager': {
      'title': '管理資料庫屬性',
      'searchHint': '搜尋屬性',
      'libraryLabel': '屬性庫',
      'loadError': '讀取屬性庫失敗。',
      'emptyTitle': '尚未有屬性',
      'emptyBody': '先建立第一個屬性，之後就能在這裡調整順序與內容。',
      'emptySearchTitle': '找不到符合的屬性',
      'emptySearchBody': '試著換個關鍵字搜尋。',
      'objectChildren': '{count} 個子屬性',
      'rootOption': '主層級',
      'fab': {'tooltip': '建立根屬性'},
      'action': {
        'rename': '重新命名',
        'addSubproperty': '新增子屬性',
        'retype': '變更類型',
        'retypeHint': '改變這個 property 的 value type。',
        'retypeDisabled': '這個物件還有子屬性，不能直接變更類型。',
        'delete': '刪除屬性',
      },
      'renameDialog': {
        'title': '重新命名屬性',
        'label': '屬性名稱',
        'cancel': '取消',
        'save': '儲存',
      },
      'retypeDialog': {'title': '變更屬性型別', 'save': '儲存'},
      'createRootTitle': '新增根屬性',
      'createRootSubmit': '建立',
      'createSubTitle': '新增子屬性',
      'createSubSubmit': '建立',
      'deleteDialog': {
        'title': '刪除屬性',
        'body': '確定要刪除屬性「{key}」嗎？',
        'delete': '刪除',
      },
      'error': {
        'confirm': '知道了',
        'retypeBlockedTitle': '無法變更類型',
        'retypeBlockedBody': '這個 object property 還有子屬性，請先調整或移除子屬性後再變更類型。',
        'deleteBlockedTitle': '無法刪除屬性',
        'deleteBlockedBody': '還有人正在使用這個 property，所以現在不能刪除。',
        'moveBlockedTitle': '無法移動屬性',
        'moveScopeConflictBody': '屬性只能在同一層級重新排序，不能離開或加入其他 object。',
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

Future<void> _pumpManageDatabasePropertiesPage(
  WidgetTester tester,
  AppDatabase database,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [people_db.appDatabaseProvider.overrideWithValue(database)],
      child: EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _ManageDatabasePropertiesTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: const ManageDatabasePropertiesPage(),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'property tile does not show preview text and drag handle is leading',
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

      await _pumpManageDatabasePropertiesPage(tester, database);
      await tester.pumpAndSettle();

      expect(find.text('Cap'), findsNothing);
      expect(
        find.byKey(const ValueKey('manage-database-properties-fab')),
        findsOneWidget,
      );

      final dragHandle = find.byKey(
        const ValueKey('manage-database-property-drag-field-profile'),
      );
      final title = find.text('資料');
      expect(dragHandle, findsOneWidget);
      expect(title, findsOneWidget);
      expect(
        tester.getTopLeft(dragHandle).dx,
        lessThan(tester.getTopLeft(title).dx),
      );

      await tester.tap(title);
      await tester.pumpAndSettle();

      expect(find.text('新增子屬性'), findsOneWidget);
      expect(find.text('重新命名'), findsOneWidget);
      expect(find.text('變更類型'), findsOneWidget);
      expect(find.text('刪除屬性'), findsOneWidget);
    },
  );

  testWidgets('object actions sheet exposes add subproperty', (tester) async {
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

    await _pumpManageDatabasePropertiesPage(tester, database);
    await tester.pumpAndSettle();
    await tester.tap(find.text('資料'));
    await tester.pumpAndSettle();

    expect(find.text('新增子屬性'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tap chevron collapses subproperties', (tester) async {
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

    await _pumpManageDatabasePropertiesPage(tester, database);
    await tester.pumpAndSettle();

    expect(find.text('暱稱'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('manage-database-property-expand-field-profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暱稱'), findsNothing);
  });

  testWidgets('drag reorder smoke test moves root properties', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.peopleDao.createPerson(
      id: 'owner',
      name: 'Owner',
      colorValue: 0xFF111111,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-a',
      personId: 'owner',
      key: '甲',
      type: PersonalDatabaseValueType.string,
      jsonValue: '"A"',
      sortOrder: 0,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-b',
      personId: 'owner',
      key: '乙',
      type: PersonalDatabaseValueType.string,
      jsonValue: '"B"',
      sortOrder: 1,
    );

    await _pumpManageDatabasePropertiesPage(tester, database);
    await tester.pumpAndSettle();

    final firstHandle = find.byKey(
      const ValueKey('manage-database-property-drag-field-a'),
    );
    expect(firstHandle, findsOneWidget);

    await tester.drag(firstHandle, const Offset(0, 400));
    await tester.pumpAndSettle();

    final topLeftA = tester.getTopLeft(find.text('甲'));
    final topLeftB = tester.getTopLeft(find.text('乙'));
    expect(topLeftB.dy, lessThan(topLeftA.dy));
  });

  testWidgets('drag reorder keeps child property in the same parent', (
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
      id: 'field-profile',
      personId: 'owner',
      key: '資料',
      type: PersonalDatabaseValueType.object,
      jsonValue: '{}',
      sortOrder: 0,
    );
    await database.personalDatabaseDao.createFieldDefinition(
      id: 'field-nickname',
      key: '暱稱',
      type: PersonalDatabaseValueType.string,
      isPublic: true,
      parentFieldId: 'field-profile',
      sortOrder: 0,
    );
    await database.personalDatabaseDao.createFieldAndAssignToPerson(
      id: 'field-other',
      personId: 'owner',
      key: '其他',
      type: PersonalDatabaseValueType.string,
      jsonValue: '"X"',
      sortOrder: 1,
    );

    await _pumpManageDatabasePropertiesPage(tester, database);
    await tester.pumpAndSettle();

    final childHandle = find.byKey(
      const ValueKey('manage-database-property-drag-field-nickname'),
    );
    expect(childHandle, findsOneWidget);

    await tester.drag(childHandle, const Offset(0, -300));
    await tester.pumpAndSettle();

    final library = await database.personalDatabaseDao.getFieldLibrary();
    final profile = library.firstWhere((field) => field.id == 'field-profile');
    final nickname = profile.children.firstWhere(
      (field) => field.id == 'field-nickname',
    );
    expect(nickname.parentFieldId, 'field-profile');
  });
}
