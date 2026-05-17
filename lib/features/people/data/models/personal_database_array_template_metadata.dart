import 'dart:convert';

import 'personal_database_value_type.dart';

class PersonalDatabaseArrayTemplateMetadata {
  const PersonalDatabaseArrayTemplateMetadata({
    required this.elementType,
    this.template,
    this.elementMetadata,
  });

  static PersonalDatabaseArrayTemplateMetadata? tryParse(Object? value) {
    final map = _asStringKeyedMap(value);
    if (map == null) {
      return null;
    }

    final elementTypeKey = map['elementType'];
    if (elementTypeKey is! String) {
      return null;
    }

    final elementType = personalDatabaseValueTypeFromDb(elementTypeKey);
    return PersonalDatabaseArrayTemplateMetadata(
      elementType: elementType,
      template: elementType == PersonalDatabaseValueType.object
          ? _asStringKeyedMap(map['template']) ?? const <String, Object?>{}
          : null,
      elementMetadata: elementType == PersonalDatabaseValueType.list
          ? tryParse(map['elementMetadata'])
          : null,
    );
  }

  static PersonalDatabaseArrayTemplateMetadata? fromDefinition({
    required PersonalDatabaseValueType fieldType,
    required PersonalDatabaseValueType? elementType,
    required String? jsonValue,
  }) {
    if (fieldType != PersonalDatabaseValueType.list || elementType == null) {
      return null;
    }

    switch (elementType) {
      case PersonalDatabaseValueType.object:
        return PersonalDatabaseArrayTemplateMetadata(
          elementType: elementType,
          template:
              _decodeTemplateObject(jsonValue) ?? const <String, Object?>{},
        );
      case PersonalDatabaseValueType.list:
        return PersonalDatabaseArrayTemplateMetadata(
          elementType: elementType,
          elementMetadata: _decodeMetadata(jsonValue),
        );
      case PersonalDatabaseValueType.string:
      case PersonalDatabaseValueType.number:
      case PersonalDatabaseValueType.boolean:
      case PersonalDatabaseValueType.media:
      case PersonalDatabaseValueType.nullType:
        return PersonalDatabaseArrayTemplateMetadata(elementType: elementType);
    }
  }

  final PersonalDatabaseValueType elementType;
  final Map<String, Object?>? template;
  final PersonalDatabaseArrayTemplateMetadata? elementMetadata;

  bool get hasObjectTemplate =>
      elementType == PersonalDatabaseValueType.object && template != null;

  Map<String, Object?> toJson() {
    return {
      'elementType': elementType.dbKey,
      if (elementType == PersonalDatabaseValueType.object)
        'template': template ?? const <String, Object?>{},
      if (elementType == PersonalDatabaseValueType.list &&
          elementMetadata != null)
        'elementMetadata': elementMetadata!.toJson(),
    };
  }

  String? toDefinitionJsonValue() {
    return switch (elementType) {
      PersonalDatabaseValueType.object => jsonEncode(
        template ?? const <String, Object?>{},
      ),
      PersonalDatabaseValueType.list =>
        elementMetadata == null ? null : jsonEncode(elementMetadata!.toJson()),
      _ => null,
    };
  }
}

String? normalizePersonalDatabaseArrayTemplateJsonValue({
  required PersonalDatabaseValueType fieldType,
  required PersonalDatabaseValueType? arrayElementType,
  required String? jsonValue,
}) {
  return PersonalDatabaseArrayTemplateMetadata.fromDefinition(
    fieldType: fieldType,
    elementType: arrayElementType,
    jsonValue: jsonValue,
  )?.toDefinitionJsonValue();
}

Map<String, Object?>? decodePersonalDatabaseArrayElementObjectTemplate({
  required PersonalDatabaseValueType fieldType,
  required PersonalDatabaseValueType? arrayElementType,
  required String? jsonValue,
}) {
  return PersonalDatabaseArrayTemplateMetadata.fromDefinition(
    fieldType: fieldType,
    elementType: arrayElementType,
    jsonValue: jsonValue,
  )?.template;
}

PersonalDatabaseArrayTemplateMetadata? _decodeMetadata(String? jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  try {
    return PersonalDatabaseArrayTemplateMetadata.tryParse(
      jsonDecode(jsonValue),
    );
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? _decodeTemplateObject(String? jsonValue) {
  if (jsonValue == null) {
    return null;
  }
  try {
    return _asStringKeyedMap(jsonDecode(jsonValue));
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? _asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }
  return null;
}
