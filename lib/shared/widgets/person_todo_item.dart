import 'package:flutter/material.dart';
import 'package:trace/core/database/database.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trace/core/utils/app_haptics.dart';
import 'package:trace/core/utils/todo_due_date_formatter.dart';
import 'package:trace/core/utils/useful_extension.dart';
import 'package:trace/features/people/data/models/todo_with_people.dart';
import 'package:trace/shared/widgets/todo_participant_avatars.dart';

class PersonTodoItem extends StatelessWidget {
  const PersonTodoItem({
    required this.todoBundle,
    required this.onToggleDone,
    required this.onToggleStar,
    required this.onPressed,
    this.currentTime,
    super.key,
  });

  final TodoWithPeople todoBundle;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;
  final VoidCallback onPressed;
  final DateTime? currentTime;

  Todo get todo => todoBundle.todo;

  @override
  Widget build(BuildContext context) {
    final dueDatePresentation = todo.dueAt == null
        ? null
        : formatTodoDueDate(
            dueAt: todo.dueAt!,
            now: currentTime ?? DateTime.now(),
            locale: context.locale,
          );
    final dueDateColor = dueDatePresentation?.isOverdue == true
        ? context.cs.error
        : context.cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppHaptics.primaryAction();
          onPressed();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () {
                AppHaptics.selection();
                onToggleDone();
              },
              icon: Icon(
                todo.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: todo.done
                    ? context.cs.primary
                    : context.cs.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: context.tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.done
                            ? context.cs.onSurfaceVariant
                            : context.cs.onSurface,
                      ),
                    ),
                    if (todo.note?.trim().isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          todo.note!,
                          style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (todo.dueAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: dueDateColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dueDatePresentation!.label,
                              style: context.tt.labelMedium?.copyWith(
                                color: dueDateColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (todoBundle.relatedPeople.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TodoParticipantAvatars(
                        people: todoBundle.relatedPeople,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      AppHaptics.selection();
                      onToggleStar();
                    },
                    icon: Icon(
                      todo.starred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: todo.starred
                          ? context.cs.primary
                          : context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
