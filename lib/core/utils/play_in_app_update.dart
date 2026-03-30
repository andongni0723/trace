import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum InAppUpdateFlow { none, immediate, flexible }

class PlayInAppUpdate {
  PlayInAppUpdate._();

  static const MethodChannel _channel = MethodChannel('trace/in_app_update');

  static Future<InAppUpdateFlow> checkForUpdate() async {
    if (!Platform.isAndroid) return InAppUpdateFlow.none;

    try {
      final result = await _channel.invokeMethod<String>('checkForUpdate');
      return switch (result) {
        'immediate' => InAppUpdateFlow.immediate,
        'flexible' => InAppUpdateFlow.flexible,
        _ => InAppUpdateFlow.none,
      };
    } on PlatformException catch (error) {
      debugPrint('[InAppUpdate] check skipped: ${error.code} ${error.message}');
      return InAppUpdateFlow.none;
    }
  }

  static Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('completeFlexibleUpdate');
    } on PlatformException catch (error) {
      debugPrint(
        '[InAppUpdate] completion failed: ${error.code} ${error.message}',
      );
    }
  }
}
