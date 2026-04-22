import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_asset_kind.dart';

part 'media_library_filter.freezed.dart';

@freezed
abstract class MediaLibraryFilter with _$MediaLibraryFilter {
  const factory MediaLibraryFilter({
    @Default('') String query,
    MediaAssetKind? kind,
  }) = _MediaLibraryFilter;
}
