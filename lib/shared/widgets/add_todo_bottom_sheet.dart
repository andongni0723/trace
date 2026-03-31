import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trace/core/database/database.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/data/models/todo_with_people.dart';
import 'package:trace/features/people/providers/person_detail_provider.dart';
import 'package:trace/features/people/providers/people_provider.dart';
import 'package:trace/shared/widgets/bottom_sheet_keyboard_inset.dart';
import 'package:trace/shared/widgets/person_avatar.dart';
import 'package:trace/shared/widgets/todo_people_picker_sheet.dart';

class AddTodoBottomSheet extends ConsumerStatefulWidget {
  const AddTodoBottomSheet({
    required this.personId,
    this.initialTodo,
    super.key,
  });

  final String personId;
  final TodoWithPeople? initialTodo;

  @override
  ConsumerState<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends ConsumerState<AddTodoBottomSheet>
    with LateInitMixin<AddTodoBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final FocusNode _titleFocusNode;

  late bool _showNoteField;
  late bool _isStarred;
  bool _isSaving = false;
  DateTime? _dueAt;
  late Set<String> _selectedParticipantIds;

  bool get _isEditing => widget.initialTodo != null;

  @override
  void initState() {
    super.initState();
    final initialTodo = widget.initialTodo?.todo;
    _titleController = TextEditingController(text: initialTodo?.title ?? '');
    _noteController = TextEditingController(text: initialTodo?.note ?? '');
    _titleFocusNode = FocusNode();
    _showNoteField = (initialTodo?.note?.trim().isNotEmpty ?? false);
    _isStarred = initialTodo?.starred ?? false;
    _dueAt = initialTodo?.dueAt;
    _selectedParticipantIds = {
      ...?widget.initialTodo?.relatedPeople.map((person) => person.id),
    };

  }

  @override
  void lateInitState() {
    if (!_isEditing) {
      _titleFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _titleController.text.trim().isNotEmpty && !_isSaving;
    final peopleAsync = ref.watch(peopleProvider);

    return BottomSheetKeyboardInset(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'personTodo.addTodo.titleHint'.tr(),
                border: InputBorder.none,
              ),
              style: context.tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedParticipantIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              peopleAsync.when(
                data: (people) {
                  final selectedPeople = people
                      .where(
                        (person) => _selectedParticipantIds.contains(person.id),
                      )
                      .toList(growable: false);

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedPeople
                        .map((person) {
                          return InputChip(
                            label: Text(person.name),
                            avatar: PersonAvatar(
                              name: person.name,
                              colorValue: person.colorValue,
                              avatarPath: person.avatarPath,
                              size: 24,
                            ),
                            onDeleted: () {
                              AppHaptics.selection();
                              setState(() {
                                _selectedParticipantIds.remove(person.id);
                              });
                            },
                          );
                        })
                        .toList(growable: false),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            if (_showNoteField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                style: context.tt.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'personTodo.addTodo.noteHint'.tr(),
                  border: InputBorder.none,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    AppHaptics.selection();
                    setState(() {
                      _showNoteField = !_showNoteField;
                    });
                  },
                  icon: Icon(
                    _showNoteField ? Icons.notes_rounded : Icons.notes_outlined,
                  ),
                ),
                IconButton(
                  onPressed: peopleAsync.hasValue
                      ? () {
                          AppHaptics.primaryAction();
                          _openPeoplePicker(peopleAsync.value!);
                        }
                      : null,
                  icon: Icon(
                    _selectedParticipantIds.isNotEmpty
                        ? Icons.group_rounded
                        : Icons.group_outlined,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.primaryAction();
                    _pickDueDateTime();
                  },
                  icon: Icon(
                    _dueAt == null
                        ? Icons.schedule_outlined
                        : Icons.schedule_rounded,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.selection();
                    setState(() {
                      _isStarred = !_isStarred;
                    });
                  },
                  icon: Icon(
                    _isStarred
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _isStarred
                        ? context.cs.primary
                        : context.cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: canSave ? _saveTodo : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing
                              ? 'personTodo.addTodo.update'.tr()
                              : 'personTodo.addTodo.save'.tr(),
                        ),
                ),
              ],
            ),
            if (_dueAt != null) ...[
              const SizedBox(height: 8),
              InputChip(
                avatar: Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: context.cs.onSecondaryContainer,
                ),
                label: Text(
                  DateFormat.yMMMd().add_jm().format(_dueAt!),
                  style: context.tt.labelLarge?.copyWith(
                    color: context.cs.onSurface,
                  ),
                ),
                backgroundColor: Colors.transparent,
                shape: StadiumBorder(
                  side: BorderSide(color: context.cs.outline),
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.cs.onSurfaceVariant,
                ),
                onDeleted: () {
                  AppHaptics.selection();
                  setState(() {
                    _dueAt = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initialDate = _dueAt ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _dueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveTodo() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final note = _noteController.text;

      if (_isEditing) {
        await ref
            .read(personTodoActionsProvider)
            .updateTodo(
              todoId: widget.initialTodo!.todo.id,
              title: _titleController.text,
              note: note,
              dueAt: _dueAt,
              starred: _isStarred,
              participantPersonIds: _selectedParticipantIds.toList(
                growable: false,
              ),
            );
      } else {
        await ref
            .read(personTodoActionsProvider)
            .createTodo(
              personId: widget.personId,
              title: _titleController.text,
              note: note,
              dueAt: _dueAt,
              starred: _isStarred,
              participantPersonIds: _selectedParticipantIds.toList(
                growable: false,
              ),
            );
      }

      if (mounted) {
        AppHaptics.confirm();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openPeoplePicker(List<PeopleData> people) async {
    final selectedIds = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.cs.surface,
      builder: (_) => TodoPeoplePickerSheet(
        people: people
            .where((person) => person.id != widget.personId)
            .toList(growable: false),
        initialSelectedIds: _selectedParticipantIds,
      ),
    );

    if (selectedIds == null) {
      return;
    }

    setState(() {
      _selectedParticipantIds = selectedIds.toSet();
    });
  }
}
