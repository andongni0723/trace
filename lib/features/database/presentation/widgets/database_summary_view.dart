import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/useful_extension.dart';
import '../../../people/providers/people_provider.dart';
import '../../providers/database_provider.dart';

const double _pageHorizontalPadding = 20;
const double _pageTopPadding = 16;
const double _sectionSpacing = 24;
const double _cardSpacing = 12;
const double _cardMinWidth = 160;

class DatabaseSummaryView extends ConsumerWidget {
  const DatabaseSummaryView({
    this.padding = const EdgeInsets.fromLTRB(
      _pageHorizontalPadding,
      _pageTopPadding,
      _pageHorizontalPadding,
      32,
    ),
    super.key,
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);
    final todosAsync = ref.watch(allTodosProvider);

    return peopleAsync.when(
      data: (people) => todosAsync.when(
        data: (todos) {
          final openTodoCount = todos.where((todo) => !todo.done).length;
          final completedTodoCount = todos.where((todo) => todo.done).length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  (constraints.maxWidth - padding.horizontal - _cardSpacing) /
                  2;
              final resolvedCardWidth = cardWidth < _cardMinWidth
                  ? constraints.maxWidth - padding.horizontal
                  : cardWidth;

              return ListView(
                padding: padding,
                children: [
                  Text(
                    'database.title'.tr(),
                    style: context.tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'database.subtitle'.tr(),
                    style: context.tt.bodyLarge?.copyWith(
                      color: context.cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: _sectionSpacing),
                  Wrap(
                    spacing: _cardSpacing,
                    runSpacing: _cardSpacing,
                    children: [
                      SizedBox(
                        width: resolvedCardWidth,
                        child: _DatabaseMetricCard(
                          label: 'database.metrics.people'.tr(),
                          value: people.length.toString(),
                          icon: Icons.people_alt_outlined,
                        ),
                      ),
                      SizedBox(
                        width: resolvedCardWidth,
                        child: _DatabaseMetricCard(
                          label: 'database.metrics.todos'.tr(),
                          value: todos.length.toString(),
                          icon: Icons.checklist_rounded,
                        ),
                      ),
                      SizedBox(
                        width: resolvedCardWidth,
                        child: _DatabaseMetricCard(
                          label: 'database.metrics.openTodos'.tr(),
                          value: openTodoCount.toString(),
                          icon: Icons.radio_button_unchecked_rounded,
                        ),
                      ),
                      SizedBox(
                        width: resolvedCardWidth,
                        child: _DatabaseMetricCard(
                          label: 'database.metrics.completedTodos'.tr(),
                          value: completedTodoCount.toString(),
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _DatabaseLoadError(message: 'database.loadError'.tr()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _DatabaseLoadError(message: 'database.loadError'.tr()),
    );
  }
}

class _DatabaseMetricCard extends StatelessWidget {
  const _DatabaseMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.cs.primary),
            const SizedBox(height: 20),
            Text(
              value,
              style: context.tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatabaseLoadError extends StatelessWidget {
  const _DatabaseLoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          style: context.tt.bodyLarge?.copyWith(color: context.cs.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
