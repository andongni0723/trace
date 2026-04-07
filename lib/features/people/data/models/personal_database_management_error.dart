enum PersonalDatabaseManagementErrorCode {
  objectWithChildrenCannotRetype,
  propertyInUseCannotDelete,
  moveTargetMustBeObject,
  moveTargetCannotBeDescendant,
  moveScopeConflict,
}

class PersonalDatabaseManagementException implements Exception {
  const PersonalDatabaseManagementException(this.code);

  final PersonalDatabaseManagementErrorCode code;
}
