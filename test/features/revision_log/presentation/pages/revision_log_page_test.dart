import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/revision_log/data/models/revision_log_action.dart';
import 'package:trace/features/revision_log/presentation/pages/revision_log_page.dart';

class _RevisionLogPageAssetLoader extends AssetLoader {
  const _RevisionLogPageAssetLoader();

  static const Map<String, dynamic> _zhTw = {
    'revisionLog': {
      'title': '修改紀錄',
      'emptyTitle': '還沒有修改紀錄',
      'emptyBody': '資料修改後會顯示在這裡。',
      'closeTooltip': '關閉修改紀錄',
      'clearTooltip': '清空紀錄',
      'clearDialog': {
        'title': '清空修改紀錄',
        'body': '確定要清空所有修改紀錄嗎？',
        'cancel': '取消',
        'confirm': '清空',
      },
      'details': {
        'title': '修改詳情',
        'closeTooltip': '關閉詳情',
        'time': '時間',
        'entity': '資料',
        'action': '動作',
        'summary': '摘要',
        'changedFields': '變更欄位',
        'before': '變更前',
        'after': '變更後',
      },
      'actions': {
        'create': '新增',
        'update': '更新',
        'delete': '刪除',
        'import': '匯入',
        'export': '匯出',
        'settings': '設定',
        'clearLogs': '清空紀錄',
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

  testWidgets('shows revision log cards, details, and clear dialog', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.revisionLogsDao.insertLog(
      id: 'log-1',
      action: RevisionLogAction.update,
      entityType: 'person',
      entityId: 'person-1',
      entityLabel: 'Maya',
      summary: 'Updated person Maya',
      changedFieldsJson: '["name"]',
      beforeJson: '{"name":"May"}',
      afterJson: '{"name":"Maya"}',
      happenedAt: DateTime(2026, 6, 10, 21, 27, 22, 792),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
          path: 'unused',
          assetLoader: const _RevisionLogPageAssetLoader(),
          fallbackLocale: const Locale('zh', 'TW'),
          startLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                locale: context.locale,
                theme: ThemeData(useMaterial3: true),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                ),
                home: const RevisionLogPage(),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('修改紀錄'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
    expect(find.text('Updated person Maya'), findsOneWidget);
    expect(find.text('21:27:22.792'), findsOneWidget);

    await tester.tap(find.text('Updated person Maya'));
    await tester.pumpAndSettle();

    expect(find.text('修改詳情'), findsOneWidget);
    expect(find.text('2026-06-10 21:27:22.792'), findsOneWidget);
    expect(find.textContaining('"name":"May"'), findsOneWidget);

    await tester.tap(find.byTooltip('關閉詳情'));
    await tester.pumpAndSettle();
    expect(find.text('修改詳情'), findsNothing);

    await tester.tap(find.byTooltip('清空紀錄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空').last);
    await tester.pumpAndSettle();

    expect(await database.revisionLogsDao.getRecentLogs(), isEmpty);
    expect(find.text('還沒有修改紀錄'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
