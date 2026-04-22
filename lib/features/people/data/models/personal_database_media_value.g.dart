// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_database_media_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PersonalDatabaseMediaValue _$PersonalDatabaseMediaValueFromJson(
  Map<String, dynamic> json,
) => _PersonalDatabaseMediaValue(
  mediaAssetId: json['mediaAssetId'] as String,
  fileName: json['fileName'] as String,
  kind: json['kind'] as String,
);

Map<String, dynamic> _$PersonalDatabaseMediaValueToJson(
  _PersonalDatabaseMediaValue instance,
) => <String, dynamic>{
  'mediaAssetId': instance.mediaAssetId,
  'fileName': instance.fileName,
  'kind': instance.kind,
};
