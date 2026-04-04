import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/features/people/data/models/personal_database_mention_suggestion.dart';
import 'package:trace/features/people/presentation/widgets/personal_database_mention_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows mention suggestions and inserts selected name', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final suggestions = [
      const PersonalDatabaseMentionSuggestion(
        id: '1',
        name: '安東尼',
        colorValue: 0xff3366ff,
      ),
      const PersonalDatabaseMentionSuggestion(
        id: '2',
        name: '阿明',
        colorValue: 0xffcc5500,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: PersonalDatabaseMentionTextField(
              controller: controller,
              focusNode: focusNode,
              labelText: 'Value',
              suggestions: suggestions,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '@');
    await tester.pumpAndSettle();

    expect(find.text('安東尼'), findsOneWidget);
    expect(find.text('阿明'), findsOneWidget);

    await tester.tap(find.text('安東尼').last);
    await tester.pumpAndSettle();

    expect(controller.text, '@安東尼');
    expect(find.text('安東尼'), findsNothing);
  });
}
