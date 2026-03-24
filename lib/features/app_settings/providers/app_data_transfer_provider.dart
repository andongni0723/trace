import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database.dart';
import '../../people/providers/people_database_providers.dart';
import '../data/models/app_settings.dart';
import 'app_settings_provider.dart';

final appDataTransferProvider = Provider<AppDataTransferService>((ref) {
  return AppDataTransferService(ref);
});

const _backupAppId = 'people_todolist';
const _backupType = 'app_backup';
const _backupVersion = 1;

class AppDataTransferService {
  AppDataTransferService(this._ref);

  final Ref _ref;

  Future<bool> exportData() async {
    final database = _ref.read(appDatabaseProvider);
    final appSettings = await _readCurrentSettings();

    final people = await database.select(database.people).get();
    final todos = await database.select(database.todos).get();
    final participants = await database.select(database.todoParticipants).get();

    final payload = <String, Object?>{
      'appId': _backupAppId,
      'backupType': _backupType,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'themeMode': appSettings.themeMode.name,
      },
      'people': people.map((person) => person.toJson()).toList(growable: false),
      'todos': todos.map((todo) => todo.toJson()).toList(growable: false),
      'todoParticipants': participants
          .map((participant) => participant.toJson())
          .toList(growable: false),
    };

    final fileName =
        'people_todolist_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      return savedPath != null;
    } catch (_) {
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          title: 'people_todolist backup',
        ),
      );

      return true;
    }
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    final rawJson = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    _validateBackupPayload(rawJson);

    final peopleJson = (rawJson['people'] as List<dynamic>? ?? const []);
    final todosJson = (rawJson['todos'] as List<dynamic>? ?? const []);
    final participantsJson =
        (rawJson['todoParticipants'] as List<dynamic>? ?? const []);
    final settingsJson = rawJson['settings'] as Map<String, dynamic>?;

    final people = peopleJson
        .map(
          (item) => PeopleData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    final todos = todosJson
        .map(
          (item) => Todo.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    final participants = participantsJson
        .map(
          (item) => TodoParticipant.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);

    final database = _ref.read(appDatabaseProvider);
    await database.transaction(() async {
      await database.delete(database.todoParticipants).go();
      await database.delete(database.todos).go();
      await database.delete(database.people).go();

      await database.batch((batch) {
        if (people.isNotEmpty) {
          batch.insertAll(database.people, people);
        }
        if (todos.isNotEmpty) {
          batch.insertAll(database.todos, todos);
        }
        if (participants.isNotEmpty) {
          batch.insertAll(database.todoParticipants, participants);
        }
      });
    });

    final importedThemeMode = AppThemeModePreferenceX.fromPreference(
      settingsJson?['themeMode'] as String?,
    );
    await _ref.read(appSettingsActionsProvider).setThemeMode(importedThemeMode);

    return true;
  }

  Future<AppSettings> _readCurrentSettings() async {
    try {
      return await _ref.read(appSettingsProvider.future);
    } catch (_) {
      return const AppSettings();
    }
  }

  void _validateBackupPayload(Map<String, dynamic> rawJson) {
    final appId = rawJson['appId'];
    final backupType = rawJson['backupType'];
    final version = rawJson['version'];

    final hasRequiredStructure =
        rawJson['settings'] is Map<String, dynamic> &&
        rawJson['people'] is List<dynamic> &&
        rawJson['todos'] is List<dynamic> &&
        rawJson['todoParticipants'] is List<dynamic>;

    if (appId != _backupAppId ||
        backupType != _backupType ||
        version != _backupVersion ||
        !hasRequiredStructure) {
      throw const FormatException('Invalid people_todolist backup format.');
    }
  }
}
