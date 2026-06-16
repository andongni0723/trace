import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/revision_log_view_data.dart';

class RevisionLogCard extends StatelessWidget {
  const RevisionLogCard({
    required this.log,
    required this.timeLabel,
    required this.onTap,
    super.key,
  });

  final RevisionLogViewData log;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Color.alphaBlend(
            colorScheme.onSurface.withValues(alpha: 0.10),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHighest;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      'revisionLog.actions.${log.action}'.tr(),
                      style: textTheme.labelLarge?.copyWith(
                        color: _actionColor(colorScheme, log.action),
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    timeLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Text(
                log.summary,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${log.entityType} / ${log.entityLabel ?? log.entityId}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _actionColor(ColorScheme colorScheme, String action) {
    return switch (action) {
      'delete' => colorScheme.error,
      'create' => colorScheme.primary,
      'import' || 'export' => colorScheme.tertiary,
      _ => colorScheme.secondary,
    };
  }
}
