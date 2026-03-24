import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';

class PersonNoteCard extends StatelessWidget {
  const PersonNoteCard({
    required this.isExpanded,
    required this.note,
    required this.onToggle,
    super.key,
  });

  final bool isExpanded;
  final String note;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasNote = note.trim().isNotEmpty;

    return Card(
      elevation: 0,
      color: context.cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    color: context.cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'personTodo.noteTitle'.tr(),
                      style: context.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
              AnimatedCrossFade(
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                // sizeCurve: Curves.easeInOut,
                sizeCurve: Curves.easeInOutCirc,

                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    hasNote ? note : 'personTodo.noteEmpty'.tr(),
                    style: context.tt.bodyMedium?.copyWith(
                      color: hasNote
                          ? context.cs.onSurface
                          : context.cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

