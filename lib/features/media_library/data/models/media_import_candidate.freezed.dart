// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_import_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaImportCandidate {

 String get sourcePath; String get fileName; int get sizeBytes; MediaAssetKind get kind; String? get mimeType;
/// Create a copy of MediaImportCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaImportCandidateCopyWith<MediaImportCandidate> get copyWith => _$MediaImportCandidateCopyWithImpl<MediaImportCandidate>(this as MediaImportCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaImportCandidate&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,sourcePath,fileName,sizeBytes,kind,mimeType);

@override
String toString() {
  return 'MediaImportCandidate(sourcePath: $sourcePath, fileName: $fileName, sizeBytes: $sizeBytes, kind: $kind, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $MediaImportCandidateCopyWith<$Res>  {
  factory $MediaImportCandidateCopyWith(MediaImportCandidate value, $Res Function(MediaImportCandidate) _then) = _$MediaImportCandidateCopyWithImpl;
@useResult
$Res call({
 String sourcePath, String fileName, int sizeBytes, MediaAssetKind kind, String? mimeType
});




}
/// @nodoc
class _$MediaImportCandidateCopyWithImpl<$Res>
    implements $MediaImportCandidateCopyWith<$Res> {
  _$MediaImportCandidateCopyWithImpl(this._self, this._then);

  final MediaImportCandidate _self;
  final $Res Function(MediaImportCandidate) _then;

/// Create a copy of MediaImportCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourcePath = null,Object? fileName = null,Object? sizeBytes = null,Object? kind = null,Object? mimeType = freezed,}) {
  return _then(_self.copyWith(
sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaImportCandidate].
extension MediaImportCandidatePatterns on MediaImportCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaImportCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaImportCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaImportCandidate value)  $default,){
final _that = this;
switch (_that) {
case _MediaImportCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaImportCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _MediaImportCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourcePath,  String fileName,  int sizeBytes,  MediaAssetKind kind,  String? mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaImportCandidate() when $default != null:
return $default(_that.sourcePath,_that.fileName,_that.sizeBytes,_that.kind,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourcePath,  String fileName,  int sizeBytes,  MediaAssetKind kind,  String? mimeType)  $default,) {final _that = this;
switch (_that) {
case _MediaImportCandidate():
return $default(_that.sourcePath,_that.fileName,_that.sizeBytes,_that.kind,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourcePath,  String fileName,  int sizeBytes,  MediaAssetKind kind,  String? mimeType)?  $default,) {final _that = this;
switch (_that) {
case _MediaImportCandidate() when $default != null:
return $default(_that.sourcePath,_that.fileName,_that.sizeBytes,_that.kind,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc


class _MediaImportCandidate implements MediaImportCandidate {
  const _MediaImportCandidate({required this.sourcePath, required this.fileName, required this.sizeBytes, required this.kind, this.mimeType});
  

@override final  String sourcePath;
@override final  String fileName;
@override final  int sizeBytes;
@override final  MediaAssetKind kind;
@override final  String? mimeType;

/// Create a copy of MediaImportCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaImportCandidateCopyWith<_MediaImportCandidate> get copyWith => __$MediaImportCandidateCopyWithImpl<_MediaImportCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaImportCandidate&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,sourcePath,fileName,sizeBytes,kind,mimeType);

@override
String toString() {
  return 'MediaImportCandidate(sourcePath: $sourcePath, fileName: $fileName, sizeBytes: $sizeBytes, kind: $kind, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$MediaImportCandidateCopyWith<$Res> implements $MediaImportCandidateCopyWith<$Res> {
  factory _$MediaImportCandidateCopyWith(_MediaImportCandidate value, $Res Function(_MediaImportCandidate) _then) = __$MediaImportCandidateCopyWithImpl;
@override @useResult
$Res call({
 String sourcePath, String fileName, int sizeBytes, MediaAssetKind kind, String? mimeType
});




}
/// @nodoc
class __$MediaImportCandidateCopyWithImpl<$Res>
    implements _$MediaImportCandidateCopyWith<$Res> {
  __$MediaImportCandidateCopyWithImpl(this._self, this._then);

  final _MediaImportCandidate _self;
  final $Res Function(_MediaImportCandidate) _then;

/// Create a copy of MediaImportCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourcePath = null,Object? fileName = null,Object? sizeBytes = null,Object? kind = null,Object? mimeType = freezed,}) {
  return _then(_MediaImportCandidate(
sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaAssetKind,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
