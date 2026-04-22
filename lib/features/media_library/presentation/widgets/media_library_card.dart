import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/useful_extension.dart';
import '../../data/models/media_asset_kind.dart';
import '../../data/services/media_asset_thumbnailer.dart';
import '../models/media_library_view_data.dart';

class MediaLibraryCard extends StatelessWidget {
  const MediaLibraryCard({
    required this.item,
    this.onTap,
    this.onRenameTap,
    super.key,
  });

  final MediaLibraryItemViewData item;
  final VoidCallback? onTap;
  final VoidCallback? onRenameTap;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: context.cs.surfaceContainerHigh,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MediaPreviewFrame(item: item),
              Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onRenameTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          item.sizeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onRenameTap != null)
                    IconButton(
                      onPressed: onRenameTap,
                      tooltip: 'mediaLibrary.card.renameTooltip'.tr(),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewFrame extends StatelessWidget {
  const _MediaPreviewFrame({required this.item});

  final MediaLibraryItemViewData item;

  @override
  Widget build(BuildContext context) {
    final accentColor = _defaultAccentColor(context, item);
    final previewPath = item.previewPath?.trim();
    final previewFile = previewPath == null || previewPath.isEmpty
        ? null
        : File(previewPath);
    final hasPreviewImage =
        !kIsWeb && previewFile != null && previewFile.existsSync();

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    context.cs.surfaceContainerHighest,
                  ],
                ),
              ),
            ),
            if (item.kind == MediaAssetKind.video && previewPath != null)
              _VideoThumbnailPreview(
                videoPath: previewPath,
                fallbackBuilder: () =>
                    _buildFallbackPreview(context, accentColor),
              )
            else if (previewFile == null || !hasPreviewImage)
              _buildFallbackPreview(context, accentColor)
            else
              Image.file(
                previewFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackPreview(context, accentColor);
                },
              ),
            Positioned(
              left: 10,
              top: 10,
              child: _MediaKindChip(kind: item.kind),
            ),
            if (item.kind == MediaAssetKind.video)
              const Center(child: _VideoPlayIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPreview(BuildContext context, Color accentColor) {
    final icon = switch (item.kind) {
      MediaAssetKind.image => Icons.image_outlined,
      MediaAssetKind.video => Icons.play_circle_outline_rounded,
      MediaAssetKind.audio => Icons.graphic_eq_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.82),
            accentColor.withValues(alpha: 0.60),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 52,
          color: Colors.white.withValues(alpha: 0.96),
        ),
      ),
    );
  }

  Color _defaultAccentColor(
    BuildContext context,
    MediaLibraryItemViewData item,
  ) {
    return switch (item.kind) {
      MediaAssetKind.image => context.cs.primaryContainer,
      MediaAssetKind.video => context.cs.secondaryContainer,
      MediaAssetKind.audio => context.cs.tertiaryContainer,
    };
  }
}

class _VideoThumbnailPreview extends StatelessWidget {
  const _VideoThumbnailPreview({
    required this.videoPath,
    required this.fallbackBuilder,
  });

  final String videoPath;
  final Widget Function() fallbackBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: const MediaAssetThumbnailer().thumbnailForVideo(videoPath),
      builder: (context, snapshot) {
        final thumbnailPath = snapshot.data?.trim();
        final thumbnailFile = thumbnailPath == null || thumbnailPath.isEmpty
            ? null
            : File(thumbnailPath);
        final hasThumbnail =
            !kIsWeb && thumbnailFile != null && thumbnailFile.existsSync();

        if (!hasThumbnail) {
          return fallbackBuilder();
        }

        return Image.file(
          thumbnailFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallbackBuilder();
          },
        );
      },
    );
  }
}

class _VideoPlayIndicator extends StatelessWidget {
  const _VideoPlayIndicator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white.withValues(alpha: 0.96),
          size: 34,
        ),
      ),
    );
  }
}

class _MediaKindChip extends StatelessWidget {
  const _MediaKindChip({required this.kind});

  final MediaAssetKind kind;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          switch (kind) {
            MediaAssetKind.image => 'mediaLibrary.kind.image'.tr(),
            MediaAssetKind.video => 'mediaLibrary.kind.video'.tr(),
            MediaAssetKind.audio => 'mediaLibrary.kind.audio'.tr(),
          },
          style: context.tt.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
