import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/revision_logs.dart';

part 'revision_logs_dao.g.dart';

@DriftAccessor(tables: [RevisionLogs])
class RevisionLogsDao extends DatabaseAccessor<AppDatabase>
    with _$RevisionLogsDaoMixin {
  RevisionLogsDao(super.db);

  Selectable<RevisionLog> _recentLogsQuery({int? limit}) {
    final query = select(revisionLogs)
      ..orderBy([
        (table) => OrderingTerm.desc(table.happenedAt),
        (table) => OrderingTerm.desc(table.id),
      ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  Stream<List<RevisionLog>> watchRecentLogs({int? limit}) {
    return _recentLogsQuery(limit: limit).watch();
  }

  Future<List<RevisionLog>> getRecentLogs({int? limit}) {
    return _recentLogsQuery(limit: limit).get();
  }

  Future<int> insertLog({
    required String id,
    required String action,
    required String entityType,
    required String entityId,
    String? entityLabel,
    required String summary,
    String changedFieldsJson = '[]',
    String? beforeJson,
    String? afterJson,
    DateTime? happenedAt,
  }) {
    return into(revisionLogs).insert(
      RevisionLogsCompanion.insert(
        id: id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        entityLabel: Value(entityLabel),
        summary: summary,
        changedFieldsJson: Value(changedFieldsJson),
        beforeJson: Value(beforeJson),
        afterJson: Value(afterJson),
        happenedAt: happenedAt ?? DateTime.now(),
      ),
    );
  }

  Future<int> clearLogs() {
    return delete(revisionLogs).go();
  }
}
