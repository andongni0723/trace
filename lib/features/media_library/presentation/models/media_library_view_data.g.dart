// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_library_view_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaLibraryViewData _$MediaLibraryViewDataFromJson(
  Map<String, dynamic> json,
) => _MediaLibraryViewData(
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => MediaLibraryItemViewData.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <MediaLibraryItemViewData>[],
);

Map<String, dynamic> _$MediaLibraryViewDataToJson(
  _MediaLibraryViewData instance,
) => <String, dynamic>{'items': instance.items};

_MediaLibraryItemViewData _$MediaLibraryItemViewDataFromJson(
  Map<String, dynamic> json,
) => _MediaLibraryItemViewData(
  id: json['id'] as String,
  kind: $enumDecode(_$MediaAssetKindEnumMap, json['kind']),
  name: json['name'] as String,
  sizeLabel: json['sizeLabel'] as String,
  previewPath: json['previewPath'] as String?,
);

Map<String, dynamic> _$MediaLibraryItemViewDataToJson(
  _MediaLibraryItemViewData instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': _$MediaAssetKindEnumMap[instance.kind]!,
  'name': instance.name,
  'sizeLabel': instance.sizeLabel,
  'previewPath': instance.previewPath,
};

const _$MediaAssetKindEnumMap = {
  MediaAssetKind.image: 'image',
  MediaAssetKind.audio: 'audio',
  MediaAssetKind.video: 'video',
};
