import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/media_asset_kind.dart';

part 'media_library_view_data.freezed.dart';
part 'media_library_view_data.g.dart';

@freezed
abstract class MediaLibraryViewData with _$MediaLibraryViewData {
  const factory MediaLibraryViewData({
    @Default(<MediaLibraryItemViewData>[]) List<MediaLibraryItemViewData> items,
  }) = _MediaLibraryViewData;

  factory MediaLibraryViewData.fromJson(Map<String, dynamic> json) =>
      _$MediaLibraryViewDataFromJson(json);
}

@freezed
abstract class MediaLibraryItemViewData with _$MediaLibraryItemViewData {
  const factory MediaLibraryItemViewData({
    required String id,
    required MediaAssetKind kind,
    required String name,
    required String sizeLabel,
    String? previewPath,
  }) = _MediaLibraryItemViewData;

  factory MediaLibraryItemViewData.fromJson(Map<String, dynamic> json) =>
      _$MediaLibraryItemViewDataFromJson(json);
}
