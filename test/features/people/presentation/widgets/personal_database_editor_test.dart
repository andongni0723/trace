import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/widgets/personal_database_editor.dart';

class _PersonalDatabaseEditorTestAssetLoader extends AssetLoader {
  const _PersonalDatabaseEditorTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'database': {
        'title': '個人資料庫',
        'action': {
          'edit': '編輯',
          'delete': '刪除',
          'addChild': '新增子項目',
          'addElement': '新增元素',
          'addFromTemplate': '從既有模板新增元素',
          'editTemplate': '編輯模板',
        },
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

  testWidgets('tapping mention segment calls onPressedMention', (tester) async {
    String? tappedPersonId;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseEditorTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: Scaffold(
                body: PersonalDatabaseEditor(
                  rows: const [
                    PersonalDatabaseEditorRowData(
                      nodeId: 'row-1',
                      fieldId: 'field-1',
                      rootFieldId: 'field-1',
                      path: [],
                      keyLabel: '關係',
                      valuePreview: '"@安東尼"',
                      rawValue: 'ignored',
                      valueType: PersonalDatabaseValueType.string,
                      depth: 0,
                      isExpanded: false,
                      isContainer: false,
                      isDefinitionBacked: true,
                      parentIsList: false,
                      valueSegments: [
                        PersonalDatabaseEditorValueSegment(text: '"'),
                        PersonalDatabaseEditorValueSegment(
                          text: '@安東尼',
                          personId: 'person-1',
                        ),
                        PersonalDatabaseEditorValueSegment(text: '"'),
                      ],
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  onPressedValue: (_) {},
                  onPressedAction: (_, __) {},
                  onPressedMention: (personId) {
                    tappedPersonId = personId;
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('@安東尼'));
    await tester.pumpAndSettle();

    expect(tappedPersonId, 'person-1');
  });

  testWidgets('disabled value row does not call onPressedValue', (
    tester,
  ) async {
    var didPressValue = false;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseEditorTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: Scaffold(
                body: PersonalDatabaseEditor(
                  rows: const [
                    PersonalDatabaseEditorRowData(
                      nodeId: 'media-row',
                      fieldId: 'field-media',
                      rootFieldId: 'field-media',
                      path: [],
                      keyLabel: '照片',
                      valuePreview: 'portrait.jpg',
                      rawValue: null,
                      valueType: PersonalDatabaseValueType.media,
                      depth: 0,
                      isExpanded: false,
                      isContainer: false,
                      isDefinitionBacked: true,
                      parentIsList: false,
                      isValueEnabled: false,
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  onPressedValue: (_) {
                    didPressValue = true;
                  },
                  onPressedAction: (_, __) {},
                  onPressedMention: (_) {},
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('portrait.jpg'));
    await tester.pumpAndSettle();

    expect(didPressValue, isFalse);
  });

  testWidgets('media value row is tappable by default', (tester) async {
    var didPressValue = false;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseEditorTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: Scaffold(
                body: PersonalDatabaseEditor(
                  rows: const [
                    PersonalDatabaseEditorRowData(
                      nodeId: 'media-row',
                      fieldId: 'field-media',
                      rootFieldId: 'field-media',
                      path: [],
                      keyLabel: '照片',
                      valuePreview: 'portrait.jpg',
                      rawValue: null,
                      valueType: PersonalDatabaseValueType.media,
                      depth: 0,
                      isExpanded: false,
                      isContainer: false,
                      isDefinitionBacked: true,
                      parentIsList: false,
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  onPressedValue: (_) {
                    didPressValue = true;
                  },
                  onPressedAction: (_, __) {},
                  onPressedMention: (_) {},
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('portrait.jpg'));
    await tester.pumpAndSettle();

    expect(didPressValue, isTrue);
  });

  testWidgets(
    'array row menu shows template action first and add element label',
    (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _PersonalDatabaseEditorTestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: Scaffold(
                  body: PersonalDatabaseEditor(
                    rows: const [
                      PersonalDatabaseEditorRowData(
                        nodeId: 'array-row',
                        fieldId: 'field-array',
                        rootFieldId: 'field-array',
                        path: [],
                        keyLabel: '寵物',
                        valuePreview: '[0] <物件>',
                        rawValue: [],
                        valueType: PersonalDatabaseValueType.list,
                        depth: 0,
                        isExpanded: false,
                        isContainer: true,
                        isDefinitionBacked: true,
                        parentIsList: false,
                        canAddFromTemplate: true,
                        canEditTemplate: true,
                      ),
                    ],
                    padding: EdgeInsets.zero,
                    onPressedValue: (_) {},
                    onPressedAction: (_, __) {},
                    onPressedMention: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      final addFromTemplate = find.text('從既有模板新增元素');
      final addElement = find.text('新增元素');
      final editTemplate = find.text('編輯模板');

      expect(addFromTemplate, findsOneWidget);
      expect(addElement, findsOneWidget);
      expect(find.text('新增子項目'), findsNothing);
      expect(editTemplate, findsOneWidget);

      expect(
        tester.getTopLeft(addFromTemplate).dy,
        lessThan(tester.getTopLeft(addElement).dy),
      );
      expect(
        tester.getTopLeft(addElement).dy,
        lessThan(tester.getTopLeft(editTemplate).dy),
      );
    },
  );
}
