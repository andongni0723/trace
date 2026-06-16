import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/models/revision_log_view_data.dart';

class RevisionLogDetailSheet extends StatelessWidget {
  const RevisionLogDetailSheet({
    required this.log,
    required this.fullTimeLabel,
    super.key,
  });

  final RevisionLogViewData log;
  final String fullTimeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      'revisionLog.details.title'.tr(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'revisionLog.details.closeTooltip'.tr(),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailValue(
                label: 'revisionLog.details.time'.tr(),
                value: fullTimeLabel,
              ),
              _DetailValue(
                label: 'revisionLog.details.entity'.tr(),
                value: '${log.entityType} / ${log.entityLabel ?? log.entityId}',
              ),
              _DetailValue(
                label: 'revisionLog.details.action'.tr(),
                value: 'revisionLog.actions.${log.action}'.tr(),
              ),
              _DetailValue(
                label: 'revisionLog.details.summary'.tr(),
                value: log.summary,
              ),
              _DetailValue(
                label: 'revisionLog.details.changedFields'.tr(),
                value: log.changedFields.isEmpty
                    ? '[]'
                    : log.changedFields.join(', '),
              ),
              Divider(height: 32, color: colorScheme.outlineVariant),
              if (log.beforeJson != null)
                _JsonBlock(
                  label: 'revisionLog.details.before'.tr(),
                  value: log.beforeJson!,
                ),
              if (log.afterJson != null)
                _JsonBlock(
                  label: 'revisionLog.details.after'.tr(),
                  value: log.afterJson!,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SelectableText(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
