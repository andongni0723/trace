import 'package:flutter/material.dart';

import '../../../../core/utils/useful_extension.dart';

class ArrayElementTypeTag extends StatelessWidget {
  const ArrayElementTypeTag({
    required this.label,
    this.onTap,
    this.tagKey,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final Key? tagKey;

  @override
  Widget build(BuildContext context) {
    final child = ClipPath(
      clipper: const _DiamondSideTagClipper(),
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.cs.tertiaryContainer),
        child: Padding(
          key: tagKey,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.tt.labelMedium?.copyWith(
              color: context.cs.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _DiamondSideTagClipper extends CustomClipper<Path> {
  const _DiamondSideTagClipper();

  static const _pointWidth = 8.0;

  @override
  Path getClip(Size size) {
    final pointWidth = _pointWidth.clamp(0.0, size.width / 2).toDouble();
    return Path()
      ..moveTo(pointWidth, 0)
      ..lineTo(size.width - pointWidth, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - pointWidth, size.height)
      ..lineTo(pointWidth, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant _DiamondSideTagClipper oldClipper) => false;
}
