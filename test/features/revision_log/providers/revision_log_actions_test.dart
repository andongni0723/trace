import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/media_library/data/models/media_asset_kind.dart';
import 'package:trace/features/media_library/data/models/media_import_candidate.dart';
import 'package:trace/features/media_library/data/services/media_asset_picker.dart';
import 'package:trace/features/media_library/providers/media_library_providers.dart';
import 'package:trace/features/people/data/models/personal_database_value_type.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/features/people/providers/person_detail_provider.dart';
import 'package:trace/features/people/providers/personal_database_provider.dart';
import 'package:trace/features/revision_log/data/models/revision_log_action.dart';

import '../../media_library/test_media_asset_storage.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('revision log actions', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('records people create, update, and delete actions', () async {
      await container
          .read(peopleActionsProvider)
          .insertPerson(name: 'Maya', avatarColor: Colors.indigo);

      final person = (await database.peopleDao.getPeople()).single;

      await container
          .read(personDetailActionsProvider)
          .updatePersonProfile(person: person, name: 'Maya Chen');
      await container.read(personDetailActionsProvider).deletePerson(person.id);

      final logs = await database.revisionLogsDao.getRecentLogs();

      expect(logs.map((log) => log.action), [
        RevisionLogAction.delete,
        RevisionLogAction.update,
        RevisionLogAction.create,
      ]);
      expect(logs.map((log) => log.entityType).toSet(), {'person'});
      expect(logs.first.entityLabel, 'Maya Chen');
      expect(logs.last.afterJson, contains('Maya'));
    });

    test('records todo create, update, and toggle actions', () async {
      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );

      await container
          .read(personTodoActionsProvider)
          .createTodo(personId: 'owner', title: 'Plan trip');
      final todo = (await database.todosDao.getTodosForPerson('owner')).single;

      await container
          .read(personTodoActionsProvider)
          .updateTodo(todoId: todo.id, title: 'Plan group trip', starred: true);
      await container
          .read(personTodoActionsProvider)
          .toggleTodoDone(todoId: todo.id, done: true);

      final logs = await database.revisionLogsDao.getRecentLogs();

      expect(logs.map((log) => log.action), [
        RevisionLogAction.update,
        RevisionLogAction.update,
        RevisionLogAction.create,
      ]);
      expect(logs.map((log) => log.entityType).toSet(), {'todo'});
      expect(logs.first.changedFieldsJson, contains('done'));
      expect(logs.last.summary, contains('Plan trip'));
    });

    test('records person notes and personal database changes', () async {
      await database.peopleDao.createPerson(
        id: 'owner',
        name: 'Owner',
        colorValue: 0xFF111111,
      );

      await container
          .read(personDetailActionsProvider)
          .updatePersonNote(personId: 'owner', content: 'Coffee preference');
      await container
          .read(personalDatabaseActionsProvider)
          .createField(
            actorPersonId: 'owner',
            key: 'nickname',
            type: PersonalDatabaseValueType.string,
            isPublic: false,
            value: 'Cap',
          );
      final field = (await database.personalDatabaseDao.getFieldTreeForPerson(
        'owner',
      )).single;
      await container
          .read(personalDatabaseActionsProvider)
          .updateFieldValue(personId: 'owner', field: field, value: 'Captain');

      final logs = await database.revisionLogsDao.getRecentLogs();

      expect(logs.map((log) => log.entityType), [
        'personalDatabaseValue',
        'personalDatabaseField',
        'personNote',
      ]);
      expect(logs.first.afterJson, contains('Captain'));
      expect(logs.last.summary, contains('note'));
    });
  });

  test('records media library import, rename, and delete actions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final storage = TestMediaAssetStorage();
    addTearDown(storage.clearManagedMediaFiles);

    final sourceFile = File(
      '${Directory.systemTemp.path}/trace_revision_log_media.mp4',
    );
    await sourceFile.writeAsBytes([1, 2, 3, 4], flush: true);
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

    final imported = await container
        .read(mediaLibraryActionsProvider)
        .importMediaFiles(mode: MediaAssetPickerMode.video);
    final asset = imported.single;

    await container
        .read(mediaLibraryActionsProvider)
        .renameMediaAsset(assetId: asset.id, displayName: 'Trip clip');
    await container
        .read(mediaLibraryActionsProvider)
        .deleteMediaAsset(asset.id);

    final logs = await database.revisionLogsDao.getRecentLogs();

    expect(logs.map((log) => log.action), [
      RevisionLogAction.delete,
      RevisionLogAction.update,
      RevisionLogAction.create,
    ]);
    expect(logs.map((log) => log.entityType).toSet(), {'mediaAsset'});
    expect(logs.first.beforeJson, contains('Trip clip'));
  });
}
