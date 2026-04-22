// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_library_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaLibraryFilter {

 String get query; MediaAssetKind? get kind;
/// Create a copy of MediaLibraryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaLibraryFilterCopyWith<MediaLibraryFilter> get copyWith => _$MediaLibraryFilterCopyWithImpl<MediaLibraryFilter>(this as MediaLibraryFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaLibraryFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,query,kind);

@override
String toString() {
  return 'MediaLibraryFilter(query: $query, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $MediaLibraryFilterCopyWith<$Res>  {
  factory $MediaLibraryFilterCopyWith(MediaLibraryFilter value, $Res Function(MediaLibraryFilter) _then) = _$MediaLibraryFilterCopyWithImpl;
@useResult
$Res call({
 String query, MediaAssetKind? kind
});




}
/// @nodoc
class _$MediaLibraryFilterCopyWithImpl<$Res>
    implements $MediaLibraryFilterCopyWith<$Res> {
  _$MediaLibraryFilterCopyWithImpl(this._self, this._then);

  final MediaLibraryFilter _self;
  final $Res Function(MediaLibraryFilter) _then;

/// Create a copy of MediaLibraryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? kind = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaLibraryFilter].
extension MediaLibraryFilterPatterns on MediaLibraryFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaLibraryFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaLibraryFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaLibraryFilter value)  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaLibraryFilter value)?  $default,){
final _that = this;
switch (_that) {
case _MediaLibraryFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  MediaAssetKind? kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaLibraryFilter() when $default != null:
return $default(_that.query,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  MediaAssetKind? kind)  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryFilter():
return $default(_that.query,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  MediaAssetKind? kind)?  $default,) {final _that = this;
switch (_that) {
case _MediaLibraryFilter() when $default != null:
return $default(_that.query,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _MediaLibraryFilter implements MediaLibraryFilter {
  const _MediaLibraryFilter({this.query = '', this.kind});
  

@override@JsonKey() final  String query;
@override final  MediaAssetKind? kind;

/// Create a copy of MediaLibraryFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaLibraryFilterCopyWith<_MediaLibraryFilter> get copyWith => __$MediaLibraryFilterCopyWithImpl<_MediaLibraryFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaLibraryFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,query,kind);

@override
String toString() {
  return 'MediaLibraryFilter(query: $query, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$MediaLibraryFilterCopyWith<$Res> implements $MediaLibraryFilterCopyWith<$Res> {
  factory _$MediaLibraryFilterCopyWith(_MediaLibraryFilter value, $Res Function(_MediaLibraryFilter) _then) = __$MediaLibraryFilterCopyWithImpl;
@override @useResult
$Res call({
 String query, MediaAssetKind? kind
});




}
/// @nodoc
class __$MediaLibraryFilterCopyWithImpl<$Res>
    implements _$MediaLibraryFilterCopyWith<$Res> {
  __$MediaLibraryFilterCopyWithImpl(this._self, this._then);

  final _MediaLibraryFilter _self;
  final $Res Function(_MediaLibraryFilter) _then;

/// Create a copy of MediaLibraryFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? kind = freezed,}) {
  return _then(_MediaLibraryFilter(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind?,
  ));
}


}

// dart format on
