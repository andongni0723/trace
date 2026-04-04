import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/pages/choose_property_page.dart';

class _ChoosePropertyTestAssetLoader extends AssetLoader {
  const _ChoosePropertyTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'database': {'actionError': '個人資料庫更新失敗。'},
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
        'menu': {'editKeyName': '編輯 key 名稱', 'deleteProperty': '刪除屬性'},
        'renameDialog': {
          'title': '編輯 key 名稱',
          'label': 'Property key',
          'cancel': '取消',
          'save': '儲存',
        },
        'deleteDialog': {
          'title': '刪除屬性',
          'body': '確定要刪除屬性「{key}」嗎？這會刪除所有人物的同一個 property。',
          'cancel': '取消',
          'delete': '刪除',
        },
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

Future<void> _pumpChooserPage(
  WidgetTester tester, {
  required List<ChoosePropertyItem> properties,
  Future<ChoosePropertyItem?> Function(
    ChoosePropertyItem item,
    String newTitle,
  )?
  onRenameProperty,
  Future<void> Function(ChoosePropertyItem item)? onDeleteProperty,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      path: 'unused',
      assetLoader: const _ChoosePropertyTestAssetLoader(),
      fallbackLocale: const Locale('zh', 'TW'),
      startLocale: const Locale('zh', 'TW'),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            locale: context.locale,
            home: ChoosePropertyPage(
              properties: properties,
              onRenameProperty: onRenameProperty,
              onDeleteProperty: onDeleteProperty,
            ),
          );
        },
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('does not render chooser subtitle when properties exist', (
    tester,
  ) async {
    await _pumpChooserPage(
      tester,
      properties: const [
        ChoosePropertyItem(
          id: 'nickname',
          title: '暱稱',
          subtitle: 'String',
          valueType: PersonalDatabaseValueType.string,
          rawValue: 'Captain',
          valuePreview: 'Captain',
        ),
      ],
    );

    expect(find.text('選擇屬性'), findsOneWidget);
    expect(find.text('搜尋屬性'), findsOneWidget);
    expect(find.text('屬性庫'), findsOneWidget);
    expect(find.text('從屬性庫挑選一個要加入這個人的項目，或建立新的屬性。'), findsNothing);
  });

  testWidgets(
    'renders filled type tag on the left and checkbox selection state',
    (tester) async {
      await _pumpChooserPage(
        tester,
        properties: const [
          ChoosePropertyItem(
            id: 'assigned',
            title: 'Assigned title',
            subtitle: 'String',
            valueType: PersonalDatabaseValueType.string,
            rawValue: 'Alpha',
            valuePreview: 'Alpha preview',
            isAssignedToCurrentPerson: true,
          ),
          ChoosePropertyItem(
            id: 'available',
            title: 'Available title',
            subtitle: 'Boolean',
            valueType: PersonalDatabaseValueType.boolean,
            rawValue: true,
            valuePreview: 'Boolean preview',
          ),
        ],
      );

      expect(find.byIcon(Icons.short_text_rounded), findsNothing);
      expect(find.byIcon(Icons.toggle_on_rounded), findsNothing);
      expect(find.text('已加入此人'), findsNothing);
      expect(find.text('Alpha preview'), findsNothing);
      expect(find.text('Boolean preview'), findsNothing);
      expect(find.text('String'), findsOneWidget);
      expect(find.text('Boolean'), findsOneWidget);

      final assignedInkWell = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Assigned title'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      final availableInkWell = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Available title'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(assignedInkWell.onTap, isNull);
      expect(availableInkWell.onTap, isNotNull);

      final assignedTagFinder = find.byKey(
        const ValueKey('choose-property-type-tag-assigned'),
      );
      final availableTagFinder = find.byKey(
        const ValueKey('choose-property-type-tag-available'),
      );
      expect(assignedTagFinder, findsOneWidget);
      expect(availableTagFinder, findsOneWidget);
      expect(
        find.byKey(const ValueKey('choose-property-expand-available')),
        findsNothing,
      );

      final assignedTagLeft = tester.getTopLeft(assignedTagFinder).dx;
      final assignedTitleLeft = tester
          .getTopLeft(find.text('Assigned title'))
          .dx;
      final availableTagLeft = tester.getTopLeft(availableTagFinder).dx;
      final availableTitleLeft = tester
          .getTopLeft(find.text('Available title'))
          .dx;
      expect(assignedTagLeft, lessThan(assignedTitleLeft));
      expect(availableTagLeft, lessThan(availableTitleLeft));

      final assignedCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-assigned')),
      );
      final availableCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-available')),
      );
      expect(assignedCheckbox.value, isTrue);
      expect(assignedCheckbox.onChanged, isNull);
      expect(availableCheckbox.value, isFalse);
      expect(availableCheckbox.onChanged, isNotNull);
    },
  );

  testWidgets('can multi-select properties and submit them together', (
    tester,
  ) async {
    ChoosePropertyResult? result;
    var launched = false;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _ChoosePropertyTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: StatefulBuilder(
                builder: (context, _) {
                  if (!launched) {
                    launched = true;
                    Future<void>.microtask(() async {
                      result = await showChoosePropertyPage(
                        context: context,
                        properties: const [
                          ChoosePropertyItem(
                            id: 'alpha',
                            title: 'Alpha',
                            subtitle: 'String',
                            valueType: PersonalDatabaseValueType.string,
                            rawValue: 'A',
                            valuePreview: 'Preview A',
                          ),
                          ChoosePropertyItem(
                            id: 'beta',
                            title: 'Beta',
                            subtitle: 'Number',
                            valueType: PersonalDatabaseValueType.number,
                            rawValue: 1,
                            valuePreview: 'Preview B',
                          ),
                        ],
                      );
                    });
                  }
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('加入 0 個屬性'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('加入 2 個屬性'), findsOneWidget);

    await tester.tap(find.text('加入 2 個屬性'));
    await tester.pumpAndSettle();

    expect(result, isA<ChoosePropertySelected>());
    final selected = result as ChoosePropertySelected;
    expect(selected.items.map((item) => item.id), ['alpha', 'beta']);
  });

  testWidgets(
    'shows class subproperties by default and selecting parent selects all descendants',
    (tester) async {
      ChoosePropertyResult? result;
      var launched = false;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _ChoosePropertyTestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: StatefulBuilder(
                  builder: (context, _) {
                    if (!launched) {
                      launched = true;
                      Future<void>.microtask(() async {
                        result = await showChoosePropertyPage(
                          context: context,
                          properties: const [
                            ChoosePropertyItem(
                              id: 'profile',
                              title: 'Profile',
                              subtitle: 'Object',
                              valueType: PersonalDatabaseValueType.object,
                              rawValue: <String, Object?>{},
                              valuePreview: '{0}',
                              children: [
                                ChoosePropertyItem(
                                  id: 'nickname',
                                  parentId: 'profile',
                                  title: 'Nickname',
                                  subtitle: 'String',
                                  valueType: PersonalDatabaseValueType.string,
                                  rawValue: '',
                                  valuePreview: '""',
                                ),
                                ChoosePropertyItem(
                                  id: 'details',
                                  parentId: 'profile',
                                  title: 'Details',
                                  subtitle: 'Object',
                                  valueType: PersonalDatabaseValueType.object,
                                  rawValue: <String, Object?>{},
                                  valuePreview: '{0}',
                                  children: [
                                    ChoosePropertyItem(
                                      id: 'age',
                                      parentId: 'details',
                                      title: 'Age',
                                      subtitle: 'Number',
                                      valueType:
                                          PersonalDatabaseValueType.number,
                                      rawValue: 0,
                                      valuePreview: '0',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      });
                    }
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nickname'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('choose-property-expand-profile')),
        findsNothing,
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('加入 4 個屬性'), findsOneWidget);

      final profileCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-profile')),
      );
      final nicknameCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-nickname')),
      );
      final detailsCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-details')),
      );
      final ageCheckbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('choose-property-checkbox-age')),
      );

      expect(profileCheckbox.tristate, isTrue);
      expect(profileCheckbox.value, isTrue);
      expect(nicknameCheckbox.value, isTrue);
      expect(detailsCheckbox.value, isTrue);
      expect(ageCheckbox.value, isTrue);

      await tester.tap(find.text('加入 4 個屬性'));
      await tester.pumpAndSettle();

      expect(result, isA<ChoosePropertySelected>());
      final selected = result as ChoosePropertySelected;
      expect(selected.items.map((item) => item.id), [
        'profile',
        'nickname',
        'details',
        'age',
      ]);
    },
  );

  testWidgets('selecting a sub class selects its children and parents', (
    tester,
  ) async {
    ChoosePropertyResult? result;
    var launched = false;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _ChoosePropertyTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: StatefulBuilder(
                builder: (context, _) {
                  if (!launched) {
                    launched = true;
                    Future<void>.microtask(() async {
                      result = await showChoosePropertyPage(
                        context: context,
                        properties: const [
                          ChoosePropertyItem(
                            id: 'profile',
                            title: 'Profile',
                            subtitle: 'Object',
                            valueType: PersonalDatabaseValueType.object,
                            rawValue: <String, Object?>{},
                            valuePreview: '{0}',
                            children: [
                              ChoosePropertyItem(
                                id: 'details',
                                parentId: 'profile',
                                title: 'Details',
                                subtitle: 'Object',
                                valueType: PersonalDatabaseValueType.object,
                                rawValue: <String, Object?>{},
                                valuePreview: '{0}',
                                children: [
                                  ChoosePropertyItem(
                                    id: 'age',
                                    parentId: 'details',
                                    title: 'Age',
                                    subtitle: 'Number',
                                    valueType: PersonalDatabaseValueType.number,
                                    rawValue: 0,
                                    valuePreview: '0',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    });
                  }
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('加入 3 個屬性'), findsOneWidget);

    final profileCheckbox = tester.widget<Checkbox>(
      find.byKey(const ValueKey('choose-property-checkbox-profile')),
    );
    final detailsCheckbox = tester.widget<Checkbox>(
      find.byKey(const ValueKey('choose-property-checkbox-details')),
    );

    expect(profileCheckbox.value, isTrue);
    expect(detailsCheckbox.value, isTrue);

    await tester.tap(find.text('加入 3 個屬性'));
    await tester.pumpAndSettle();

    expect(result, isA<ChoosePropertySelected>());
    final selected = result as ChoosePropertySelected;
    expect(selected.items.map((item) => item.id), [
      'profile',
      'details',
      'age',
    ]);
  });

  testWidgets('renaming a nested property updates the visible tree', (
    tester,
  ) async {
    await _pumpChooserPage(
      tester,
      properties: const [
        ChoosePropertyItem(
          id: 'profile',
          title: 'Profile',
          subtitle: 'Object',
          valueType: PersonalDatabaseValueType.object,
          rawValue: <String, Object?>{},
          valuePreview: '{0}',
          children: [
            ChoosePropertyItem(
              id: 'nickname',
              parentId: 'profile',
              title: 'Nickname',
              subtitle: 'String',
              valueType: PersonalDatabaseValueType.string,
              rawValue: '',
              valuePreview: '""',
            ),
          ],
        ),
      ],
      onRenameProperty: (item, newTitle) async =>
          item.copyWith(title: newTitle),
    );

    await tester.longPress(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編輯 key 名稱'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Display name');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Nickname'), findsNothing);
  });

  testWidgets('deleting a nested property removes it from the visible tree', (
    tester,
  ) async {
    await _pumpChooserPage(
      tester,
      properties: const [
        ChoosePropertyItem(
          id: 'profile',
          title: 'Profile',
          subtitle: 'Object',
          valueType: PersonalDatabaseValueType.object,
          rawValue: <String, Object?>{},
          valuePreview: '{0}',
          children: [
            ChoosePropertyItem(
              id: 'nickname',
              parentId: 'profile',
              title: 'Nickname',
              subtitle: 'String',
              valueType: PersonalDatabaseValueType.string,
              rawValue: '',
              valuePreview: '""',
            ),
          ],
        ),
      ],
      onDeleteProperty: (_) async {},
    );

    await tester.longPress(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除屬性'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();

    expect(find.text('Nickname'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets(
    'uses grouped list radii and same surface color for create tile',
    (tester) async {
      await _pumpChooserPage(
        tester,
        properties: const [
          ChoosePropertyItem(
            id: 'first',
            title: 'First',
            subtitle: 'String',
            valueType: PersonalDatabaseValueType.string,
            rawValue: 'A',
            valuePreview: 'Preview A',
          ),
          ChoosePropertyItem(
            id: 'second',
            title: 'Second',
            subtitle: 'Number',
            valueType: PersonalDatabaseValueType.number,
            rawValue: 1,
            valuePreview: 'Preview B',
          ),
        ],
      );

      final firstTile = tester.widget<Material>(
        find.byKey(const ValueKey('choose-property-tile-first')),
      );
      final secondTile = tester.widget<Material>(
        find.byKey(const ValueKey('choose-property-tile-second')),
      );
      final createTile = tester.widget<Material>(
        find.byKey(const ValueKey('choose-property-create-tile')),
      );

      expect(
        firstTile.borderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      );
      expect(secondTile.borderRadius, BorderRadius.circular(4));
      expect(
        createTile.borderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      );
      expect(createTile.color, firstTile.color);
    },
  );

  testWidgets('long press opens menu and can rename a property', (
    tester,
  ) async {
    var renameCallCount = 0;

    await _pumpChooserPage(
      tester,
      properties: const [
        ChoosePropertyItem(
          id: 'nickname',
          title: '舊名稱',
          subtitle: 'String',
          valueType: PersonalDatabaseValueType.string,
          rawValue: 'Captain',
          valuePreview: 'Captain',
        ),
      ],
      onRenameProperty: (item, newTitle) async {
        renameCallCount += 1;
        return item.copyWith(title: newTitle);
      },
      onDeleteProperty: (item) async {},
    );

    await tester.longPress(find.text('舊名稱'));
    await tester.pumpAndSettle();

    expect(find.text('編輯 key 名稱'), findsOneWidget);
    expect(find.text('刪除屬性'), findsOneWidget);

    await tester.tap(find.text('編輯 key 名稱'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '新名稱',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(renameCallCount, 1);
    expect(find.text('新名稱'), findsOneWidget);
    expect(find.text('舊名稱'), findsNothing);
  });

  testWidgets('long press menu can delete a property from the local list', (
    tester,
  ) async {
    var deleteCallCount = 0;

    await _pumpChooserPage(
      tester,
      properties: const [
        ChoosePropertyItem(
          id: 'nickname',
          title: '要刪除的屬性',
          subtitle: 'String',
          valueType: PersonalDatabaseValueType.string,
          rawValue: 'Captain',
          valuePreview: 'Captain',
        ),
      ],
      onDeleteProperty: (item) async {
        deleteCallCount += 1;
      },
    );

    await tester.longPress(find.text('要刪除的屬性'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('刪除屬性'));
    await tester.pumpAndSettle();

    expect(
      find.text('確定要刪除屬性「要刪除的屬性」嗎？這會刪除所有人物的同一個 property。'),
      findsOneWidget,
    );

    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();

    expect(deleteCallCount, 1);
    expect(find.text('要刪除的屬性'), findsNothing);
  });
}
