import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/app_haptics.dart';
import 'core/utils/useful_extension.dart';
import 'shared/widgets/add_friend_bottom_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  Future<void> _openAddFriendBottomSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => const AddFriendBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          navigationShell.goBranch(
            index,
            initialLocation: index == selectedIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: 'appShell.navigation.list'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.storage_outlined),
            selectedIcon: const Icon(Icons.storage_rounded),
            label: 'appShell.navigation.database'.tr(),
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'app-shell-add-friend-fab',
              onPressed: () {
                AppHaptics.primaryAction();
                _openAddFriendBottomSheet(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
