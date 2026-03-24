import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:people_todolist/core/database/database.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';

class TodoPeoplePickerSheet extends StatefulWidget {
  const TodoPeoplePickerSheet({
    required this.people,
    required this.initialSelectedIds,
    super.key,
  });

  final List<PeopleData> people;
  final Set<String> initialSelectedIds;

  @override
  State<TodoPeoplePickerSheet> createState() => _TodoPeoplePickerSheetState();
}

class _TodoPeoplePickerSheetState extends State<TodoPeoplePickerSheet> {
  late final Set<String> _selectedIds = {...widget.initialSelectedIds};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'personTodo.peoplePicker.title'.tr(),
                    style: context.tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedIds.toList(growable: false));
                  },
                  child: Text('personTodo.peoplePicker.done'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.people.length,
                itemBuilder: (context, index) {
                  final person = widget.people[index];
                  final isSelected = _selectedIds.contains(person.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(person.id);
                        } else {
                          _selectedIds.add(person.id);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    secondary: CircleAvatar(
                      backgroundColor: Color(person.colorValue),
                      child: Text(
                        _initialsOf(person.name),
                        style: context.tt.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(person.name),
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
            ),
          ],
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

