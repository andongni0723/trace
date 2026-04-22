import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/media_library/data/models/media_asset_kind.dart';
import 'package:trace/features/media_library/data/models/media_import_candidate.dart';
import 'package:trace/features/media_library/data/services/media_asset_picker.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/media_library/providers/media_library_providers.dart';

import '../test_media_asset_storage.dart';

class _FakeMediaAssetPicker extends MediaAssetPicker {
  _FakeMediaAssetPicker(this._candidates);

  final List<MediaImportCandidate> _candidates;

  @override
  Future<List<MediaImportCandidate>> pickMediaFiles({
    required MediaAssetPickerMode mode,
  }) async {
    return _candidates;
  }
}

void main() {
  test('media picker extensions include images, videos, and audio', () {
    final extensions =
        MediaAssetKindX.supportedImageAudioAndVideoPickerExtensions;

    expect(extensions, contains('jpg'));
    expect(extensions, contains('mp4'));
    expect(extensions, contains('mp3'));
    expect(extensions.every((extension) => !extension.startsWith('.')), isTrue);
  });

  test('media library filters and imports picked files', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final storage = TestMediaAssetStorage();
    addTearDown(storage.clearManagedMediaFiles);

    final sourceFile = File(
      '${Directory.systemTemp.path}/trace_media_provider_video.mp4',
    );
    await sourceFile.writeAsBytes([4, 5, 6, 7], flush: true);
    addTearDown(sourceFile.delete);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        mediaAssetStorageProvider.overrideWithValue(storage),
        mediaAssetPickerProvider.overrideWithValue(
          _FakeMediaAssetPicker([
            MediaImportCandidate(
              sourcePath: sourceFile.path,
              fileName: 'clip.mp4',
              sizeBytes: 4,
              kind: MediaAssetKind.video,
              mimeType: 'video/mp4',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(mediaLibraryActionsProvider).setSearchQuery('clip');
    expect(container.read(mediaLibraryFilterProvider).query, 'clip');

    final importedAssets = await container
        .read(mediaLibraryActionsProvider)
        .importMediaFiles(mode: MediaAssetPickerMode.video);
    expect(importedAssets, hasLength(1));
    expect(importedAssets.single.displayName, 'clip.mp4');

    final watchedAssets = await container
        .read(mediaAssetsDaoProvider)
        .getMediaAssets();
    expect(watchedAssets, hasLength(1));
    expect(watchedAssets.single.kind, MediaAssetKind.video);
    expect(watchedAssets.single.originalFileName, 'clip.mp4');
  });
}
