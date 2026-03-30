import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trace/core/utils/useful_extension.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.name,
    required this.colorValue,
    this.avatarPath,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 0,
    super.key,
  });

  final String name;
  final int colorValue;
  final String? avatarPath;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarPath = avatarPath?.trim();
    final avatarFile = resolvedAvatarPath == null || resolvedAvatarPath.isEmpty
        ? null
        : File(resolvedAvatarPath);
    final hasImage = !kIsWeb && avatarFile != null && avatarFile.existsSync();
    final initials = _initialsOf(name);

    return Semantics(
      label: name,
      image: hasImage,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: borderWidth > 0
              ? Border.all(
                  color: borderColor ?? Colors.transparent,
                  width: borderWidth,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? _buildAvatarImage(
                context: context,
                avatarFile: avatarFile,
                initials: initials,
              )
            : Center(
                child: Text(
                  initials,
                  style: context.tt.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarImage({
    required BuildContext context,
    required File? avatarFile,
    required String initials,
  }) {
    if (avatarFile == null) {
      return Center(
        child: Text(
          initials,
          style: context.tt.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Image.file(
      avatarFile,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Text(
            initials,
            style: context.tt.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

String _initialsOf(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return '?';
  }

  final parts = trimmedName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }

  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
