import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/media_asset_kind.dart';
import '../models/media_import_candidate.dart';

enum MediaAssetPickerMode {
  image,
  video,
  audio,
  singleAudio,
  imageAudioOrVideo,
}

class MediaAssetPicker {
  MediaAssetPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  bool _isPicking = false;

  Future<List<MediaImportCandidate>> pickMediaFiles({
    required MediaAssetPickerMode mode,
  }) async {
    if (_isPicking) {
      return const [];
    }

    _isPicking = true;
    try {
      return await switch (mode) {
        MediaAssetPickerMode.image => _pickImageFile(),
        MediaAssetPickerMode.video => _pickVideoFile(),
        MediaAssetPickerMode.audio => _pickAudioFiles(),
        MediaAssetPickerMode.singleAudio => _pickAudioFiles(
          allowMultiple: false,
        ),
        MediaAssetPickerMode.imageAudioOrVideo => _pickImageAudioOrVideoFile(),
      };
    } on PlatformException catch (error) {
      if (_isRedundantPickerRequest(error)) {
        return const [];
      }
      rethrow;
    } finally {
      _isPicking = false;
    }
  }

  Future<List<MediaImportCandidate>> _pickImageFile() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return const [];
    }

    return _xFilesToCandidates(
      [file],
      allowedKinds: const {MediaAssetKind.image},
    );
  }

  Future<List<MediaImportCandidate>> _pickVideoFile() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null) {
      return const [];
    }

    return _xFilesToCandidates(
      [file],
      allowedKinds: const {MediaAssetKind.video},
    );
  }

  Future<List<MediaImportCandidate>> _xFilesToCandidates(
    List<XFile> files, {
    required Set<MediaAssetKind> allowedKinds,
  }) async {
    if (files.isEmpty) {
      return const [];
    }

    final candidates = <MediaImportCandidate>[];
    for (final file in files) {
      final sourcePath = file.path.trim();
      if (sourcePath.isEmpty) {
        continue;
      }

      final kind = mediaAssetKindFromMimeType(
        mimeType: null,
        fileName: p.basename(sourcePath),
        filePath: sourcePath,
      );
      if (kind == null || !allowedKinds.contains(kind)) {
        continue;
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        continue;
      }

      candidates.add(
        MediaImportCandidate(
          sourcePath: sourcePath,
          fileName: p.basename(sourcePath),
          sizeBytes: await sourceFile.length(),
          kind: kind,
          mimeType: MediaAssetKindX.guessMimeType(p.extension(sourcePath)),
        ),
      );
    }

    return candidates;
  }

  Future<List<MediaImportCandidate>> _pickAudioFiles({
    bool allowMultiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: allowMultiple,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final candidates = <MediaImportCandidate>[];
    for (final file in result.files) {
      final sourcePath = file.path;
      if (sourcePath == null || sourcePath.trim().isEmpty) {
        continue;
      }

      final kind = mediaAssetKindFromMimeType(
        mimeType: null,
        fileName: file.name,
        filePath: sourcePath,
      );
      if (kind != MediaAssetKind.audio) {
        continue;
      }

      candidates.add(
        MediaImportCandidate(
          sourcePath: sourcePath,
          fileName: file.name.isEmpty ? p.basename(sourcePath) : file.name,
          sizeBytes: file.size,
          kind: kind!,
          mimeType: MediaAssetKindX.guessMimeType(p.extension(sourcePath)),
        ),
      );
    }

    return candidates;
  }

  Future<List<MediaImportCandidate>> _pickImageAudioOrVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          MediaAssetKindX.supportedImageAudioAndVideoPickerExtensions,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final file = result.files.single;
    final sourcePath = file.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return const [];
    }

    final kind = mediaAssetKindFromMimeType(
      mimeType: null,
      fileName: file.name,
      filePath: sourcePath,
    );
    if (kind != MediaAssetKind.image &&
        kind != MediaAssetKind.audio &&
        kind != MediaAssetKind.video) {
      return const [];
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return const [];
    }

    return [
      MediaImportCandidate(
        sourcePath: sourcePath,
        fileName: file.name.isEmpty ? p.basename(sourcePath) : file.name,
        sizeBytes: file.size > 0 ? file.size : await sourceFile.length(),
        kind: kind!,
        mimeType: MediaAssetKindX.guessMimeType(p.extension(sourcePath)),
      ),
    ];
  }

  bool _isRedundantPickerRequest(PlatformException error) {
    return error.code == 'multiple_request';
  }
}
