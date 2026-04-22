import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_database_media_value.freezed.dart';
part 'personal_database_media_value.g.dart';

@freezed
abstract class PersonalDatabaseMediaValue with _$PersonalDatabaseMediaValue {
  const PersonalDatabaseMediaValue._();

  const factory PersonalDatabaseMediaValue({
    required String mediaAssetId,
    required String fileName,
    required String kind,
  }) = _PersonalDatabaseMediaValue;

  factory PersonalDatabaseMediaValue.fromJson(Map<String, dynamic> json) =>
      _$PersonalDatabaseMediaValueFromJson(json);

  bool get hasFile =>
      mediaAssetId.trim().isNotEmpty || fileName.trim().isNotEmpty;
}

const emptyPersonalDatabaseMediaValue = PersonalDatabaseMediaValue(
  mediaAssetId: '',
  fileName: '',
  kind: '',
);

PersonalDatabaseMediaValue personalDatabaseMediaValueFromObject(Object? value) {
  if (value is PersonalDatabaseMediaValue) {
    return value;
  }

  if (value is Map<String, dynamic>) {
    try {
      return PersonalDatabaseMediaValue.fromJson(value);
    } catch (_) {
      return emptyPersonalDatabaseMediaValue;
    }
  }

  if (value is Map) {
    try {
      return PersonalDatabaseMediaValue.fromJson(
        value.map((key, value) => MapEntry('$key', value)),
      );
    } catch (_) {
      return emptyPersonalDatabaseMediaValue;
    }
  }

  return emptyPersonalDatabaseMediaValue;
}
