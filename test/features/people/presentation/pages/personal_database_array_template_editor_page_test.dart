import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/pages/personal_database_array_template_editor_page.dart';

class _TemplateEditorTestAssetLoader extends AssetLoader {
  const _TemplateEditorTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'database': {
        'type': {
          'string': '字串',
          'number': '數字',
          'boolean': '布林',
          'media': '媒體',
          'null': '空值',
          'list': '陣列',
          'object': '物件',
        },
        'sheet': {'type': '型別'},
        'action': {'delete': '刪除'},
      },
    },
    'databasePropertyManager': {
      'action': {
        'changeElementType': '變更元素類型',
        'editElementTemplate': '編輯元素模板',
      },
      'arrayElement': {'unspecified': '未指定'},
      'elementTypeDialog': {'title': '變更元素型別', 'save': '儲存'},
    },
    'personalDatabaseTemplateEditor': {
      'save': '儲存',
      'addProperty': '新增屬性',
      'action': {
        'editObject': '編輯物件結構',
        'editTemplate': '編輯元素模板',
        'editProperty': '編輯屬性',
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

  testWidgets(
    'saving unchanged unspecified nested element type keeps metadata absent',
    (tester) async {
      Map<String, Object?>? result;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _TemplateEditorTestAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                home: Builder(
                  builder: (pageContext) {
                    return Scaffold(
                      body: Center(
                        child: FilledButton(
                          key: const ValueKey('open-template-editor'),
                          onPressed: () async {
                            result =
                                await showPersonalDatabaseArrayTemplateEditorPage(
                                  context: pageContext,
                                  title: '模板',
                                  initialTemplate: const {'pets': []},
                                );
                          },
                          child: const Text('open'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open-template-editor')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('未指定'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '儲存'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, '儲存'));
      await tester.pumpAndSettle();

      expect(result, const {'pets': []});
    },
  );

  testWidgets('can save recursive list element metadata', (tester) async {
    Map<String, Object?>? result;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _TemplateEditorTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              home: Builder(
                builder: (pageContext) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        key: const ValueKey('open-template-editor'),
                        onPressed: () async {
                          result =
                              await showPersonalDatabaseArrayTemplateEditorPage(
                                context: pageContext,
                                title: '模板',
                                initialTemplate: const {'matrix': []},
                              );
                        },
                        child: const Text('open'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-template-editor')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('未指定'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenu<PersonalDatabaseValueType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('陣列').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownMenu<PersonalDatabaseValueType?>).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('物件').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '儲存').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '儲存').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '儲存'));
    await tester.pumpAndSettle();

    expect(result, {
      'matrix': [],
      '__traceArrayElementTemplates': {
        'matrix': {
          'elementType': 'list',
          'elementMetadata': {
            'elementType': 'object',
            'template': <String, Object?>{},
          },
        },
      },
    });
  });
}
