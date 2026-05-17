import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trace/core/widgets/app_keyboard_focus_guard.dart';

void main() {
  testWidgets('route changes unfocus the active input field', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    final router = GoRouter(
      observers: [AppKeyboardFocusRouteObserver()],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focusNode),
                  TextButton(
                    onPressed: () => context.push('/next'),
                    child: const Text('Next'),
                  ),
                ],
              ),
            );
          },
        ),
        GoRoute(
          path: '/next',
          builder: (context, state) {
            return const Scaffold(body: Text('Next page'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
    expect(find.text('Next page'), findsOneWidget);
  });

  testWidgets('hidden keyboard unfocuses the active input field', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    addTearDown(tester.view.resetViewInsets);

    await _pumpGuardInAppBuilder(tester, focusNode);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}

Future<void> _pumpGuardInAppBuilder(
  WidgetTester tester,
  FocusNode focusNode,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) {
        return AppKeyboardFocusGuard(child: child ?? const SizedBox.shrink());
      },
      home: Scaffold(body: TextField(focusNode: focusNode)),
    ),
  );
  await tester.pumpAndSettle();
}
