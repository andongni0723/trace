import 'package:flutter/services.dart';

class MediaAssetThumbnailer {
  const MediaAssetThumbnailer();

  static const _channel = MethodChannel('trace/media_thumbnailer');

  Future<String?> thumbnailForVideo(String videoPath) async {
    final trimmedPath = videoPath.trim();
    if (trimmedPath.isEmpty) {
      return null;
    }

    try {
      final thumbnailPath = await _channel.invokeMethod<String>(
        'thumbnailForVideo',
        {'videoPath': trimmedPath},
      );
      final normalizedPath = thumbnailPath?.trim();
      if (normalizedPath == null || normalizedPath.isEmpty) {
        return null;
      }
      return normalizedPath;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
