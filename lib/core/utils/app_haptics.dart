import 'package:flutter/services.dart';

final class AppHaptics {
  const AppHaptics._();

  static void primaryAction() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void confirm() {
    HapticFeedback.mediumImpact();
  }
}
