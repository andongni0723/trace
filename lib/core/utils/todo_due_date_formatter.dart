import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class TodoDueDatePresentation {
  const TodoDueDatePresentation({required this.label, required this.isOverdue});

  final String label;
  final bool isOverdue;
}

TodoDueDatePresentation formatTodoDueDate({
  required DateTime dueAt,
  required DateTime now,
  required Locale locale,
}) {
  final isOverdue = dueAt.isBefore(now);
  final difference = dueAt.difference(now);
  final absoluteDifference = difference.abs();
  final localeName = locale.toLanguageTag();
  final timeLabel = DateFormat.Hm(localeName).format(dueAt);

  if (absoluteDifference < const Duration(hours: 6)) {
    final hours = absoluteDifference.inHours;
    if (hours >= 1) {
      return TodoDueDatePresentation(
        label: isOverdue
            ? 'time.hoursAgo'.tr(namedArgs: {'count': '$hours'})
            : 'time.inHours'.tr(namedArgs: {'count': '$hours'}),
        isOverdue: isOverdue,
      );
    }

    final minutes = absoluteDifference.inMinutes.clamp(1, 59);
    return TodoDueDatePresentation(
      label: isOverdue
          ? 'time.minutesAgo'.tr(namedArgs: {'count': '$minutes'})
          : 'time.inMinutes'.tr(namedArgs: {'count': '$minutes'}),
      isOverdue: isOverdue,
    );
  }

  if (_isSameDay(dueAt, now)) {
    return TodoDueDatePresentation(
      label: 'time.todayAt'.tr(namedArgs: {'time': timeLabel}),
      isOverdue: isOverdue,
    );
  }

  if (_isSameDay(dueAt, now.add(const Duration(days: 1)))) {
    return TodoDueDatePresentation(
      label: 'time.tomorrowAt'.tr(namedArgs: {'time': timeLabel}),
      isOverdue: isOverdue,
    );
  }

  if (_isSameDay(dueAt, now.subtract(const Duration(days: 1)))) {
    return TodoDueDatePresentation(
      label: 'time.yesterdayAt'.tr(namedArgs: {'time': timeLabel}),
      isOverdue: isOverdue,
    );
  }

  return TodoDueDatePresentation(
    label: DateFormat.yMMMd(localeName).add_Hm().format(dueAt),
    isOverdue: isOverdue,
  );
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
