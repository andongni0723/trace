import 'package:flutter/material.dart';

class BottomSheetKeyboardInset extends StatelessWidget {
  const BottomSheetKeyboardInset({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: duration,
        curve: curve,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
