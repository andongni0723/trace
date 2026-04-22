import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_asset_kind.dart';

part 'media_import_candidate.freezed.dart';

@freezed
abstract class MediaImportCandidate with _$MediaImportCandidate {
  const factory MediaImportCandidate({
    required String sourcePath,
    required String fileName,
    required int sizeBytes,
    required MediaAssetKind kind,
    String? mimeType,
  }) = _MediaImportCandidate;
}
