import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../revision_log/data/models/revision_log_action.dart';
import '../../revision_log/providers/revision_log_provider.dart';
import 'people_database_providers.dart';

const _legacyFakePersonIds = ['alex', 'lina', 'maya', 'sam'];

final peopleStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(peopleActionsProvider).removeLegacyFakePeople();
});

final peopleProvider = StreamProvider<List<PeopleData>>((ref) async* {
  await ref.watch(peopleStartupProvider.future);
  yield* ref.watch(peopleDaoProvider).watchPeople();
});

final personPreviewTodoProvider = StreamProvider.family<Todo?, String>((
  ref,
  personId,
) {
  return ref.watch(todosDaoProvider).watchTodosForPerson(personId).map((todos) {
    for (final todo in todos) {
      if (todo.starred && !todo.done) {
        return todo;
      }
    }

    for (final todo in todos) {
      if (!todo.done) {
        return todo;
      }
    }

    return todos.isEmpty ? null : todos.first;
  });
});

final personOpenTodoCountProvider = StreamProvider.family<int, String>((
  ref,
  personId,
) {
  return ref
      .watch(todosDaoProvider)
      .watchTodosForPerson(personId)
      .map((todos) => todos.where((todo) => !todo.done).length);
});

final peopleActionsProvider = Provider<PeopleActions>((ref) {
  return PeopleActions(ref: ref, uuid: const Uuid());
});

class PeopleActions {
  PeopleActions({required Ref ref, required Uuid uuid})
    : _ref = ref,
      _uuid = uuid;

  final Ref _ref;
  final Uuid _uuid;

  Future<void> removeLegacyFakePeople() async {
    final peopleDao = _ref.read(peopleDaoProvider);

    for (final personId in _legacyFakePersonIds) {
      await peopleDao.deletePersonById(personId);
    }
  }

  Future<void> insertPerson({
    required String name,
    required Color avatarColor,
    String? avatarPath,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final personId = _uuid.v4();
    final storedAvatarPath = await _ref
        .read(personAvatarStorageProvider)
        .persistAvatar(personId: personId, sourcePath: avatarPath);

    await _ref
        .read(peopleDaoProvider)
        .insertPerson(
          id: personId,
          name: trimmedName,
          colorValue: avatarColor.toARGB32(),
          avatarPath: storedAvatarPath,
        );

    final person = await _ref.read(peopleDaoProvider).getPersonById(personId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.create,
          entityType: 'person',
          entityId: personId,
          entityLabel: trimmedName,
          summary: 'Created person $trimmedName',
          changedFields: const ['name', 'colorValue', 'avatarPath'],
          after: person?.toJson(),
        );
  }
}
