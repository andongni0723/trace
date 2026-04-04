// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_database_mention_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PersonalDatabaseMentionSuggestion {

 String get id; String get name; int get colorValue; String? get avatarPath;
/// Create a copy of PersonalDatabaseMentionSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalDatabaseMentionSuggestionCopyWith<PersonalDatabaseMentionSuggestion> get copyWith => _$PersonalDatabaseMentionSuggestionCopyWithImpl<PersonalDatabaseMentionSuggestion>(this as PersonalDatabaseMentionSuggestion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDatabaseMentionSuggestion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.avatarPath, avatarPath) || other.avatarPath == avatarPath));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,avatarPath);

@override
String toString() {
  return 'PersonalDatabaseMentionSuggestion(id: $id, name: $name, colorValue: $colorValue, avatarPath: $avatarPath)';
}


}

/// @nodoc
abstract mixin class $PersonalDatabaseMentionSuggestionCopyWith<$Res>  {
  factory $PersonalDatabaseMentionSuggestionCopyWith(PersonalDatabaseMentionSuggestion value, $Res Function(PersonalDatabaseMentionSuggestion) _then) = _$PersonalDatabaseMentionSuggestionCopyWithImpl;
@useResult
$Res call({
 String id, String name, int colorValue, String? avatarPath
});




}
/// @nodoc
class _$PersonalDatabaseMentionSuggestionCopyWithImpl<$Res>
    implements $PersonalDatabaseMentionSuggestionCopyWith<$Res> {
  _$PersonalDatabaseMentionSuggestionCopyWithImpl(this._self, this._then);

  final PersonalDatabaseMentionSuggestion _self;
  final $Res Function(PersonalDatabaseMentionSuggestion) _then;

/// Create a copy of PersonalDatabaseMentionSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? avatarPath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalDatabaseMentionSuggestion].
extension PersonalDatabaseMentionSuggestionPatterns on PersonalDatabaseMentionSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalDatabaseMentionSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalDatabaseMentionSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalDatabaseMentionSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  String? avatarPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.avatarPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  String? avatarPath)  $default,) {final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion():
return $default(_that.id,_that.name,_that.colorValue,_that.avatarPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int colorValue,  String? avatarPath)?  $default,) {final _that = this;
switch (_that) {
case _PersonalDatabaseMentionSuggestion() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.avatarPath);case _:
  return null;

}
}

}

/// @nodoc


class _PersonalDatabaseMentionSuggestion implements PersonalDatabaseMentionSuggestion {
  const _PersonalDatabaseMentionSuggestion({required this.id, required this.name, required this.colorValue, this.avatarPath});
  

@override final  String id;
@override final  String name;
@override final  int colorValue;
@override final  String? avatarPath;

/// Create a copy of PersonalDatabaseMentionSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalDatabaseMentionSuggestionCopyWith<_PersonalDatabaseMentionSuggestion> get copyWith => __$PersonalDatabaseMentionSuggestionCopyWithImpl<_PersonalDatabaseMentionSuggestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalDatabaseMentionSuggestion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.avatarPath, avatarPath) || other.avatarPath == avatarPath));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,avatarPath);

@override
String toString() {
  return 'PersonalDatabaseMentionSuggestion(id: $id, name: $name, colorValue: $colorValue, avatarPath: $avatarPath)';
}


}

/// @nodoc
abstract mixin class _$PersonalDatabaseMentionSuggestionCopyWith<$Res> implements $PersonalDatabaseMentionSuggestionCopyWith<$Res> {
  factory _$PersonalDatabaseMentionSuggestionCopyWith(_PersonalDatabaseMentionSuggestion value, $Res Function(_PersonalDatabaseMentionSuggestion) _then) = __$PersonalDatabaseMentionSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int colorValue, String? avatarPath
});




}
/// @nodoc
class __$PersonalDatabaseMentionSuggestionCopyWithImpl<$Res>
    implements _$PersonalDatabaseMentionSuggestionCopyWith<$Res> {
  __$PersonalDatabaseMentionSuggestionCopyWithImpl(this._self, this._then);

  final _PersonalDatabaseMentionSuggestion _self;
  final $Res Function(_PersonalDatabaseMentionSuggestion) _then;

/// Create a copy of PersonalDatabaseMentionSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? avatarPath = freezed,}) {
  return _then(_PersonalDatabaseMentionSuggestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,avatarPath: freezed == avatarPath ? _self.avatarPath : avatarPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
