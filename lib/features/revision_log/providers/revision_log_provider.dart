import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../people/providers/people_database_providers.dart';
import '../data/daos/revision_logs_dao.dart';
import '../data/models/revision_log_action.dart';
import '../data/models/revision_log_view_data.dart';

final revisionLogsDaoProvider = Provider<RevisionLogsDao>((ref) {
  return ref.watch(appDatabaseProvider).revisionLogsDao;
});

final revisionLogProvider = StreamProvider<List<RevisionLogViewData>>((ref) {
  return ref
      .watch(revisionLogsDaoProvider)
      .watchRecentLogs()
      .map((logs) => logs.map(_mapRevisionLog).toList(growable: false));
});

final revisionLogActionsProvider = Provider<RevisionLogActions>((ref) {
  return RevisionLogActions(ref: ref, uuid: const Uuid());
});

class RevisionLogActions {
  RevisionLogActions({required Ref ref, required Uuid uuid})
    : _ref = ref,
      _uuid = uuid;

  final Ref _ref;
  final Uuid _uuid;

  Future<void> record({
    required String action,
    required String entityType,
    required String entityId,
    String? entityLabel,
    required String summary,
    List<String> changedFields = const [],
    Object? before,
    Object? after,
  }) {
    assert(RevisionLogAction.values.contains(action));

    return _ref
        .read(revisionLogsDaoProvider)
        .insertLog(
          id: _uuid.v4(),
          action: action,
          entityType: entityType,
          entityId: entityId,
          entityLabel: entityLabel,
          summary: summary,
          changedFieldsJson: jsonEncode(changedFields),
          beforeJson: _encodeNullableJson(before),
          afterJson: _encodeNullableJson(after),
        );
  }

  Future<int> clearLogs() {
    return _ref.read(revisionLogsDaoProvider).clearLogs();
  }
}

RevisionLogViewData _mapRevisionLog(RevisionLog log) {
  return RevisionLogViewData(
    id: log.id,
    action: log.action,
    entityType: log.entityType,
    entityId: log.entityId,
    entityLabel: log.entityLabel,
    summary: log.summary,
    changedFields: _decodeChangedFields(log.changedFieldsJson),
    beforeJson: log.beforeJson,
    afterJson: log.afterJson,
    happenedAt: log.happenedAt,
  );
}

List<String> _decodeChangedFields(String jsonValue) {
  try {
    final decoded = jsonDecode(jsonValue);
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<String>().toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String? _encodeNullableJson(Object? value) {
  if (value == null) {
    return null;
  }
  return const JsonEncoder.withIndent('  ').convert(value);
}
