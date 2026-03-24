import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
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
  return ref.watch(todosDaoProvider).watchTodosForPerson(personId).map(
        (todos) => todos.where((todo) => !todo.done).length,
      );
});

final peopleActionsProvider = Provider<PeopleActions>((ref) {
  return PeopleActions(
    ref: ref,
    uuid: const Uuid(),
  );
});

class PeopleActions {
  PeopleActions({
    required Ref ref,
    required Uuid uuid,
  })  : _ref = ref,
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
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    await _ref.read(peopleDaoProvider).insertPerson(
          id: _uuid.v4(),
          name: trimmedName,
          colorValue: avatarColor.toARGB32(),
        );
  }
}
