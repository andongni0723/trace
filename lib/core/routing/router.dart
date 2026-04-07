import 'package:go_router/go_router.dart';

import '../../app_shell.dart';
import '../../features/app_settings/presentation/pages/app_settings_page.dart';
import '../../features/people/presentation/pages/manage_database_properties_page.dart';
import '../../shared/pages/messages_home_page.dart';
import '../../shared/pages/person_todo.dart';

final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const MessagesHomePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/people/:personId',
      builder: (context, state) {
        final personId = state.pathParameters['personId']!;
        final initialTab = switch (state.uri.queryParameters['tab']) {
          'database' => PersonTodoInitialTab.database,
          _ => PersonTodoInitialTab.todoList,
        };
        return PersonTodoPage(personId: personId, initialTab: initialTab);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const AppSettingsPage(),
    ),
    GoRoute(
      path: '/manage-database-properties',
      builder: (context, state) => const ManageDatabasePropertiesPage(),
    ),
  ],
);
