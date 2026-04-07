import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_mention.dart';
import 'package:trace/features/people/data/models/personal_database_mention_suggestion.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/widgets/personal_database_field_sheet.dart';

class _PersonalDatabaseFieldSheetTestAssetLoader extends AssetLoader {
  const _PersonalDatabaseFieldSheetTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
      'database': {
        'sheet': {
          'type': 'Type',
          'value': 'Value',
          'invalidList': 'Invalid list',
          'invalidObject': 'Invalid object',
        },
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _zhTw;
  }
}

Future<PersonalDatabaseFieldSheetResult?> _openSheet(
  WidgetTester tester, {
  required PersonalDatabaseValueType type,
  required Object? initialValue,
}) async {
  PersonalDatabaseFieldSheetResult? result;

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      path: 'unused',
      assetLoader: const _PersonalDatabaseFieldSheetTestAssetLoader(),
      fallbackLocale: const Locale('zh', 'TW'),
      startLocale: const Locale('zh', 'TW'),
      child: Builder(
        builder: (localizationContext) {
          return MaterialApp(
            supportedLocales: localizationContext.supportedLocales,
            localizationsDelegates: localizationContext.localizationDelegates,
            locale: localizationContext.locale,
            home: Builder(
              builder: (materialContext) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        result = await showPersonalDatabaseFieldSheet(
                          context: materialContext,
                          title: 'Edit property',
                          submitLabel: 'Save',
                          showKeyInput: false,
                          initialType: type,
                          initialValue: initialValue,
                        );
                      },
                      child: const Text('Open'),
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

  await tester.pump();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).last, '');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('can hide value input and still submit default value', (
    tester,
  ) async {
    PersonalDatabaseFieldSheetResult? result;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseFieldSheetTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (localizationContext) {
            return MaterialApp(
              supportedLocales: localizationContext.supportedLocales,
              localizationsDelegates: localizationContext.localizationDelegates,
              locale: localizationContext.locale,
              home: Builder(
                builder: (materialContext) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () async {
                          result = await showPersonalDatabaseFieldSheet(
                            context: materialContext,
                            title: 'Create property',
                            submitLabel: 'Create',
                            showKeyInput: true,
                            showValueInput: false,
                            initialType: PersonalDatabaseValueType.number,
                          );
                        },
                        child: const Text('Open'),
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

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Value'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '欄位');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.key, '欄位');
    expect(result!.type, PersonalDatabaseValueType.number);
    expect(result!.value, 0);
  });

  testWidgets('empty list input saves as empty list', (tester) async {
    final result = await _openSheet(
      tester,
      type: PersonalDatabaseValueType.list,
      initialValue: const ['existing'],
    );

    expect(result, isNotNull);
    expect(result!.type, PersonalDatabaseValueType.list);
    expect(result.value, isA<List<Object?>>());
    expect(result.value, isEmpty);
  });

  testWidgets('empty object input saves as empty object', (tester) async {
    final result = await _openSheet(
      tester,
      type: PersonalDatabaseValueType.object,
      initialValue: const {'existing': true},
    );

    expect(result, isNotNull);
    expect(result!.type, PersonalDatabaseValueType.object);
    expect(result.value, isA<Map<String, Object?>>());
    expect(result.value, isEmpty);
  });

  testWidgets('string input decodes and re-encodes stored mention tokens', (
    tester,
  ) async {
    const codec = PersonalDatabaseMentionCodec();
    const mention = PersonalDatabasePersonMention(
      personId: 'person-1',
      displayName: '安東尼',
    );
    PersonalDatabaseFieldSheetResult? result;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseFieldSheetTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (localizationContext) {
            return MaterialApp(
              supportedLocales: localizationContext.supportedLocales,
              localizationsDelegates: localizationContext.localizationDelegates,
              locale: localizationContext.locale,
              home: Builder(
                builder: (materialContext) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () async {
                          result = await showPersonalDatabaseFieldSheet(
                            context: materialContext,
                            title: 'Edit property',
                            submitLabel: 'Save',
                            showKeyInput: false,
                            initialType: PersonalDatabaseValueType.string,
                            initialValue:
                                'Hello ${codec.encodeMention(mention)}',
                            mentionCodec: codec,
                          );
                        },
                        child: const Text('Open'),
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

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).last);
    expect(textField.controller?.text, 'Hello @安東尼');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result?.value, 'Hello ${codec.encodeMention(mention)}');
  });

  testWidgets('string input saves selected mention as token', (tester) async {
    const codec = PersonalDatabaseMentionCodec();
    PersonalDatabaseFieldSheetResult? result;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseFieldSheetTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (localizationContext) {
            return MaterialApp(
              supportedLocales: localizationContext.supportedLocales,
              localizationsDelegates: localizationContext.localizationDelegates,
              locale: localizationContext.locale,
              home: Builder(
                builder: (materialContext) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () async {
                          result = await showPersonalDatabaseFieldSheet(
                            context: materialContext,
                            title: 'Edit property',
                            submitLabel: 'Save',
                            showKeyInput: false,
                            initialType: PersonalDatabaseValueType.string,
                            mentionSuggestions: const [
                              PersonalDatabaseMentionSuggestion(
                                id: 'person-2',
                                name: '小美',
                                colorValue: 0xFF3366FF,
                              ),
                            ],
                            mentionCodec: codec,
                          );
                        },
                        child: const Text('Open'),
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

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '@');
    await tester.pumpAndSettle();
    await tester.tap(find.text('小美').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      result?.value,
      codec.encodeMention(
        const PersonalDatabasePersonMention(
          personId: 'person-2',
          displayName: '小美',
        ),
      ),
    );
  });

  testWidgets('string input prefers latest suggestion name for existing token', (
    tester,
  ) async {
    const codec = PersonalDatabaseMentionCodec();
    const staleMention = PersonalDatabasePersonMention(
      personId: 'person-3',
      displayName: '舊名字',
    );
    PersonalDatabaseFieldSheetResult? result;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
        path: 'unused',
        assetLoader: const _PersonalDatabaseFieldSheetTestAssetLoader(),
        fallbackLocale: const Locale('zh', 'TW'),
        startLocale: const Locale('zh', 'TW'),
        child: Builder(
          builder: (localizationContext) {
            return MaterialApp(
              supportedLocales: localizationContext.supportedLocales,
              localizationsDelegates: localizationContext.localizationDelegates,
              locale: localizationContext.locale,
              home: Builder(
                builder: (materialContext) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () async {
                          result = await showPersonalDatabaseFieldSheet(
                            context: materialContext,
                            title: 'Edit property',
                            submitLabel: 'Save',
                            showKeyInput: false,
                            initialType: PersonalDatabaseValueType.string,
                            initialValue:
                                'Hello ${codec.encodeMention(staleMention)}',
                            mentionSuggestions: const [
                              PersonalDatabaseMentionSuggestion(
                                id: 'person-3',
                                name: '新名字',
                                colorValue: 0xFF3366FF,
                              ),
                            ],
                            mentionCodec: codec,
                          );
                        },
                        child: const Text('Open'),
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

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).last);
    expect(textField.controller?.text, 'Hello @新名字');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      result?.value,
      'Hello ${codec.encodeMention(const PersonalDatabasePersonMention(personId: 'person-3', displayName: '新名字'))}',
    );
  });
}
