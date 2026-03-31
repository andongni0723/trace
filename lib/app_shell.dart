import 'package:flutter/material.dart';
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
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: context.cs.surface,
      builder: (_) => const AddFriendBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        heroTag: 'app-shell-add-friend-fab',
        onPressed: () {
          AppHaptics.primaryAction();
          _openAddFriendBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
