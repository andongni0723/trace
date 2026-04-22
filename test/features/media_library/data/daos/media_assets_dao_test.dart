import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/media_library/data/models/media_asset_kind.dart';

import '../../test_media_asset_storage.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('MediaAssetsDao', () {
    test('supports create, search, rename and delete', () async {
      final sourceFile = File(
        '${Directory.systemTemp.path}/trace_media_source_photo.png',
      );
      await sourceFile.writeAsBytes([1, 2, 3, 4], flush: true);
      addTearDown(sourceFile.delete);

      final storage = TestMediaAssetStorage();
      addTearDown(storage.clearManagedMediaFiles);
      final storedPath = await storage.persistMediaFile(
        mediaAssetId: 'asset-1',
        sourcePath: sourceFile.path,
      );

      expect(storedPath, isNotNull);

      await database.mediaAssetsDao.insertMediaAsset(
        id: 'asset-1',
        displayName: 'Vacation photo',
        originalFileName: 'photo.png',
        kind: MediaAssetKind.image,
        sizeBytes: 4,
        filePath: storedPath!,
        mimeType: 'image/png',
      );
      await database.mediaAssetsDao.insertMediaAsset(
        id: 'asset-2',
        displayName: 'Voice memo',
        originalFileName: 'memo.m4a',
        kind: MediaAssetKind.audio,
        sizeBytes: 8,
        filePath: '/tmp/memo.m4a',
        mimeType: 'audio/mp4',
      );

      final searchResult = await database.mediaAssetsDao.getMediaAssets(
        query: 'vacation',
      );
      expect(searchResult, hasLength(1));
      expect(searchResult.single.id, 'asset-1');

      final filteredResult = await database.mediaAssetsDao.getMediaAssets(
        kind: MediaAssetKind.audio,
      );
      expect(filteredResult, hasLength(1));
      expect(filteredResult.single.id, 'asset-2');

      final renamedRows = await database.mediaAssetsDao.renameMediaAsset(
        id: 'asset-1',
        displayName: 'Family trip photo',
      );
      expect(renamedRows, 1);

      final renamedAsset = await database.mediaAssetsDao.getMediaAssetById(
        'asset-1',
      );
      expect(renamedAsset, isNotNull);
      expect(renamedAsset!.displayName, 'Family trip photo');

      final deletedRows = await database.mediaAssetsDao.deleteMediaAssetById(
        'asset-2',
      );
      expect(deletedRows, 1);
      expect(
        await database.mediaAssetsDao.getMediaAssetById('asset-2'),
        isNull,
      );
    });
  });
}
