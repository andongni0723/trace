import 'package:flutter/services.dart';

class MediaAssetOpener {
  const MediaAssetOpener();

  static const _channel = MethodChannel('trace/media_opener');

  Future<bool> openMediaFile({
    required String filePath,
    String? mimeType,
  }) async {
    final didOpen = await _channel.invokeMethod<bool>('openMediaFile', {
      'filePath': filePath,
      'mimeType': mimeType,
    });
    return didOpen ?? false;
  }
}
