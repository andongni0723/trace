import 'package:go_router/go_router.dart';

import '../../app_shell.dart';
import '../../features/app_settings/presentation/pages/app_settings_page.dart';
import '../../features/media_library/presentation/pages/media_library_page.dart';
import '../../features/people/presentation/pages/manage_database_properties_page.dart';
import '../../features/revision_log/presentation/pages/revision_log_page.dart';
import '../../shared/pages/messages_home_page.dart';
import '../../shared/pages/person_todo.dart';
import '../widgets/app_keyboard_focus_guard.dart';

final router = GoRouter(
  observers: [appKeyboardFocusRouteObserver],
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
          'note' => PersonTodoInitialTab.note,
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
    GoRoute(
      path: '/media-library',
      builder: (context, state) => const MediaLibraryPage(),
    ),
    GoRoute(
      path: '/revision-log',
      builder: (context, state) => const RevisionLogPage(),
    ),
  ],
);
