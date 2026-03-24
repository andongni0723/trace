import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:people_todolist/core/utils/useful_extension.dart';
import 'package:people_todolist/features/people/providers/people_provider.dart';

const List<Color> _avatarColors = [
  Color(0xFF5B6CF0),
  Color(0xFF18A999),
  Color(0xFFE67E22),
  Color(0xFFC855BC),
  Color(0xFF00897B),
  Color(0xFFE53935),
  Color(0xFF3949AB),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFF6D4C41),
  Color(0xFF43A047),
  Color(0xFFF9A825),
];

class AddFriendBottomSheet extends ConsumerStatefulWidget {
  const AddFriendBottomSheet({super.key});

  @override
  ConsumerState<AddFriendBottomSheet> createState() =>
      _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends ConsumerState<AddFriendBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = _avatarColors.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canCreate = _nameController.text.trim().isNotEmpty && !_isSubmitting;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'messages.addFriend.title'.tr(),
                    style: context.tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canCreate
                      ? _handleCreatePressed
                      : null,
                  tooltip: 'messages.addFriend.create'.tr(),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {});
              },
              onSubmitted: (_) {
                if (canCreate) {
                  _handleCreatePressed();
                }
              },
              decoration: InputDecoration(
                labelText: 'messages.addFriend.nameLabel'.tr(),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'messages.addFriend.avatarColorLabel'.tr(),
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatarColors.map((color) {
                final isSelected = color == _selectedColor;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? context.cs.onSurface
                              : context.cs.outlineVariant,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.cs.shadow.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreatePressed() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(peopleActionsProvider).insertPerson(
            name: _nameController.text,
            avatarColor: _selectedColor,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
