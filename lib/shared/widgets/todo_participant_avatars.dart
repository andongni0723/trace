import 'package:flutter/material.dart';
import 'package:people_todolist/core/database/database.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';

class TodoParticipantAvatars extends StatelessWidget {
  const TodoParticipantAvatars({
    required this.people,
    this.maxVisible = 3,
    super.key,
  });

  final List<PeopleData> people;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const SizedBox.shrink();
    }

    final visiblePeople = people.take(maxVisible).toList(growable: false);
    final overflowCount = people.length - visiblePeople.length;

    return SizedBox(
      width: 28.0 + ((visiblePeople.length - 1) * 18.0) + (overflowCount > 0 ? 28.0 : 0),
      height: 28,
      child: Stack(
        children: [
          for (var index = 0; index < visiblePeople.length; index++)
            Positioned(
              left: index * 18.0,
              child: _AvatarBadge(person: visiblePeople[index]),
            ),
          if (overflowCount > 0)
            Positioned(
              left: visiblePeople.length * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: context.cs.surfaceContainerHighest,
                child: Text(
                  '+$overflowCount',
                  style: context.tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.person});

  final PeopleData person;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Color(person.colorValue),
      child: Text(
        _initialsOf(person.name),
        style: context.tt.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }

  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

