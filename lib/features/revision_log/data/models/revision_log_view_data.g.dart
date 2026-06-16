// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revision_log_view_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RevisionLogViewData _$RevisionLogViewDataFromJson(Map<String, dynamic> json) =>
    _RevisionLogViewData(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      entityLabel: json['entityLabel'] as String?,
      summary: json['summary'] as String,
      changedFields:
          (json['changedFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      beforeJson: json['beforeJson'] as String?,
      afterJson: json['afterJson'] as String?,
      happenedAt: DateTime.parse(json['happenedAt'] as String),
    );

Map<String, dynamic> _$RevisionLogViewDataToJson(
  _RevisionLogViewData instance,
) => <String, dynamic>{
  'id': instance.id,
  'action': instance.action,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'entityLabel': instance.entityLabel,
  'summary': instance.summary,
  'changedFields': instance.changedFields,
  'beforeJson': instance.beforeJson,
  'afterJson': instance.afterJson,
  'happenedAt': instance.happenedAt.toIso8601String(),
};
