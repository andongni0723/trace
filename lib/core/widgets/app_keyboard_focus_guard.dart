import 'package:flutter/material.dart';

final appKeyboardFocusRouteObserver = AppKeyboardFocusRouteObserver();

void dismissPrimaryFocus() {
  final primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus == null || !primaryFocus.hasFocus) {
    return;
  }

  primaryFocus.unfocus();
}

class AppKeyboardFocusRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    dismissPrimaryFocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    dismissPrimaryFocus();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    dismissPrimaryFocus();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    dismissPrimaryFocus();
  }
}

class AppKeyboardFocusGuard extends StatefulWidget {
  const AppKeyboardFocusGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AppKeyboardFocusGuard> createState() => _AppKeyboardFocusGuardState();
}

class _AppKeyboardFocusGuardState extends State<AppKeyboardFocusGuard>
    with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = _currentBottomViewInset();
    if (bottomInset == null) {
      return;
    }

    final wasKeyboardVisible = _isKeyboardVisible;
    _isKeyboardVisible = bottomInset > 0;
    if (!wasKeyboardVisible || _isKeyboardVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_currentBottomViewInset() ?? 0) == 0) {
        dismissPrimaryFocus();
      }
    });
  }

  double? _currentBottomViewInset() {
    final view = View.maybeOf(context);
    if (view == null) {
      return null;
    }

    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
