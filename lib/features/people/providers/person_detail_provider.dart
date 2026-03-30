import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../data/models/todo_with_people.dart';
import 'people_database_providers.dart';

final personProvider = StreamProvider.family<PeopleData?, String>((
  ref,
  personId,
) {
  return ref.watch(peopleDaoProvider).watchPersonById(personId);
});

final personTodosProvider = StreamProvider.family<List<TodoWithPeople>, String>(
  (ref, personId) {
    return ref.watch(todosDaoProvider).watchTodosWithPeopleForPerson(personId);
  },
);

final personDetailActionsProvider = Provider<PersonDetailActions>((ref) {
  return PersonDetailActions(ref: ref);
});

final personTodoActionsProvider = Provider<PersonTodoActions>((ref) {
  return PersonTodoActions(ref: ref, uuid: const Uuid());
});

class PersonDetailActions {
  PersonDetailActions({required Ref ref}) : _ref = ref;

  final Ref _ref;

  Future<void> updatePersonProfile({
    required PeopleData person,
    required String name,
    String? avatarPath,
  }) async {
    final trimmedName = name.trim();
    final trimmedAvatarPath = avatarPath?.trim();
    final currentAvatarPath = person.avatarPath?.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final hasNameChanged = trimmedName != person.name;
    final hasAvatarChanged = trimmedAvatarPath != currentAvatarPath;
    if (!hasNameChanged && !hasAvatarChanged) {
      return;
    }

    final avatarStorage = _ref.read(personAvatarStorageProvider);
    String? storedAvatarPath = currentAvatarPath;

    if (hasAvatarChanged) {
      storedAvatarPath = await avatarStorage.persistAvatar(
        personId: person.id,
        sourcePath: trimmedAvatarPath,
      );
      await avatarStorage.deleteManagedAvatar(currentAvatarPath);
    }

    await _ref
        .read(peopleDaoProvider)
        .updatePerson(
          id: person.id,
          name: trimmedName,
          colorValue: person.colorValue,
          avatarPath: Value(storedAvatarPath),
        );
  }

  Future<void> deletePerson(String personId) async {
    final person = await _ref.read(peopleDaoProvider).getPersonById(personId);
    await _ref
        .read(personAvatarStorageProvider)
        .deleteManagedAvatar(person?.avatarPath);
    await _ref.read(peopleDaoProvider).deletePersonById(personId);
  }
}

class PersonTodoActions {
  PersonTodoActions({required Ref ref, required Uuid uuid})
    : _ref = ref,
      _uuid = uuid;

  final Ref _ref;
  final Uuid _uuid;

  Future<void> toggleTodoDone({required String todoId, required bool done}) {
    return _ref.read(todosDaoProvider).setTodoDone(todoId: todoId, done: done);
  }

  Future<void> toggleTodoStarred({
    required String todoId,
    required bool starred,
  }) {
    return _ref
        .read(todosDaoProvider)
        .setTodoStarred(todoId: todoId, starred: starred);
  }

  Future<void> createTodo({
    required String personId,
    required String title,
    String? note,
    DateTime? dueAt,
    bool starred = false,
    List<String> participantPersonIds = const [],
  }) async {
    final trimmedTitle = title.trim();
    final trimmedNote = note?.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    await _ref
        .read(todosDaoProvider)
        .createTodo(
          id: _uuid.v4(),
          personId: personId,
          title: trimmedTitle,
          note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
          starred: starred,
          dueAt: dueAt,
          participantPersonIds: participantPersonIds,
        );
  }

  Future<void> updateTodo({
    required String todoId,
    required String title,
    String? note,
    DateTime? dueAt,
    required bool starred,
    List<String> participantPersonIds = const [],
  }) async {
    final trimmedTitle = title.trim();
    final trimmedNote = note?.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    await _ref
        .read(todosDaoProvider)
        .updateTodo(
          id: todoId,
          title: trimmedTitle,
          note: Value(
            trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
          ),
          starred: starred,
          dueAt: Value(dueAt),
          participantPersonIds: participantPersonIds,
        );
  }
}
