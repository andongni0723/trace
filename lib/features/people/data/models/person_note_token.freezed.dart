// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'person_note_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PersonNoteToken {

 String get id; String get label;
/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonNoteTokenCopyWith<PersonNoteToken> get copyWith => _$PersonNoteTokenCopyWithImpl<PersonNoteToken>(this as PersonNoteToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNoteToken&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'PersonNoteToken(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $PersonNoteTokenCopyWith<$Res>  {
  factory $PersonNoteTokenCopyWith(PersonNoteToken value, $Res Function(PersonNoteToken) _then) = _$PersonNoteTokenCopyWithImpl;
@useResult
$Res call({
 String id, String label
});




}
/// @nodoc
class _$PersonNoteTokenCopyWithImpl<$Res>
    implements $PersonNoteTokenCopyWith<$Res> {
  _$PersonNoteTokenCopyWithImpl(this._self, this._then);

  final PersonNoteToken _self;
  final $Res Function(PersonNoteToken) _then;

/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonNoteToken].
extension PersonNoteTokenPatterns on PersonNoteToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PersonNotePersonToken value)?  person,TResult Function( PersonNoteMediaToken value)?  media,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PersonNotePersonToken() when person != null:
return person(_that);case PersonNoteMediaToken() when media != null:
return media(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PersonNotePersonToken value)  person,required TResult Function( PersonNoteMediaToken value)  media,}){
final _that = this;
switch (_that) {
case PersonNotePersonToken():
return person(_that);case PersonNoteMediaToken():
return media(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PersonNotePersonToken value)?  person,TResult? Function( PersonNoteMediaToken value)?  media,}){
final _that = this;
switch (_that) {
case PersonNotePersonToken() when person != null:
return person(_that);case PersonNoteMediaToken() when media != null:
return media(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String label)?  person,TResult Function( String id,  String label)?  media,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PersonNotePersonToken() when person != null:
return person(_that.id,_that.label);case PersonNoteMediaToken() when media != null:
return media(_that.id,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String label)  person,required TResult Function( String id,  String label)  media,}) {final _that = this;
switch (_that) {
case PersonNotePersonToken():
return person(_that.id,_that.label);case PersonNoteMediaToken():
return media(_that.id,_that.label);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String label)?  person,TResult? Function( String id,  String label)?  media,}) {final _that = this;
switch (_that) {
case PersonNotePersonToken() when person != null:
return person(_that.id,_that.label);case PersonNoteMediaToken() when media != null:
return media(_that.id,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class PersonNotePersonToken extends PersonNoteToken {
  const PersonNotePersonToken({required this.id, required this.label}): super._();
  

@override final  String id;
@override final  String label;

/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonNotePersonTokenCopyWith<PersonNotePersonToken> get copyWith => _$PersonNotePersonTokenCopyWithImpl<PersonNotePersonToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNotePersonToken&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'PersonNoteToken.person(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $PersonNotePersonTokenCopyWith<$Res> implements $PersonNoteTokenCopyWith<$Res> {
  factory $PersonNotePersonTokenCopyWith(PersonNotePersonToken value, $Res Function(PersonNotePersonToken) _then) = _$PersonNotePersonTokenCopyWithImpl;
@override @useResult
$Res call({
 String id, String label
});




}
/// @nodoc
class _$PersonNotePersonTokenCopyWithImpl<$Res>
    implements $PersonNotePersonTokenCopyWith<$Res> {
  _$PersonNotePersonTokenCopyWithImpl(this._self, this._then);

  final PersonNotePersonToken _self;
  final $Res Function(PersonNotePersonToken) _then;

/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(PersonNotePersonToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PersonNoteMediaToken extends PersonNoteToken {
  const PersonNoteMediaToken({required this.id, required this.label}): super._();
  

@override final  String id;
@override final  String label;

/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonNoteMediaTokenCopyWith<PersonNoteMediaToken> get copyWith => _$PersonNoteMediaTokenCopyWithImpl<PersonNoteMediaToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNoteMediaToken&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'PersonNoteToken.media(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $PersonNoteMediaTokenCopyWith<$Res> implements $PersonNoteTokenCopyWith<$Res> {
  factory $PersonNoteMediaTokenCopyWith(PersonNoteMediaToken value, $Res Function(PersonNoteMediaToken) _then) = _$PersonNoteMediaTokenCopyWithImpl;
@override @useResult
$Res call({
 String id, String label
});




}
/// @nodoc
class _$PersonNoteMediaTokenCopyWithImpl<$Res>
    implements $PersonNoteMediaTokenCopyWith<$Res> {
  _$PersonNoteMediaTokenCopyWithImpl(this._self, this._then);

  final PersonNoteMediaToken _self;
  final $Res Function(PersonNoteMediaToken) _then;

/// Create a copy of PersonNoteToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(PersonNoteMediaToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PersonNoteSegment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNoteSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PersonNoteSegment()';
}


}

/// @nodoc
class $PersonNoteSegmentCopyWith<$Res>  {
$PersonNoteSegmentCopyWith(PersonNoteSegment _, $Res Function(PersonNoteSegment) __);
}


/// Adds pattern-matching-related methods to [PersonNoteSegment].
extension PersonNoteSegmentPatterns on PersonNoteSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PersonNoteTextSegment value)?  text,TResult Function( PersonNoteTokenSegment value)?  token,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PersonNoteTextSegment() when text != null:
return text(_that);case PersonNoteTokenSegment() when token != null:
return token(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PersonNoteTextSegment value)  text,required TResult Function( PersonNoteTokenSegment value)  token,}){
final _that = this;
switch (_that) {
case PersonNoteTextSegment():
return text(_that);case PersonNoteTokenSegment():
return token(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PersonNoteTextSegment value)?  text,TResult? Function( PersonNoteTokenSegment value)?  token,}){
final _that = this;
switch (_that) {
case PersonNoteTextSegment() when text != null:
return text(_that);case PersonNoteTokenSegment() when token != null:
return token(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( PersonNoteToken token)?  token,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PersonNoteTextSegment() when text != null:
return text(_that.text);case PersonNoteTokenSegment() when token != null:
return token(_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( PersonNoteToken token)  token,}) {final _that = this;
switch (_that) {
case PersonNoteTextSegment():
return text(_that.text);case PersonNoteTokenSegment():
return token(_that.token);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( PersonNoteToken token)?  token,}) {final _that = this;
switch (_that) {
case PersonNoteTextSegment() when text != null:
return text(_that.text);case PersonNoteTokenSegment() when token != null:
return token(_that.token);case _:
  return null;

}
}

}

/// @nodoc


class PersonNoteTextSegment extends PersonNoteSegment {
  const PersonNoteTextSegment(this.text): super._();
  

 final  String text;

/// Create a copy of PersonNoteSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonNoteTextSegmentCopyWith<PersonNoteTextSegment> get copyWith => _$PersonNoteTextSegmentCopyWithImpl<PersonNoteTextSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNoteTextSegment&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'PersonNoteSegment.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $PersonNoteTextSegmentCopyWith<$Res> implements $PersonNoteSegmentCopyWith<$Res> {
  factory $PersonNoteTextSegmentCopyWith(PersonNoteTextSegment value, $Res Function(PersonNoteTextSegment) _then) = _$PersonNoteTextSegmentCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$PersonNoteTextSegmentCopyWithImpl<$Res>
    implements $PersonNoteTextSegmentCopyWith<$Res> {
  _$PersonNoteTextSegmentCopyWithImpl(this._self, this._then);

  final PersonNoteTextSegment _self;
  final $Res Function(PersonNoteTextSegment) _then;

/// Create a copy of PersonNoteSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(PersonNoteTextSegment(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PersonNoteTokenSegment extends PersonNoteSegment {
  const PersonNoteTokenSegment(this.token): super._();
  

 final  PersonNoteToken token;

/// Create a copy of PersonNoteSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonNoteTokenSegmentCopyWith<PersonNoteTokenSegment> get copyWith => _$PersonNoteTokenSegmentCopyWithImpl<PersonNoteTokenSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonNoteTokenSegment&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'PersonNoteSegment.token(token: $token)';
}


}

/// @nodoc
abstract mixin class $PersonNoteTokenSegmentCopyWith<$Res> implements $PersonNoteSegmentCopyWith<$Res> {
  factory $PersonNoteTokenSegmentCopyWith(PersonNoteTokenSegment value, $Res Function(PersonNoteTokenSegment) _then) = _$PersonNoteTokenSegmentCopyWithImpl;
@useResult
$Res call({
 PersonNoteToken token
});


$PersonNoteTokenCopyWith<$Res> get token;

}
/// @nodoc
class _$PersonNoteTokenSegmentCopyWithImpl<$Res>
    implements $PersonNoteTokenSegmentCopyWith<$Res> {
  _$PersonNoteTokenSegmentCopyWithImpl(this._self, this._then);

  final PersonNoteTokenSegment _self;
  final $Res Function(PersonNoteTokenSegment) _then;

/// Create a copy of PersonNoteSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? token = null,}) {
  return _then(PersonNoteTokenSegment(
null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as PersonNoteToken,
  ));
}

/// Create a copy of PersonNoteSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonNoteTokenCopyWith<$Res> get token {
  
  return $PersonNoteTokenCopyWith<$Res>(_self.token, (value) {
    return _then(_self.copyWith(token: value));
  });
}
}

// dart format on
