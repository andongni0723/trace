// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'revision_log_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RevisionLogViewData {

 String get id; String get action; String get entityType; String get entityId; String? get entityLabel; String get summary; List<String> get changedFields; String? get beforeJson; String? get afterJson; DateTime get happenedAt;
/// Create a copy of RevisionLogViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevisionLogViewDataCopyWith<RevisionLogViewData> get copyWith => _$RevisionLogViewDataCopyWithImpl<RevisionLogViewData>(this as RevisionLogViewData, _$identity);

  /// Serializes this RevisionLogViewData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevisionLogViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityLabel, entityLabel) || other.entityLabel == entityLabel)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.changedFields, changedFields)&&(identical(other.beforeJson, beforeJson) || other.beforeJson == beforeJson)&&(identical(other.afterJson, afterJson) || other.afterJson == afterJson)&&(identical(other.happenedAt, happenedAt) || other.happenedAt == happenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,entityType,entityId,entityLabel,summary,const DeepCollectionEquality().hash(changedFields),beforeJson,afterJson,happenedAt);

@override
String toString() {
  return 'RevisionLogViewData(id: $id, action: $action, entityType: $entityType, entityId: $entityId, entityLabel: $entityLabel, summary: $summary, changedFields: $changedFields, beforeJson: $beforeJson, afterJson: $afterJson, happenedAt: $happenedAt)';
}


}

/// @nodoc
abstract mixin class $RevisionLogViewDataCopyWith<$Res>  {
  factory $RevisionLogViewDataCopyWith(RevisionLogViewData value, $Res Function(RevisionLogViewData) _then) = _$RevisionLogViewDataCopyWithImpl;
@useResult
$Res call({
 String id, String action, String entityType, String entityId, String? entityLabel, String summary, List<String> changedFields, String? beforeJson, String? afterJson, DateTime happenedAt
});




}
/// @nodoc
class _$RevisionLogViewDataCopyWithImpl<$Res>
    implements $RevisionLogViewDataCopyWith<$Res> {
  _$RevisionLogViewDataCopyWithImpl(this._self, this._then);

  final RevisionLogViewData _self;
  final $Res Function(RevisionLogViewData) _then;

/// Create a copy of RevisionLogViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? entityType = null,Object? entityId = null,Object? entityLabel = freezed,Object? summary = null,Object? changedFields = null,Object? beforeJson = freezed,Object? afterJson = freezed,Object? happenedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityLabel: freezed == entityLabel ? _self.entityLabel : entityLabel // ignore: cast_nullable_to_non_nullable
as String?,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,changedFields: null == changedFields ? _self.changedFields : changedFields // ignore: cast_nullable_to_non_nullable
as List<String>,beforeJson: freezed == beforeJson ? _self.beforeJson : beforeJson // ignore: cast_nullable_to_non_nullable
as String?,afterJson: freezed == afterJson ? _self.afterJson : afterJson // ignore: cast_nullable_to_non_nullable
as String?,happenedAt: null == happenedAt ? _self.happenedAt : happenedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RevisionLogViewData].
extension RevisionLogViewDataPatterns on RevisionLogViewData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevisionLogViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevisionLogViewData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevisionLogViewData value)  $default,){
final _that = this;
switch (_that) {
case _RevisionLogViewData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevisionLogViewData value)?  $default,){
final _that = this;
switch (_that) {
case _RevisionLogViewData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  String entityType,  String entityId,  String? entityLabel,  String summary,  List<String> changedFields,  String? beforeJson,  String? afterJson,  DateTime happenedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevisionLogViewData() when $default != null:
return $default(_that.id,_that.action,_that.entityType,_that.entityId,_that.entityLabel,_that.summary,_that.changedFields,_that.beforeJson,_that.afterJson,_that.happenedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  String entityType,  String entityId,  String? entityLabel,  String summary,  List<String> changedFields,  String? beforeJson,  String? afterJson,  DateTime happenedAt)  $default,) {final _that = this;
switch (_that) {
case _RevisionLogViewData():
return $default(_that.id,_that.action,_that.entityType,_that.entityId,_that.entityLabel,_that.summary,_that.changedFields,_that.beforeJson,_that.afterJson,_that.happenedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  String entityType,  String entityId,  String? entityLabel,  String summary,  List<String> changedFields,  String? beforeJson,  String? afterJson,  DateTime happenedAt)?  $default,) {final _that = this;
switch (_that) {
case _RevisionLogViewData() when $default != null:
return $default(_that.id,_that.action,_that.entityType,_that.entityId,_that.entityLabel,_that.summary,_that.changedFields,_that.beforeJson,_that.afterJson,_that.happenedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevisionLogViewData implements RevisionLogViewData {
  const _RevisionLogViewData({required this.id, required this.action, required this.entityType, required this.entityId, this.entityLabel, required this.summary, final  List<String> changedFields = const <String>[], this.beforeJson, this.afterJson, required this.happenedAt}): _changedFields = changedFields;
  factory _RevisionLogViewData.fromJson(Map<String, dynamic> json) => _$RevisionLogViewDataFromJson(json);

@override final  String id;
@override final  String action;
@override final  String entityType;
@override final  String entityId;
@override final  String? entityLabel;
@override final  String summary;
 final  List<String> _changedFields;
@override@JsonKey() List<String> get changedFields {
  if (_changedFields is EqualUnmodifiableListView) return _changedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changedFields);
}

@override final  String? beforeJson;
@override final  String? afterJson;
@override final  DateTime happenedAt;

/// Create a copy of RevisionLogViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevisionLogViewDataCopyWith<_RevisionLogViewData> get copyWith => __$RevisionLogViewDataCopyWithImpl<_RevisionLogViewData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevisionLogViewDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevisionLogViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityLabel, entityLabel) || other.entityLabel == entityLabel)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._changedFields, _changedFields)&&(identical(other.beforeJson, beforeJson) || other.beforeJson == beforeJson)&&(identical(other.afterJson, afterJson) || other.afterJson == afterJson)&&(identical(other.happenedAt, happenedAt) || other.happenedAt == happenedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,entityType,entityId,entityLabel,summary,const DeepCollectionEquality().hash(_changedFields),beforeJson,afterJson,happenedAt);

@override
String toString() {
  return 'RevisionLogViewData(id: $id, action: $action, entityType: $entityType, entityId: $entityId, entityLabel: $entityLabel, summary: $summary, changedFields: $changedFields, beforeJson: $beforeJson, afterJson: $afterJson, happenedAt: $happenedAt)';
}


}

/// @nodoc
abstract mixin class _$RevisionLogViewDataCopyWith<$Res> implements $RevisionLogViewDataCopyWith<$Res> {
  factory _$RevisionLogViewDataCopyWith(_RevisionLogViewData value, $Res Function(_RevisionLogViewData) _then) = __$RevisionLogViewDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, String entityType, String entityId, String? entityLabel, String summary, List<String> changedFields, String? beforeJson, String? afterJson, DateTime happenedAt
});




}
/// @nodoc
class __$RevisionLogViewDataCopyWithImpl<$Res>
    implements _$RevisionLogViewDataCopyWith<$Res> {
  __$RevisionLogViewDataCopyWithImpl(this._self, this._then);

  final _RevisionLogViewData _self;
  final $Res Function(_RevisionLogViewData) _then;

/// Create a copy of RevisionLogViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? entityType = null,Object? entityId = null,Object? entityLabel = freezed,Object? summary = null,Object? changedFields = null,Object? beforeJson = freezed,Object? afterJson = freezed,Object? happenedAt = null,}) {
  return _then(_RevisionLogViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityLabel: freezed == entityLabel ? _self.entityLabel : entityLabel // ignore: cast_nullable_to_non_nullable
as String?,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,changedFields: null == changedFields ? _self._changedFields : changedFields // ignore: cast_nullable_to_non_nullable
as List<String>,beforeJson: freezed == beforeJson ? _self.beforeJson : beforeJson // ignore: cast_nullable_to_non_nullable
as String?,afterJson: freezed == afterJson ? _self.afterJson : afterJson // ignore: cast_nullable_to_non_nullable
as String?,happenedAt: null == happenedAt ? _self.happenedAt : happenedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
