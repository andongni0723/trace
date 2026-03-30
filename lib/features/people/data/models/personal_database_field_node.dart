import 'personal_database_value_type.dart';

class PersonalDatabaseFieldNode {
  const PersonalDatabaseFieldNode({
    required this.id,
    required this.key,
    required this.type,
    required this.isPublic,
    required this.parentFieldId,
    required this.sortOrder,
    required this.rawJsonValue,
    required this.value,
    required this.children,
  });

  final String id;
  final String key;
  final PersonalDatabaseValueType type;
  final bool isPublic;
  final String? parentFieldId;
  final int sortOrder;
  final String rawJsonValue;
  final Object? value;
  final List<PersonalDatabaseFieldNode> children;

  bool get isObject => type == PersonalDatabaseValueType.object;
}
