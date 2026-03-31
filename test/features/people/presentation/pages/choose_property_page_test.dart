import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/presentation/pages/choose_property_page.dart';

class _ChoosePropertyTestAssetLoader extends AssetLoader {
  const _ChoosePropertyTestAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'personTodo': {
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

Future<void> _pumpChooserPage(
  WidgetTester tester, {
  required List<ChoosePropertyItem> properties,
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
            home: ChoosePropertyPage(properties: properties),
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

  testWidgets('renders compact property row with type label and state icon', (
    tester,
  ) async {
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

    final assignedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('choose-property-icon-assigned')),
    );
    final availableIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('choose-property-icon-available')),
    );
    expect(assignedIcon.icon, Icons.check_circle_rounded);
    expect(availableIcon.icon, Icons.arrow_forward_ios_rounded);
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
}
