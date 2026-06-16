import 'package:freezed_annotation/freezed_annotation.dart';

part 'revision_log_view_data.freezed.dart';
part 'revision_log_view_data.g.dart';

@freezed
abstract class RevisionLogViewData with _$RevisionLogViewData {
  const factory RevisionLogViewData({
    required String id,
    required String action,
    required String entityType,
    required String entityId,
    String? entityLabel,
    required String summary,
    @Default(<String>[]) List<String> changedFields,
    String? beforeJson,
    String? afterJson,
    required DateTime happenedAt,
  }) = _RevisionLogViewData;

  factory RevisionLogViewData.fromJson(Map<String, dynamic> json) =>
      _$RevisionLogViewDataFromJson(json);
}
