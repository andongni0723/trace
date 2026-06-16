import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../revision_log/data/models/revision_log_action.dart';
import '../../revision_log/providers/revision_log_provider.dart';
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

final personNoteProvider = StreamProvider.family<PersonNote?, String>((
  ref,
  personId,
) {
  return ref.watch(personNotesDaoProvider).watchNoteForPerson(personId);
});

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

    final updatedPerson = await _ref
        .read(peopleDaoProvider)
        .getPersonById(person.id);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.update,
          entityType: 'person',
          entityId: person.id,
          entityLabel: updatedPerson?.name ?? trimmedName,
          summary: 'Updated person ${updatedPerson?.name ?? trimmedName}',
          changedFields: [
            if (hasNameChanged) 'name',
            if (hasAvatarChanged) 'avatarPath',
          ],
          before: person.toJson(),
          after: updatedPerson?.toJson(),
        );
  }

  Future<void> deletePerson(String personId) async {
    final person = await _ref.read(peopleDaoProvider).getPersonById(personId);
    await _ref
        .read(personAvatarStorageProvider)
        .deleteManagedAvatar(person?.avatarPath);
    await _ref.read(peopleDaoProvider).deletePersonById(personId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.delete,
          entityType: 'person',
          entityId: personId,
          entityLabel: person?.name,
          summary: 'Deleted person ${person?.name ?? personId}',
          changedFields: const ['person'],
          before: person?.toJson(),
        );
  }

  Future<void> updatePersonNote({
    required String personId,
    required String content,
  }) async {
    final notesDao = _ref.read(personNotesDaoProvider);
    final before = await notesDao.getNoteForPerson(personId);
    await notesDao.upsertNote(personId: personId, content: content);
    final after = await notesDao.getNoteForPerson(personId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: before == null
              ? RevisionLogAction.create
              : RevisionLogAction.update,
          entityType: 'personNote',
          entityId: personId,
          entityLabel: personId,
          summary: 'Updated person note',
          changedFields: const ['content'],
          before: before?.toJson(),
          after: after?.toJson(),
        );
  }
}

class PersonTodoActions {
  PersonTodoActions({required Ref ref, required Uuid uuid})
    : _ref = ref,
      _uuid = uuid;

  final Ref _ref;
  final Uuid _uuid;

  Future<void> toggleTodoDone({
    required String todoId,
    required bool done,
  }) async {
    final todosDao = _ref.read(todosDaoProvider);
    final before = await todosDao.getTodoById(todoId);
    await todosDao.setTodoDone(todoId: todoId, done: done);
    final after = await todosDao.getTodoById(todoId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.update,
          entityType: 'todo',
          entityId: todoId,
          entityLabel: after?.title ?? before?.title ?? todoId,
          summary: 'Updated todo ${after?.title ?? before?.title ?? todoId}',
          changedFields: const ['done'],
          before: before?.toJson(),
          after: after?.toJson(),
        );
  }

  Future<void> toggleTodoStarred({
    required String todoId,
    required bool starred,
  }) async {
    final todosDao = _ref.read(todosDaoProvider);
    final before = await todosDao.getTodoById(todoId);
    await todosDao.setTodoStarred(todoId: todoId, starred: starred);
    final after = await todosDao.getTodoById(todoId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.update,
          entityType: 'todo',
          entityId: todoId,
          entityLabel: after?.title ?? before?.title ?? todoId,
          summary: 'Updated todo ${after?.title ?? before?.title ?? todoId}',
          changedFields: const ['starred'],
          before: before?.toJson(),
          after: after?.toJson(),
        );
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

    final todoId = _uuid.v4();
    await _ref
        .read(todosDaoProvider)
        .createTodo(
          id: todoId,
          personId: personId,
          title: trimmedTitle,
          note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
          starred: starred,
          dueAt: dueAt,
          participantPersonIds: participantPersonIds,
        );
    final todo = await _ref.read(todosDaoProvider).getTodoById(todoId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.create,
          entityType: 'todo',
          entityId: todoId,
          entityLabel: trimmedTitle,
          summary: 'Created todo $trimmedTitle',
          changedFields: const [
            'title',
            'note',
            'dueAt',
            'starred',
            'participantPersonIds',
          ],
          after: todo?.toJson(),
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

    final todosDao = _ref.read(todosDaoProvider);
    final before = await todosDao.getTodoById(todoId);
    await todosDao.updateTodo(
      id: todoId,
      title: trimmedTitle,
      note: Value(
        trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      ),
      starred: starred,
      dueAt: Value(dueAt),
      participantPersonIds: participantPersonIds,
    );
    final after = await todosDao.getTodoById(todoId);
    await _ref
        .read(revisionLogActionsProvider)
        .record(
          action: RevisionLogAction.update,
          entityType: 'todo',
          entityId: todoId,
          entityLabel: after?.title ?? trimmedTitle,
          summary: 'Updated todo ${after?.title ?? trimmedTitle}',
          changedFields: const [
            'title',
            'note',
            'dueAt',
            'starred',
            'participantPersonIds',
          ],
          before: before?.toJson(),
          after: after?.toJson(),
        );
  }
}
