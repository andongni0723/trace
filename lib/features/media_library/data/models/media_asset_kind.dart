import 'package:path/path.dart' as p;

enum MediaAssetKind { image, audio, video }

extension MediaAssetKindX on MediaAssetKind {
  static const _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
    '.bmp',
    '.tif',
    '.tiff',
  };

  static const _videoExtensions = {
    '.mp4',
    '.mov',
    '.mkv',
    '.avi',
    '.webm',
    '.wmv',
    '.m4v',
    '.3gp',
  };

  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg',
    '.opus',
    '.amr',
  };

  static MediaAssetKind fromDbKey(String value) {
    return switch (value) {
      'image' => MediaAssetKind.image,
      'audio' => MediaAssetKind.audio,
      'video' => MediaAssetKind.video,
      _ => MediaAssetKind.image,
    };
  }

  static MediaAssetKind? fromFileExtension(String? extension) {
    final normalizedExtension = _normalizeExtension(extension);
    if (normalizedExtension == null) {
      return null;
    }
    if (_imageExtensions.contains(normalizedExtension)) {
      return MediaAssetKind.image;
    }
    if (_videoExtensions.contains(normalizedExtension)) {
      return MediaAssetKind.video;
    }
    if (_audioExtensions.contains(normalizedExtension)) {
      return MediaAssetKind.audio;
    }
    return null;
  }

  static String? guessMimeType(String? extension) {
    final normalizedExtension = _normalizeExtension(extension);
    if (normalizedExtension == null) {
      return null;
    }

    return switch (normalizedExtension) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      '.bmp' => 'image/bmp',
      '.tif' || '.tiff' => 'image/tiff',
      '.mp4' => 'video/mp4',
      '.mov' => 'video/quicktime',
      '.mkv' => 'video/x-matroska',
      '.avi' => 'video/x-msvideo',
      '.webm' => 'video/webm',
      '.wmv' => 'video/x-ms-wmv',
      '.m4v' => 'video/x-m4v',
      '.3gp' => 'video/3gpp',
      '.mp3' => 'audio/mpeg',
      '.m4a' => 'audio/mp4',
      '.aac' => 'audio/aac',
      '.wav' => 'audio/wav',
      '.flac' => 'audio/flac',
      '.ogg' => 'audio/ogg',
      '.opus' => 'audio/opus',
      '.amr' => 'audio/amr',
      _ => null,
    };
  }

  static List<String> get supportedExtensions => [
    ..._imageExtensions,
    ..._videoExtensions,
    ..._audioExtensions,
  ];

  static List<String> get supportedImageAudioAndVideoPickerExtensions => [
    ..._imageExtensions,
    ..._videoExtensions,
    ..._audioExtensions,
  ].map((extension) => extension.replaceFirst('.', '')).toList(growable: false);

  static List<String> get supportedImageAndAudioPickerExtensions =>
      supportedImageAudioAndVideoPickerExtensions;

  String get dbKey => switch (this) {
    MediaAssetKind.image => 'image',
    MediaAssetKind.audio => 'audio',
    MediaAssetKind.video => 'video',
  };

  String get localizationKey => switch (this) {
    MediaAssetKind.image => 'mediaLibrary.kind.image',
    MediaAssetKind.audio => 'mediaLibrary.kind.audio',
    MediaAssetKind.video => 'mediaLibrary.kind.video',
  };

  static String? _normalizeExtension(String? extension) {
    final trimmedExtension = extension?.trim().toLowerCase();
    if (trimmedExtension == null || trimmedExtension.isEmpty) {
      return null;
    }
    return trimmedExtension.startsWith('.')
        ? trimmedExtension
        : '.$trimmedExtension';
  }
}

MediaAssetKind? mediaAssetKindFromMimeType({
  required String? mimeType,
  required String fileName,
  required String filePath,
}) {
  final normalizedMimeType = mimeType?.trim().toLowerCase();
  if (normalizedMimeType != null && normalizedMimeType.isNotEmpty) {
    if (normalizedMimeType.startsWith('image/')) {
      return MediaAssetKind.image;
    }
    if (normalizedMimeType.startsWith('audio/')) {
      return MediaAssetKind.audio;
    }
    if (normalizedMimeType.startsWith('video/')) {
      return MediaAssetKind.video;
    }
  }

  final extension = p.extension(fileName.isNotEmpty ? fileName : filePath);
  return MediaAssetKindX.fromFileExtension(extension);
}
