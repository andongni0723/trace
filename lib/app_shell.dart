import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/utils/app_haptics.dart';
import 'core/utils/useful_extension.dart';
import 'shared/providers/messages_home_selection_mode_provider.dart';
import 'shared/widgets/add_friend_bottom_sheet.dart';

const _feedbackIssuesUrl = 'https://github.com/andongni0723/trace/issues';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  Future<void> _openAddFriendBottomSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => const AddFriendBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectionMode = ref.watch(messagesHomeSelectionModeProvider);

    return Scaffold(
      drawer: _AppShellDrawer(shellContext: context),
      body: navigationShell,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isSelectionMode
            ? const SizedBox.shrink(key: ValueKey('app-shell-fab-hidden'))
            : FloatingActionButton(
                key: const ValueKey('app-shell-add-friend-fab'),
                heroTag: 'app-shell-add-friend-fab',
                onPressed: () {
                  AppHaptics.primaryAction();
                  _openAddFriendBottomSheet(context);
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

class _AppShellDrawer extends StatelessWidget {
  const _AppShellDrawer({required this.shellContext});

  final BuildContext shellContext;
  static const _mainPageDestinationIndex = 0;
  static const _manageDatabasePropertiesDestinationIndex = 1;
  static const _settingsDestinationIndex = 2;
  static const _feedbackDestinationIndex = 3;

  void _openSettings(BuildContext drawerContext) {
    final router = GoRouter.of(shellContext);
    Navigator.of(drawerContext).pop();
    router.push('/settings');
  }

  Future<void> _openFeedback(BuildContext drawerContext) async {
    final messenger = ScaffoldMessenger.of(shellContext);
    Navigator.of(drawerContext).pop();

    final didLaunch = await launchUrl(
      Uri.parse(_feedbackIssuesUrl),
      mode: LaunchMode.externalApplication,
    );
    if (didLaunch) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('appSettings.checkUpdate.openLinkError'.tr())),
      );
  }

  void _openMainPage(BuildContext drawerContext) {
    final router = GoRouter.of(shellContext);
    Navigator.of(drawerContext).pop();
    router.go('/');
  }

  void _openManageDatabaseProperties(BuildContext drawerContext) {
    final router = GoRouter.of(shellContext);
    Navigator.of(drawerContext).pop();
    router.push('/manage-database-properties');
  }

  void _handleDestinationSelected(BuildContext context, int index) {
    AppHaptics.selection();

    switch (index) {
      case _mainPageDestinationIndex:
        _openMainPage(context);
      case _manageDatabasePropertiesDestinationIndex:
        _openManageDatabaseProperties(context);
      case _settingsDestinationIndex:
        _openSettings(context);
      case _feedbackDestinationIndex:
        _openFeedback(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: _mainPageDestinationIndex,
      onDestinationSelected: (index) =>
          _handleDestinationSelected(context, index),
      tilePadding : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/icon/trace_icon_foreground_v2.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Trace',
                style: context.tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        NavigationDrawerDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text('appShell.drawer.mainPage'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2_rounded),
          label: Text('appShell.drawer.manageDatabaseProperties'.tr()),
        ),
        const Divider(height: 1, thickness: 1),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: Text('appShell.drawer.settings'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.feedback_outlined),
          selectedIcon: const Icon(Icons.feedback_rounded),
          label: Text('appShell.drawer.feedback'.tr()),
        ),
      ],
    );
  }
}
