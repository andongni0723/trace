import 'dart:convert';

enum PersonalDatabaseValueType {
  string,
  number,
  boolean,
  nullType,
  list,
  object,
}

extension PersonalDatabaseValueTypeX on PersonalDatabaseValueType {
  String get dbKey => switch (this) {
    PersonalDatabaseValueType.string => 'string',
    PersonalDatabaseValueType.number => 'number',
    PersonalDatabaseValueType.boolean => 'boolean',
    PersonalDatabaseValueType.nullType => 'null',
    PersonalDatabaseValueType.list => 'list',
    PersonalDatabaseValueType.object => 'object',
  };

  String get localizationKey => switch (this) {
    PersonalDatabaseValueType.string => 'personTodo.database.type.string',
    PersonalDatabaseValueType.number => 'personTodo.database.type.number',
    PersonalDatabaseValueType.boolean => 'personTodo.database.type.boolean',
    PersonalDatabaseValueType.nullType => 'personTodo.database.type.null',
    PersonalDatabaseValueType.list => 'personTodo.database.type.list',
    PersonalDatabaseValueType.object => 'personTodo.database.type.object',
  };

  String get defaultJsonValue => switch (this) {
    PersonalDatabaseValueType.string => jsonEncode(''),
    PersonalDatabaseValueType.number => jsonEncode(0),
    PersonalDatabaseValueType.boolean => jsonEncode(false),
    PersonalDatabaseValueType.nullType => 'null',
    PersonalDatabaseValueType.list => '[]',
    PersonalDatabaseValueType.object => '{}',
  };

  bool get allowsInlineTextValue => switch (this) {
    PersonalDatabaseValueType.string => true,
    PersonalDatabaseValueType.number => true,
    PersonalDatabaseValueType.boolean => true,
    PersonalDatabaseValueType.nullType => false,
    PersonalDatabaseValueType.list => true,
    PersonalDatabaseValueType.object => false,
  };

  bool get isContainer => switch (this) {
    PersonalDatabaseValueType.string => false,
    PersonalDatabaseValueType.number => false,
    PersonalDatabaseValueType.boolean => false,
    PersonalDatabaseValueType.nullType => false,
    PersonalDatabaseValueType.list => true,
    PersonalDatabaseValueType.object => true,
  };
}

PersonalDatabaseValueType personalDatabaseValueTypeFromDb(String dbKey) {
  return switch (dbKey) {
    'string' => PersonalDatabaseValueType.string,
    'number' => PersonalDatabaseValueType.number,
    'boolean' => PersonalDatabaseValueType.boolean,
    'null' => PersonalDatabaseValueType.nullType,
    'list' => PersonalDatabaseValueType.list,
    'object' => PersonalDatabaseValueType.object,
    _ => PersonalDatabaseValueType.string,
  };
}

PersonalDatabaseValueType personalDatabaseValueTypeFromValue(Object? value) {
  if (value == null) {
    return PersonalDatabaseValueType.nullType;
  }
  if (value is String) {
    return PersonalDatabaseValueType.string;
  }
  if (value is num) {
    return PersonalDatabaseValueType.number;
  }
  if (value is bool) {
    return PersonalDatabaseValueType.boolean;
  }
  if (value is List) {
    return PersonalDatabaseValueType.list;
  }
  if (value is Map) {
    return PersonalDatabaseValueType.object;
  }

  return PersonalDatabaseValueType.string;
}
