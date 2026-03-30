import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/features/people/providers/person_detail_provider.dart';
import 'package:trace/features/people/providers/people_database_providers.dart';

import '../../people/test_person_avatar_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('PersonDetailActions', () {
    test(
      'updates and deletes managed avatars with the person record',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final avatarStorage = TestPersonAvatarStorage();
        addTearDown(avatarStorage.clearManagedAvatars);

        final originalAvatarFile = File(
          '${Directory.systemTemp.path}/trace_person_avatar_original.png',
        );
        await originalAvatarFile.writeAsBytes([1, 2, 3], flush: true);
        addTearDown(originalAvatarFile.delete);

        final updatedAvatarFile = File(
          '${Directory.systemTemp.path}/trace_person_avatar_updated.png',
        );
        await updatedAvatarFile.writeAsBytes([4, 5, 6], flush: true);
        addTearDown(updatedAvatarFile.delete);

        final storedAvatarPath = await avatarStorage.persistAvatar(
          personId: 'owner',
          sourcePath: originalAvatarFile.path,
        );
        expect(storedAvatarPath, isNotNull);

        await database.peopleDao.createPerson(
          id: 'owner',
          name: 'Owner',
          colorValue: 0xFF111111,
          avatarPath: storedAvatarPath,
        );

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            personAvatarStorageProvider.overrideWithValue(avatarStorage),
          ],
        );
        addTearDown(container.dispose);

        final originalPerson = await database.peopleDao.getPersonById('owner');
        expect(originalPerson, isNotNull);

        await container
            .read(personDetailActionsProvider)
            .updatePersonProfile(
              person: originalPerson!,
              name: 'Owner Updated',
              avatarPath: updatedAvatarFile.path,
            );

        final updatedPerson = await database.peopleDao.getPersonById('owner');
        expect(updatedPerson, isNotNull);
        expect(updatedPerson!.name, 'Owner Updated');
        expect(updatedPerson.avatarPath, isNotNull);
        expect(await File(updatedPerson.avatarPath!).readAsBytes(), [4, 5, 6]);
        expect(await File(storedAvatarPath!).exists(), isFalse);

        await container.read(personDetailActionsProvider).deletePerson('owner');

        expect(await database.peopleDao.getPersonById('owner'), isNull);
        expect(await File(updatedPerson.avatarPath!).exists(), isFalse);
      },
    );
  });
}
