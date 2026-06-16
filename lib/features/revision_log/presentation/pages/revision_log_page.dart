import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/revision_log_view_data.dart';
import '../../providers/revision_log_provider.dart';
import '../widgets/revision_log_card.dart';
import '../widgets/revision_log_detail_sheet.dart';

class RevisionLogPage extends ConsumerWidget {
  const RevisionLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(revisionLogProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'revisionLog.closeTooltip'.tr(),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _closePage(context),
        ),
        title: Text('revisionLog.title'.tr()),
        actions: [
          IconButton(
            tooltip: 'revisionLog.clearTooltip'.tr(),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmClearLogs(context, ref),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const _RevisionLogEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemBuilder: (context, index) {
              final log = logs[index];
              return RevisionLogCard(
                log: log,
                timeLabel: DateFormat('HH:mm:ss.SSS').format(log.happenedAt),
                onTap: () => _showLogDetails(context, log),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: logs.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _closePage(BuildContext context) async {
    final didPop = await Navigator.of(context).maybePop();
    if (didPop || !context.mounted) {
      return;
    }

    try {
      GoRouter.of(context).go('/');
    } on Exception {
      // Standalone previews/tests may not have a GoRouter ancestor.
    }
  }

  Future<void> _confirmClearLogs(BuildContext context, WidgetRef ref) async {
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('revisionLog.clearDialog.title'.tr()),
          content: Text('revisionLog.clearDialog.body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('revisionLog.clearDialog.cancel'.tr()),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('revisionLog.clearDialog.confirm'.tr()),
            ),
          ],
        );
      },
    );

    if (didConfirm != true) {
      return;
    }

    await ref.read(revisionLogActionsProvider).clearLogs();
  }

  Future<void> _showLogDetails(BuildContext context, RevisionLogViewData log) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return RevisionLogDetailSheet(
          log: log,
          fullTimeLabel: DateFormat(
            'yyyy-MM-dd HH:mm:ss.SSS',
          ).format(log.happenedAt),
        );
      },
    );
  }
}

class _RevisionLogEmptyState extends StatelessWidget {
  const _RevisionLogEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.history_rounded,
              size: 42,
              color: colorScheme.onSurfaceVariant,
            ),
            Text(
              'revisionLog.emptyTitle'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'revisionLog.emptyBody'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
