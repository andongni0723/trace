import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
