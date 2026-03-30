import 'package:go_router/go_router.dart';

import '../../app_shell.dart';
import '../../features/app_settings/presentation/pages/app_settings_page.dart';
import '../../features/database/presentation/pages/database_page.dart';
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/database',
              builder: (context, state) => const DatabasePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/people/:personId',
      builder: (context, state) {
        final personId = state.pathParameters['personId']!;
        return PersonTodoPage(personId: personId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const AppSettingsPage(),
    ),
  ],
);
