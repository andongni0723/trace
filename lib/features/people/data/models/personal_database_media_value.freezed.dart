// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_database_media_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PersonalDatabaseMediaValue {

 String get mediaAssetId; String get fileName; String get kind;
/// Create a copy of PersonalDatabaseMediaValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalDatabaseMediaValueCopyWith<PersonalDatabaseMediaValue> get copyWith => _$PersonalDatabaseMediaValueCopyWithImpl<PersonalDatabaseMediaValue>(this as PersonalDatabaseMediaValue, _$identity);

  /// Serializes this PersonalDatabaseMediaValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDatabaseMediaValue&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaAssetId,fileName,kind);

@override
String toString() {
  return 'PersonalDatabaseMediaValue(mediaAssetId: $mediaAssetId, fileName: $fileName, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $PersonalDatabaseMediaValueCopyWith<$Res>  {
  factory $PersonalDatabaseMediaValueCopyWith(PersonalDatabaseMediaValue value, $Res Function(PersonalDatabaseMediaValue) _then) = _$PersonalDatabaseMediaValueCopyWithImpl;
@useResult
$Res call({
 String mediaAssetId, String fileName, String kind
});




}
/// @nodoc
class _$PersonalDatabaseMediaValueCopyWithImpl<$Res>
    implements $PersonalDatabaseMediaValueCopyWith<$Res> {
  _$PersonalDatabaseMediaValueCopyWithImpl(this._self, this._then);

  final PersonalDatabaseMediaValue _self;
  final $Res Function(PersonalDatabaseMediaValue) _then;

/// Create a copy of PersonalDatabaseMediaValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mediaAssetId = null,Object? fileName = null,Object? kind = null,}) {
  return _then(_self.copyWith(
mediaAssetId: null == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalDatabaseMediaValue].
extension PersonalDatabaseMediaValuePatterns on PersonalDatabaseMediaValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalDatabaseMediaValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalDatabaseMediaValue value)  $default,){
final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalDatabaseMediaValue value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mediaAssetId,  String fileName,  String kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue() when $default != null:
return $default(_that.mediaAssetId,_that.fileName,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mediaAssetId,  String fileName,  String kind)  $default,) {final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue():
return $default(_that.mediaAssetId,_that.fileName,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mediaAssetId,  String fileName,  String kind)?  $default,) {final _that = this;
switch (_that) {
case _PersonalDatabaseMediaValue() when $default != null:
return $default(_that.mediaAssetId,_that.fileName,_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalDatabaseMediaValue extends PersonalDatabaseMediaValue {
  const _PersonalDatabaseMediaValue({required this.mediaAssetId, required this.fileName, required this.kind}): super._();
  factory _PersonalDatabaseMediaValue.fromJson(Map<String, dynamic> json) => _$PersonalDatabaseMediaValueFromJson(json);

@override final  String mediaAssetId;
@override final  String fileName;
@override final  String kind;

/// Create a copy of PersonalDatabaseMediaValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalDatabaseMediaValueCopyWith<_PersonalDatabaseMediaValue> get copyWith => __$PersonalDatabaseMediaValueCopyWithImpl<_PersonalDatabaseMediaValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalDatabaseMediaValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalDatabaseMediaValue&&(identical(other.mediaAssetId, mediaAssetId) || other.mediaAssetId == mediaAssetId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mediaAssetId,fileName,kind);

@override
String toString() {
  return 'PersonalDatabaseMediaValue(mediaAssetId: $mediaAssetId, fileName: $fileName, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$PersonalDatabaseMediaValueCopyWith<$Res> implements $PersonalDatabaseMediaValueCopyWith<$Res> {
  factory _$PersonalDatabaseMediaValueCopyWith(_PersonalDatabaseMediaValue value, $Res Function(_PersonalDatabaseMediaValue) _then) = __$PersonalDatabaseMediaValueCopyWithImpl;
@override @useResult
$Res call({
 String mediaAssetId, String fileName, String kind
});




}
/// @nodoc
class __$PersonalDatabaseMediaValueCopyWithImpl<$Res>
    implements _$PersonalDatabaseMediaValueCopyWith<$Res> {
  __$PersonalDatabaseMediaValueCopyWithImpl(this._self, this._then);

  final _PersonalDatabaseMediaValue _self;
  final $Res Function(_PersonalDatabaseMediaValue) _then;

/// Create a copy of PersonalDatabaseMediaValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mediaAssetId = null,Object? fileName = null,Object? kind = null,}) {
  return _then(_PersonalDatabaseMediaValue(
mediaAssetId: null == mediaAssetId ? _self.mediaAssetId : mediaAssetId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
